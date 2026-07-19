// メロン予約管理表（melon.html / melon_sheet.html）共通のヘルパー

const KANA_ROWS = ['あ', 'か', 'さ', 'た', 'な', 'は', 'ま', 'や', 'ら', 'わ'];

const DEFAULT_PRICES = {
  qty3l: 1000,
  qty4l: 1100,
  qty5l: 1200,
  onion: 280,
  box2: 250,
  box35: 350,
};

const WEEKDAYS_JA = ['日', '月', '火', '水', '木', '金', '土'];

function formatYen(n) {
  const v = Number(n) || 0;
  return `${v.toLocaleString('ja-JP')}円`;
}

// '2026-07-19' -> '19日（日）'
function formatDateJa(dateStr) {
  if (!dateStr) return '未設定';
  const d = new Date(dateStr + 'T00:00:00');
  if (Number.isNaN(d.getTime())) return dateStr;
  return `${d.getDate()}日（${WEEKDAYS_JA[d.getDay()]}）`;
}

function monthLabel(year, month) {
  return `${year}年${month}月`;
}
