// 完了予定時刻(scheduled_end)から5分経過しても完了報告がないタスクを検出し、
// 管理者宛てにResend経由でメール通知する。pg_cronから5分おきに呼び出される想定。
import { createClient } from 'npm:@supabase/supabase-js@2'

const RESEND_API_KEY    = Deno.env.get('RESEND_API_KEY')!
const ADMIN_ALERT_EMAIL = Deno.env.get('ADMIN_ALERT_EMAIL')!
const RESEND_FROM       = Deno.env.get('RESEND_FROM') ?? 'onboarding@resend.dev'
const DELAY_MINUTES     = 5

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async () => {
  const now = new Date()
  // JSTの「今日」の日付（tasks.dateとの比較に使用）
  const jstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000)
  const today = jstNow.toISOString().split('T')[0]

  const { data: tasks, error } = await supabase
    .from('tasks')
    .select('id, task_name, crop, scheduled_end, task_completions(id), task_delay_notifications(task_id)')
    .eq('date', today)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const targets = (tasks ?? []).filter((t) => {
    if (t.task_completions?.length) return false
    if (t.task_delay_notifications?.length) return false
    const deadline = new Date(`${today}T${t.scheduled_end}+09:00`)
    const alertAt  = new Date(deadline.getTime() + DELAY_MINUTES * 60 * 1000)
    return now >= alertAt
  })

  for (const task of targets) {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: RESEND_FROM,
        to: ADMIN_ALERT_EMAIL,
        subject: `【遅延】${task.task_name}(${task.crop})が完了報告されていません`,
        text: `${task.crop} の「${task.task_name}」は、完了予定時刻（${String(task.scheduled_end).substring(0, 5)}）から${DELAY_MINUTES}分以上経過していますが、まだ完了報告がありません。ご確認ください。`,
      }),
    })

    if (!res.ok) {
      console.error('Resend送信失敗', task.id, await res.text())
      continue // 送信に失敗した場合は記録を残さず、次回また再試行させる
    }

    await supabase.from('task_delay_notifications').insert({ task_id: task.id })
  }

  return new Response(JSON.stringify({ checked: tasks?.length ?? 0, notified: targets.length }))
})
