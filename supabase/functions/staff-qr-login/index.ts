// 現場に貼ったQRコードからのスタッフログイン（start.html から呼び出される）。
// QRコードのURLに含まれる合言葉（staff_qr_keys.key）が正しい場合のみ、
//   action = 'list'  → ログイン可能なスタッフ（profiles.role = 'staff'）の名前一覧を返す
//   action = 'login' → 選ばれたスタッフ本人としてログインするためのワンタイムトークンを返す
//                      （ブラウザ側で supabase.auth.verifyOtp に渡すとセッションが作られる）
// 管理者（admin）・事務所タブレット（kiosk）のアカウントには、この方法ではログインできない。
// ログイン前のページから呼ばれるため、JWT検証は無効化して使う。
import { createClient } from 'npm:@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

async function isValidKey(key: unknown): Promise<boolean> {
  if (typeof key !== 'string' || !key) return false
  const { data } = await supabase.from('staff_qr_keys').select('key').eq('id', 1).maybeSingle()
  return !!data && data.key === key
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS })

  let body: { action?: string; key?: string; staff_id?: string }
  try {
    body = await req.json()
  } catch {
    return json({ error: 'bad_request' }, 400)
  }

  if (!(await isValidKey(body.key))) return json({ error: 'invalid_key' }, 403)

  if (body.action === 'list') {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, name')
      .eq('role', 'staff')
      .order('name')
    if (error) return json({ error: error.message }, 500)
    return json({ staff: data })
  }

  if (body.action === 'login') {
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, role')
      .eq('id', body.staff_id ?? '')
      .maybeSingle()
    if (!profile || profile.role !== 'staff') return json({ error: 'not_staff' }, 403)

    const { data: userData, error: userErr } = await supabase.auth.admin.getUserById(profile.id)
    if (userErr || !userData.user?.email) return json({ error: 'user_not_found' }, 404)

    // メールは送信されない（トークンを発行するだけ）
    const { data: link, error: linkErr } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email: userData.user.email,
    })
    if (linkErr) return json({ error: linkErr.message }, 500)
    return json({ token_hash: link.properties.hashed_token })
  }

  return json({ error: 'unknown_action' }, 400)
})

