// 勤怠データ（attendance_records）の日次Excelレポート。
// 毎日20:00 JST頃にpg_cronから呼び出され、その日の勤怠データを
// admin.htmlの「Excelダウンロード」機能と同じ形式（日別勤怠記録＋スタッフ別集計）で
// Excel（.xlsx）にまとめてメール添付で送信する。
import { createClient } from 'npm:@supabase/supabase-js@2'
import * as XLSX from 'npm:xlsx@0.18.5'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!
const REPORT_EMAIL    = Deno.env.get('ATTENDANCE_BACKUP_EMAIL')!

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

function jstToday(): string {
  const jst = new Date(Date.now() + 9 * 60 * 60 * 1000)
  return jst.toISOString().split('T')[0]
}

function fmtHM(d: Date | null): string {
  if (!d) return ''
  const jst = new Date(d.getTime() + 9 * 60 * 60 * 1000)
  return String(jst.getUTCHours()).padStart(2, '0') + ':' + String(jst.getUTCMinutes()).padStart(2, '0')
}

// 打刻時間を30分単位で切り上げ、始業時間を求める（例: 7:20→7:30、7:45→8:00）
// admin.htmlのroundUpToHalfHour()と同じロジック（分の値はJST/UTCどちらで見ても同じなため時差変換不要）
function roundUpToHalfHour(d: Date): Date {
  const rounded = new Date(d)
  rounded.setUTCSeconds(0, 0)
  const remainder = rounded.getUTCMinutes() % 30
  if (remainder !== 0) rounded.setUTCMinutes(rounded.getUTCMinutes() + (30 - remainder))
  return rounded
}

// その日の始業時間。始業時間が決まっているお手伝い先に外出した日はその時刻（JST）、それ以外は出勤打刻の30分切り上げ
// admin.htmlのattendanceStartTime()と同じロジック
function attendanceStartTime(r: { date: string; clock_in: string | null; fixed_start_time: string | null }): Date | null {
  if (!r.clock_in) return null
  if (r.fixed_start_time) return new Date(`${r.date}T${r.fixed_start_time.substring(0, 5)}:00+09:00`)
  return roundUpToHalfHour(new Date(r.clock_in))
}

// 退勤打刻を15分単位で切り下げ、終業時間を求める（例: 17:14→17:00、17:29→17:15）
// admin.htmlのroundDownToQuarterHour()と同じロジック
function roundDownToQuarterHour(d: Date): Date {
  const rounded = new Date(d)
  rounded.setUTCSeconds(0, 0)
  rounded.setUTCMinutes(rounded.getUTCMinutes() - (rounded.getUTCMinutes() % 15))
  return rounded
}

function formatMinutesHM(mins: number): string {
  const h = Math.floor(mins / 60)
  const m = mins % 60
  return `${h}時間${m}分`
}

Deno.serve(async () => {
  const today = jstToday()

  const { data, error } = await supabase
    .from('attendance_records')
    .select('date, clock_in, clock_out, break_minutes, staff_id, help_destination_name, fixed_start_time, returned_at, kintai_staff(name, status, monthly_wage)')
    .eq('date', today)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  if (!data || data.length === 0) {
    return new Response(JSON.stringify({ ok: true, skipped: 'no attendance records for today' }))
  }

  const { data: wagesData, error: wagesError } = await supabase
    .from('kintai_hourly_wages')
    .select('staff_id, wage, start_date')
  if (wagesError) console.error(wagesError)

  const wagesByStaff: Record<string, { wage: number; start_date: string }[]> = {}
  for (const w of (wagesData ?? []) as any[]) {
    (wagesByStaff[w.staff_id] ??= []).push(w)
  }
  function getWageForDate(staffId: string, dateStr: string): number | null {
    const wages = wagesByStaff[staffId]
    if (!wages?.length) return null
    const applicable = wages.filter(w => w.start_date <= dateStr)
    if (!applicable.length) return null
    return applicable.reduce((latest, w) => (w.start_date > latest.start_date ? w : latest)).wage
  }

  const MIN_WAGE = 1112
  const dailyRows: (string | number)[][] = [['日付', 'スタッフ名', '出勤打刻', 'お手伝い先', '始業時間(30分切上／お手伝い先の始業)', '帰社打刻', '退勤打刻', '終業時間(15分切下)', '休憩時間(分)', '労働時間(分)', '労働時間', '時給(円)', '賃金(円)']]
  const staffTotals: Record<string, { status: string; days: number; totalMins: number; totalPay: number; hasPay: boolean; monthlyWage: number | null }> = {}

  for (const r of (data as any[]).slice().sort((a, b) => (a.kintai_staff?.name ?? '').localeCompare(b.kintai_staff?.name ?? '', 'ja'))) {
    const name = r.kintai_staff?.name ?? '—'
    const status = r.kintai_staff?.status ?? ''
    const clockInDate = r.clock_in ? new Date(r.clock_in) : null
    const clockOutDate = r.clock_out ? new Date(r.clock_out) : null
    const startTime = attendanceStartTime(r)
    const endTime = clockOutDate ? roundDownToQuarterHour(clockOutDate) : null
    const breakMinutes = r.break_minutes ?? 0

    let mins: number | '' = ''
    let wage: number | null = null
    let pay: number | '' = ''
    if (startTime && endTime) {
      // 打刻ミスで終業が始業より前になっても、マイナスの労働時間・賃金は出さない
      mins = Math.max(0, Math.round((endTime.getTime() - startTime.getTime()) / 60000) - breakMinutes)
      wage = getWageForDate(r.staff_id, r.date)
      if (wage != null) pay = Math.round(wage * mins / 60)
    }

    dailyRows.push([r.date, name, fmtHM(clockInDate), r.help_destination_name ?? '', fmtHM(startTime), fmtHM(r.returned_at ? new Date(r.returned_at) : null), fmtHM(clockOutDate), fmtHM(endTime), r.break_minutes ?? '', mins, mins !== '' ? formatMinutesHM(mins as number) : '', wage ?? '', pay])

    if (!staffTotals[name]) staffTotals[name] = { status, days: 0, totalMins: 0, totalPay: 0, hasPay: false, monthlyWage: r.kintai_staff?.monthly_wage ?? null }
    if (mins !== '') {
      staffTotals[name].days += 1
      staffTotals[name].totalMins += mins as number
      if (pay !== '') { staffTotals[name].totalPay += pay as number; staffTotals[name].hasPay = true }
    }
  }

  const summaryRows: (string | number)[][] = [['スタッフ名', '属性', '出勤日数', '合計労働時間(分)', '合計労働時間', '合計賃金(円)', '実質時給(円)', '最低賃金判定']]
  for (const name of Object.keys(staffTotals).sort((a, b) => a.localeCompare(b, 'ja'))) {
    const t = staffTotals[name]
    const isSalaried = t.status === '社員'
    const totalPay = isSalaried ? (t.monthlyWage ?? '') : (t.hasPay ? t.totalPay : '')
    const payForCalc = isSalaried ? t.monthlyWage : (t.hasPay ? t.totalPay : null)

    let effectiveHourly: number | '' = ''
    let judgement = ''
    if (payForCalc != null && t.totalMins > 0) {
      effectiveHourly = Math.round(payForCalc / t.totalMins * 60)
      if (effectiveHourly < MIN_WAGE) judgement = `⚠ 最低賃金(${MIN_WAGE}円)未満`
    }

    summaryRows.push([name, t.status, t.days, t.totalMins, formatMinutesHM(t.totalMins), totalPay, effectiveHourly, judgement])
  }

  const wb = XLSX.utils.book_new()

  const wsDaily = XLSX.utils.aoa_to_sheet(dailyRows)
  wsDaily['!cols'] = [{ wch: 12 }, { wch: 14 }, { wch: 10 }, { wch: 18 }, { wch: 22 }, { wch: 10 }, { wch: 10 }, { wch: 18 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 10 }, { wch: 12 }]
  XLSX.utils.book_append_sheet(wb, wsDaily, '日別勤怠記録')

  const wsSummary = XLSX.utils.aoa_to_sheet(summaryRows)
  wsSummary['!cols'] = [{ wch: 14 }, { wch: 14 }, { wch: 10 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 12 }, { wch: 20 }]
  XLSX.utils.book_append_sheet(wb, wsSummary, 'スタッフ別集計')

  const xlsxBase64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' })
  const filename = `村上農園_勤怠日次レポート_${today}.xlsx`

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'onboarding@resend.dev',
      to: REPORT_EMAIL,
      subject: `【勤怠日次レポート】${today}分`,
      text: `${today}分の勤怠データ（${(data ?? []).length}件）を添付します。\n毎日20時頃に自動送信される日次レポートメールです。`,
      attachments: [{ filename, content: xlsxBase64 }],
    }),
  })

  if (!res.ok) {
    console.error('日次レポートメール送信失敗', await res.text())
    return new Response(JSON.stringify({ ok: false }), { status: 500 })
  }

  return new Response(JSON.stringify({ ok: true, rows: (data ?? []).length }))
})
