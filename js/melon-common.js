// メロン予約管理表（melon.html / melon_sheet.html）共通のヘルパー

const KANA_ROWS = ['あ', 'か', 'さ', 'た', 'な', 'は', 'ま', 'や', 'ら', 'わ'];

const DEFAULT_PRICES = {
  qty3l: 1000,
  qty4l: 1100,
  qty5l: 1200,
  onion: 280,
  box2: 250,
  box35: 350,

  andes3l: 1000, andes4l: 1100, andes5l: 1200,
  yogurkissM: 300, yogurkissL: 500,
  pureNormal: 1000, pureLarge: 1100, pureXlarge: 1100,
  hiyake: 800,
  sakusakuM: 600, sakusakuL: 800,

  suikaWakeS: 1000, suikaWakeM: 1200, suikaWakeL: 1400,
  suikaWake2l: 1600, suikaWake3l: 2000, suikaWake4l: 2200, suikaWake5l: 2500,
  suikaRegular2l: 2300, suikaRegular3l: 2500, suikaRegular4l: 2800,
  boxSuika1: 200, boxSuika2: 300, boxSuikaPlain: 250,

  kokabuKikaku: 400, kokabuNaka: 55,
  daikonS: 120, daikonM: 130, daikonL: 170, daikon2l: 190,
  daikonKiri: 100,
  kabochaKikaku: 35,
  ninjinKikaku: 1080,
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

      andes3l: period.price_andes_3l, andes4l: period.price_andes_4l, andes5l: period.price_andes_5l,
      yogurkissM: period.price_yogurkiss_m, yogurkissL: period.price_yogurkiss_l,
      pureNormal: period.price_pure_normal, pureLarge: period.price_pure_large, pureXlarge: period.price_pure_xlarge,
      hiyake: period.price_hiyake,
      sakusakuM: period.price_sakusaku_m, sakusakuL: period.price_sakusaku_l,

      suikaWakeS: period.price_suika_wake_s, suikaWakeM: period.price_suika_wake_m, suikaWakeL: period.price_suika_wake_l,
      suikaWake2l: period.price_suika_wake_2l, suikaWake3l: period.price_suika_wake_3l,
      suikaWake4l: period.price_suika_wake_4l, suikaWake5l: period.price_suika_wake_5l,
      suikaRegular2l: period.price_suika_regular_2l, suikaRegular3l: period.price_suika_regular_3l, suikaRegular4l: period.price_suika_regular_4l,
      boxSuika1: period.price_box_suika_1, boxSuika2: period.price_box_suika_2, boxSuikaPlain: period.price_box_suika_plain,

      kokabuKikaku: period.price_kokabu_kikaku, kokabuNaka: period.price_kokabu_naka,
      daikonS: period.price_daikon_s, daikonM: period.price_daikon_m, daikonL: period.price_daikon_l, daikon2l: period.price_daikon_2l,
      daikonKiri: period.price_daikon_kiri,
      kabochaKikaku: period.price_kabocha_kikaku,
      ninjinKikaku: period.price_ninjin_kikaku,
    };
  }
  return { ...DEFAULT_PRICES };
}
