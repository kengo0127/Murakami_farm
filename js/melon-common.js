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

// 価格期間一覧から、指定日時点で有効な期間を返す（開始日が指定日以前で最も新しいもの。
// 終了日が指定日より前の「期限切れ」期間より、終了日内/未設定の期間を優先する）
function getActivePricePeriodFrom(pricePeriods, dateStr) {
  const inRange = pricePeriods.filter(p => p.start_date <= dateStr && (!p.end_date || p.end_date >= dateStr));
  const pool = inRange.length ? inRange : pricePeriods.filter(p => p.start_date <= dateStr);
  if (!pool.length) return null;
  return pool.reduce((latest, p) => (p.start_date > latest.start_date ? p : latest));
}

function getPricesForDateFrom(pricePeriods, dateStr) {
  const period = getActivePricePeriodFrom(pricePeriods, dateStr);
  if (period) {
    return {
      qty3l: period.price_3l, qty4l: period.price_4l, qty5l: period.price_5l,
      onion: period.price_onion, box2: period.price_box2, box35: period.price_box35,
    };
  }
  return { ...DEFAULT_PRICES };
}
