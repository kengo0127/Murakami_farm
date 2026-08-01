// LINEからのWebhookを受け取り、公式アカウントが友だち追加された際に
// そのユーザーのLINEユーザーIDを line_recipients に保存する。
// 押し忘れ通知(check-delayed-tasks)は、このテーブルに保存されたIDを宛先として使う。
import { createClient } from 'npm:@supabase/supabase-js@2'

const LINE_CHANNEL_SECRET = Deno.env.get('LINE_CHANNEL_SECRET')!

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

async function isValidSignature(body: string, signature: string | null): Promise<boolean> {
  if (!signature) return false
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(LINE_CHANNEL_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body))
  const expected = btoa(String.fromCharCode(...new Uint8Array(mac)))
  return expected === signature
}

Deno.serve(async (req) => {
  const body = await req.text()
  const signature = req.headers.get('x-line-signature')

  if (!(await isValidSignature(body, signature))) {
    return new Response('invalid signature', { status: 401 })
  }

  const { events } = JSON.parse(body)

  for (const event of events ?? []) {
    if (event.type === 'follow' && event.source?.type === 'user') {
      await supabase.from('line_recipients').upsert({
        label: 'admin_alert',
        line_user_id: event.source.userId,
        updated_at: new Date().toISOString(),
      })
    }
  }

  return new Response('ok')
})
