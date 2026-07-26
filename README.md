# Banking EDA & Business Insights Dashboard

## Business Problem
A retail bank has raw customer, account, transaction, and loan data spread across
multiple tables but no clear view of where revenue and risk are concentrated.
Leadership needs to know: which customer segments matter, where risk is
concentrated, and what recurring patterns exist in transaction activity.

## Goal
Turn raw relational banking data into a diagnostic dashboard answering:
**"Where is this bank making money, where is it exposed to risk, and what
patterns should decision-makers act on?"**

## Dataset
Synthetic banking dataset (Kaggle) — 7 relational tables, 1.26M+ records:
`customers`, `accounts`, `cards`, `branches`, `loans`, `merchants`, `transactions`.

## Tools & Approach
- **SQL Server (T-SQL)** — schema design, data import (bulk insert via `sqlcmd`),
  data quality validation, descriptive statistics, and pattern analysis using
  window functions (`RANK()`, `LAG()`)
- **Power BI** — dashboard connected live to SQL Server views (not static CSVs)

## Key Insights
1. **Flat, non-seasonal volume overall** — transaction count and revenue are
   stable within ~1% year-over-year (2019–2025), consistent with synthetic
   rather than real-world growth data.
2. **Consistent February dip** — every single year shows a 5–10% dip in
   transaction volume in February, tied to the shorter calendar month rather
   than customer behavior. Found using a `LAG()` window function for
   month-over-month comparison.
3. **No concentration risk** — the top 10 accounts by spend are tightly
   clustered ($161K–$187K), unlike real portfolios where a small number of
   accounts often dominate volume.
4. **Subprime-skewing credit profile** — average credit score of 574, with
   18,000+ customers in the "Poor" (300–499) band.
5. **Data quality** — zero nulls, duplicates, or invalid values across all
   7 tables; uniform distributions in transaction amounts and credit scores
   indicate synthetically generated data. Findings demonstrate SQL/BI
   methodology rather than real market signal.

## Data Quality Checks Performed
- Referential integrity across all foreign key relationships (0 orphaned rows)
- Null checks across key columns (0 found)
- Duplicate transaction detection (0 found)
- Range validation (credit scores 300–850, no negative balances/transactions)
- Categorical consistency checks (account_type, card_type, city)

## Dashboard
**Page 1 — Transaction Trends:** KPI summary, monthly volume trend (2019–2025),
top 10 accounts by spend.
**Page 2 — Risk & Account Overview:** Customer credit risk distribution,
average balance by account type.

See `/screenshots` for previews and `/powerbi/banking_dashboard.pbix` for the
full interactive file.

## Repository Structure
```
├── README.md
├── sql/
│   ├── schema.sql
│   ├── data_quality_checks.sql
│   ├── descriptive_stats.sql
│   ├── patterns_window_functions.sql
│   └── views_for_powerbi.sql
├── powerbi/
│   └── banking_dashboard.pbix
├── screenshots/
│   ├── page1_trends.png
│   └── page2_risk_overview.png
```

## Author
Devrajsingh Sukhai (Dev) — [GitHub](https://github.com/D3vra1)
