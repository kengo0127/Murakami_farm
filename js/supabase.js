const SUPABASE_URL = 'https://wquwvkjnngqkiepthstq.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_HNTsEkozPSmyobggMOGeSA_qRJC6ECI';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function getMyProfile() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) return null;

  const { data } = await supabaseClient
    .from('profiles')
    .select('id, name, role')
    .eq('id', session.user.id)
    .single();

  return data;
}

async function requireAuth(expectedRole = null) {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = 'login.html';
    return null;
  }

  const profile = await getMyProfile();
  if (!profile) {
    window.location.href = 'login.html';
    return null;
  }

  if (expectedRole && profile.role !== expectedRole) {
    window.location.href = profile.role === 'admin' ? 'admin.html' : 'staff.html';
    return null;
  }

  return profile;
}

async function logout() {
  await supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}
