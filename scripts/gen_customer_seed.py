"""
顧客リスト.xlsx（あ行〜わ行タップ選択用の顧客マスタ）から
seed_customers.sql（Supabase SQL Editor貼り付け用のUPSERT文）を生成する。

シートはA列=行の大分類（あ/か/さ…）、B列=細かい仮名区分（あ/い/う/え/お…）、
C列=名前 の3列構成。名前の並び順はB列ですでに細かく五十音整列されているため、
Excelの記載順（＝上から下の行順）をそのまま sort_order として保持する。

使い方:
  py scripts\\gen_customer_seed.py
"""
import openpyxl

SOURCE_XLSX = r"C:\Users\oshms\HiPro\02_村上農園\EC売上表_インスタ\顧客リスト.xlsx"
OUTPUT_SQL = r"C:\Users\oshms\HiPro\02_村上農園\アプリ開発用\seed_customers.sql"


def esc(s: str) -> str:
    return s.replace("'", "''")


def main() -> None:
    wb = openpyxl.load_workbook(SOURCE_XLSX, data_only=True)
    ws = wb["Sheet1"]

    rows = []
    seen = set()
    for row in ws.iter_rows(values_only=True):
        kana, _kana_detail, name = row[0], row[1], row[2]
        if kana is None or name is None:
            continue
        kana = str(kana).strip()
        name = str(name).strip()
        if not kana or not name:
            continue
        key = (kana, name)
        if key in seen:
            continue  # 完全重複行はExcel記載順で先に登場した方を優先
        seen.add(key)
        rows.append((kana, name, len(rows)))

    lines = [
        "-- ============================================================",
        "-- 村上農園 メロン予約管理 顧客マスタ初期データ投入",
        f"-- 元データ: EC売上表_インスタ/顧客リスト.xlsx （{len(rows)}件、B列の記載順を sort_order として保持）",
        "-- SupabaseのSQL Editorに貼り付けて「Run」を押してください",
        "-- ============================================================",
        "",
        "insert into public.customers (kana_row, name, sort_order) values",
        ",\n".join(f"  ('{esc(k)}', '{esc(n)}', {o})" for k, n, o in rows),
        "on conflict (kana_row, name) do update set sort_order = excluded.sort_order;",
        "",
    ]

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"{len(rows)}件のデータから {OUTPUT_SQL} を生成しました")


if __name__ == "__main__":
    main()
