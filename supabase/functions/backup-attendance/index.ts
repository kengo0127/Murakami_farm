// 勤怠データ（attendance_records）の週次バックアップ。
// 毎週日曜23:55 JST頃にpg_cronから呼び出され、当月分の勤怠データを
// CSVにまとめてメール添付で送信する。Supabase自体に障害等が起きた
// 場合の保険として、Supabase外にも記録を残すための仕組み。
import { createClient } from 'npm:@supabase/supabase-js@2'

const RESEND_API_KEY      = Deno.env.get('RESEND_API_KEY')!
const BACKUP_EMAIL        = Deno.env.get('ATTENDANCE_BACKUP_EMAIL')!

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

function fmtHM(iso: string | null): string {
  if (!iso) return ''
  const jst = new Date(new Date(iso).getTime() + 9 * 60 * 60 * 1000)
  return String(jst.getUTCHours()).padStart(2, '0') + ':' + String(jst.getUTCMinutes()).padStart(2, '0')
}

function csvEscape(v: unknown): string {
  return `"${String(v ?? '').replace(/"/g, '""')}"`
}

Deno.serve(async () => {
  const now = new Date()
  const jstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000)
  const year  = jstNow.getUTCFullYear()
  const month = jstNow.getUTCMonth() + 1
  const monthStart = `${year}-${String(month).padStart(2, '0')}-01`
  const todayStr    = jstNow.toISOString().split('T')[0]

  const { data, error } = await supabase
    .from('attendance_records')
    .select('date, clock_in, clock_out, kintai_staff(name, status)')
    .gte('date', monthStart)
    .lte('date', todayStr)
    .order('date')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const rows: string[][] = [['日付', 'スタッフ名', '属性', '出勤時刻', '退勤時刻', '労働時間(分)']]
  for (const r of (data ?? []) as any[]) {
    let mins = ''
    if (r.clock_in && r.clock_out) {
      mins = String(Math.round((new Date(r.clock_out).getTime() - new Date(r.clock_in).getTime()) / 60000))
    }
    rows.push([r.date, r.kintai_staff?.name ?? '', r.kintai_staff?.status ?? '', fmtHM(r.clock_in), fmtHM(r.clock_out), mins])
  }

  const csvBody   = '﻿' + rows.map(row => row.map(csvEscape).join(',')).join('\r\n')
  const csvBase64 = btoa(unescape(encodeURIComponent(csvBody)))
  const filename  = `村上農園_勤怠バックアップ_${year}-${String(month).padStart(2, '0')}.csv`

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'onboarding@resend.dev',
      to: BACKUP_EMAIL,
      subject: `【勤怠バックアップ】${year}年${month}月分（${todayStr}時点）`,
      text: `${year}年${month}月分の勤怠データ（${todayStr}時点、${(data ?? []).length}件）を添付します。\n毎週日曜深夜に自動送信されるバックアップメールです。`,
      attachments: [{ filename, content: csvBase64 }],
    }),
  })

  if (!res.ok) {
    console.error('バックアップメール送信失敗', await res.text())
    return new Response(JSON.stringify({ ok: false }), { status: 500 })
  }

  return new Response(JSON.stringify({ ok: true, rows: (data ?? []).length }))
})
