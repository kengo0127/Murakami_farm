// お客様からの注文リクエスト（melon_order_requests）について、以下2パターンを
// 検出し、管理者宛てにLINEで通知する。
//   A. 新規受信（まだ通知していない pending リクエスト）→ すぐに通知
//   B. pending のまま受付から60分経過 → 催促の再通知
// pg_cronから5分おきに呼び出される想定。
// 通知先は line_recipients テーブルに保存されたLINEユーザーID
// （check-delayed-tasks と共通。line-webhook が友だち追加イベントを受けて保存する）。
import { createClient } from 'npm:@supabase/supabase-js@2'

const LINE_CHANNEL_ACCESS_TOKEN = Deno.env.get('LINE_CHANNEL_ACCESS_TOKEN')!

const OVERDUE_MINUTES = 60
const REQUESTS_URL = 'https://kengo0127.github.io/Murakami_farm/melon_requests.html'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

type OrderRequest = {
  id: string
  customer_name: string
  contact: string | null
  entry_date: string
  qty_3l: number
  qty_4l: number
  qty_5l: number
  qty_other: number
  other_label: string | null
  onion_kg: number
  created_at: string
}

async function sendLineMessage(text: string): Promise<boolean> {
  const { data: recipient } = await supabase
    .from('line_recipients')
    .select('line_user_id')
    .eq('label', 'admin_alert')
    .maybeSingle()

  if (!recipient) {
    console.error('LINE通知先が未登録です（友だち追加が完了していない可能性があります）')
    return false
  }

  const res = await fetch('https://api.line.me/v2/bot/message/push', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: recipient.line_user_id,
      messages: [{ type: 'text', text }],
    }),
  })

  if (!res.ok) {
    console.error('LINE送信失敗', await res.text())
    return false
  }
  return true
}

function summarizeItems(req: OrderRequest): string {
  const parts: string[] = []
  if (req.qty_3l) parts.push(`3L ${req.qty_3l}玉`)
  if (req.qty_4l) parts.push(`4L ${req.qty_4l}玉`)
  if (req.qty_5l) parts.push(`5L ${req.qty_5l}玉`)
  if (req.onion_kg) parts.push(`玉ねぎ ${req.onion_kg}kg`)
  if (req.qty_other) parts.push(`その他 ${req.qty_other}${req.other_label ? '（' + req.other_label + '）' : ''}`)
  return parts.length ? parts.join('、') : '（数量未入力）'
}

function formatDateJa(dateStr: string): string {
  const d = new Date(`${dateStr}T00:00:00+09:00`)
  const weekdays = ['日', '月', '火', '水', '木', '金', '土']
  return `${d.getMonth() + 1}/${d.getDate()}（${weekdays[d.getDay()]}）`
}

function buildMessage(req: OrderRequest, heading: string): string {
  return `${heading}\n`
    + `お名前：${req.customer_name}様\n`
    + `来店希望日：${formatDateJa(req.entry_date)}\n`
    + `内容：${summarizeItems(req)}\n`
    + `連絡先：${req.contact || '（未記入）'}\n`
    + `確認・承認はこちら\n${REQUESTS_URL}`
}

Deno.serve(async () => {
  const now = new Date()
  let notifiedCount = 0

  // A. 新規受信の通知
  const { data: newRequests, error: newErr } = await supabase
    .from('melon_order_requests')
    .select('*')
    .eq('status', 'pending')
    .is('notified_new_at', null)

  if (newErr) {
    return new Response(JSON.stringify({ error: newErr.message }), { status: 500 })
  }

  for (const req of (newRequests ?? []) as OrderRequest[]) {
    const ok = await sendLineMessage(buildMessage(req, '【新規ご予約が届きました】'))
    if (ok) {
      await supabase.from('melon_order_requests').update({ notified_new_at: now.toISOString() }).eq('id', req.id)
      notifiedCount++
    }
  }

  // B. 受付から60分経過しても未対応（承認・却下されていない）場合の催促通知
  const overdueBefore = new Date(now.getTime() - OVERDUE_MINUTES * 60 * 1000).toISOString()
  const { data: overdueRequests, error: overdueErr } = await supabase
    .from('melon_order_requests')
    .select('*')
    .eq('status', 'pending')
    .is('notified_overdue_at', null)
    .lte('created_at', overdueBefore)

  if (overdueErr) {
    return new Response(JSON.stringify({ error: overdueErr.message }), { status: 500 })
  }

  for (const req of (overdueRequests ?? []) as OrderRequest[]) {
    const ok = await sendLineMessage(buildMessage(req, `【要確認】受付から${OVERDUE_MINUTES}分以上未対応です`))
    if (ok) {
      await supabase.from('melon_order_requests').update({ notified_overdue_at: now.toISOString() }).eq('id', req.id)
      notifiedCount++
    }
  }

  return new Response(JSON.stringify({
    newChecked: newRequests?.length ?? 0,
    overdueChecked: overdueRequests?.length ?? 0,
    notified: notifiedCount,
  }))
})
