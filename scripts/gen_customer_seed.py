"""
顧客リスト.xlsx（あ行〜わ行タップ選択用の顧客マスタ）から
seed_customers.sql（Supabase SQL Editor貼り付け用のINSERT文）を生成する。

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
    for row in ws.iter_rows(values_only=True):
        kana, name = row[0], row[1]
        if kana is None or name is None:
            continue
        kana = str(kana).strip()
        name = str(name).strip()
        if not kana or not name:
            continue
        rows.append((kana, name))

    lines = [
        "-- ============================================================",
        "-- 村上農園 メロン予約管理 顧客マスタ初期データ投入",
        f"-- 元データ: EC売上表_インスタ/顧客リスト.xlsx （{len(rows)}件）",
        "-- SupabaseのSQL Editorに貼り付けて「Run」を押してください",
        "-- ============================================================",
        "",
        "insert into public.customers (kana_row, name) values",
        ",\n".join(f"  ('{esc(k)}', '{esc(n)}')" for k, n in rows),
        "on conflict (kana_row, name) do nothing;",
        "",
    ]

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"{len(rows)}件のデータから {OUTPUT_SQL} を生成しました")


if __name__ == "__main__":
    main()
