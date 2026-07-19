// 以下3種類の押し忘れを検出し、管理者宛てにResend経由でメール通知する。
// pg_cronから5分おきに呼び出される想定。
//   A. 完了予定時刻(scheduled_end)から5分経過しても完了報告がない
//   B. 休憩直前(9:55/11:55/14:55/16:55)の時点で、完了予定時刻を過ぎているのに
//      まだ完了報告がない（休憩時間に管理者が対面で確認・注意できるようにするため）
//   C. 開始予定時刻(scheduled_start)から10分経過しても開始報告がない
import { createClient } from 'npm:@supabase/supabase-js@2'

const RESEND_API_KEY    = Deno.env.get('RESEND_API_KEY')!
const ADMIN_ALERT_EMAIL = Deno.env.get('ADMIN_ALERT_EMAIL')!
const RESEND_FROM       = Deno.env.get('RESEND_FROM') ?? 'onboarding@resend.dev'

const COMPLETION_DELAY_MINUTES = 5
const START_DELAY_MINUTES      = 10
// 休憩直前の再チェック時刻（JST）。休憩開始（10:00/12:00/15:00/17:00）の5分前。
const BREAK_CHECKPOINTS = ['09:55', '11:55', '14:55', '16:55']

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

async function sendMail(subject: string, text: string): Promise<boolean> {
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: RESEND_FROM,
      to: ADMIN_ALERT_EMAIL,
      subject,
      text,
    }),
  })

  if (!res.ok) {
    console.error('Resend送信失敗', await res.text())
    return false
  }
  return true
}

// 送信に成功した場合のみ notification_type ごとに記録する（1タスク×1種類につき1回）
async function notifyOnce(taskId: string, notificationType: string, subject: string, text: string) {
  const ok = await sendMail(subject, text)
  if (!ok) return // 失敗時は記録を残さず、次回また再試行させる
  await supabase.from('task_delay_notifications').insert({ task_id: taskId, notification_type: notificationType })
}

Deno.serve(async () => {
  const now = new Date()
  // JSTの「今日」の日付・時刻（tasks.dateとの比較、休憩チェックポイント判定に使用）
  const jstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000)
  const today  = jstNow.toISOString().split('T')[0]
  const hhmm   = jstNow.toISOString().substring(11, 16) // "09:55" 形式（JST）

  const { data: tasks, error } = await supabase
    .from('tasks')
    .select(`
      id, task_name, crop, scheduled_start, scheduled_end,
      task_starts(id), task_completions(id), task_delay_notifications(notification_type)
    `)
    .eq('date', today)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  let notifiedCount = 0

  for (const task of tasks ?? []) {
    const notifiedTypes = new Set((task.task_delay_notifications ?? []).map((n: { notification_type: string }) => n.notification_type))
    const isCompleted = !!task.task_completions?.length
    const isStarted   = !!task.task_starts?.length

    // A. 完了予定時刻から5分経過しても完了報告がない
    if (!isCompleted && !notifiedTypes.has('completion_delay')) {
      const deadline = new Date(`${today}T${task.scheduled_end}+09:00`)
      const alertAt  = new Date(deadline.getTime() + COMPLETION_DELAY_MINUTES * 60 * 1000)
      if (now >= alertAt) {
        await notifyOnce(
          task.id, 'completion_delay',
          `【遅延】${task.task_name}(${task.crop})が完了報告されていません`,
          `${task.crop} の「${task.task_name}」は、完了予定時刻（${String(task.scheduled_end).substring(0, 5)}）から${COMPLETION_DELAY_MINUTES}分以上経過していますが、まだ完了報告がありません。ご確認ください。`,
        )
        notifiedCount++
      }
    }

    // B. 休憩直前の再チェック（完了予定時刻を過ぎているのにまだ完了していない）
    if (!isCompleted && BREAK_CHECKPOINTS.includes(hhmm)) {
      const checkpointType = `completion_break_${hhmm.replace(':', '')}`
      if (!notifiedTypes.has(checkpointType)) {
        const deadline = new Date(`${today}T${task.scheduled_end}+09:00`)
        if (now >= deadline) {
          await notifyOnce(
            task.id, checkpointType,
            `【休憩前確認】${task.task_name}(${task.crop})が完了報告されていません`,
            `${task.crop} の「${task.task_name}」は完了予定時刻（${String(task.scheduled_end).substring(0, 5)}）を過ぎていますが、まだ完了報告がありません。まもなく休憩時間です。対面で完了ボタンの確認をお願いします。`,
          )
          notifiedCount++
        }
      }
    }

    // C. 開始予定時刻から10分経過しても開始報告がない
    if (!isStarted && !notifiedTypes.has('start_delay')) {
      const startDeadline = new Date(`${today}T${task.scheduled_start}+09:00`)
      const alertAt        = new Date(startDeadline.getTime() + START_DELAY_MINUTES * 60 * 1000)
      if (now >= alertAt) {
        await notifyOnce(
          task.id, 'start_delay',
          `【未開始】${task.task_name}(${task.crop})が開始されていません`,
          `${task.crop} の「${task.task_name}」は、開始予定時刻（${String(task.scheduled_start).substring(0, 5)}）から${START_DELAY_MINUTES}分以上経過していますが、まだ開始報告がありません。ご確認ください。`,
        )
        notifiedCount++
      }
    }
  }

  return new Response(JSON.stringify({ checked: tasks?.length ?? 0, notified: notifiedCount }))
})
