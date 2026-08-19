#!/usr/bin/env bash
# Runs the full pipeline: clean + engineer features -> load into SQLite ->
# regenerate the static dashboard preview chart.
#
# Usage: ./run_pipeline.sh
set -euo pipefail

echo "==> [1/3] Feature engineering (Python)"
cd python
python3 feature_engineering.py
cd ..

echo "==> [2/3] Loading customer_features.csv into SQLite (data/retention.db)"
python3 - <<'PY'
import pandas as pd, sqlite3
df = pd.read_csv('data/customer_features.csv')
df.columns = [c.strip().replace(' ', '_').replace('(', '').replace(')', '') for c in df.columns]
conn = sqlite3.connect('data/retention.db')
df.to_sql('customers', conn, if_exists='replace', index=False)
conn.close()
print(f"Loaded {len(df)} rows into data/retention.db (table: customers)")
PY

echo "==> [3/3] Try a sample query (sql/01_customer_pyramid.sql, adapted for SQLite column names)"
python3 - <<'PY'
import sqlite3, pandas as pd
conn = sqlite3.connect('data/retention.db')
q = """
SELECT value_tier, COUNT(*) AS customers,
       ROUND(AVG(est_annual_value),2) AS avg_annual_value,
       ROUND(AVG(tenure_orders),1) AS avg_tenure_orders
FROM customers GROUP BY value_tier ORDER BY avg_annual_value DESC;
"""
print(pd.read_sql(q, conn).to_string(index=False))
conn.close()
PY

echo ""
echo "Done. Open dashboard/founder_dashboard.html in a browser for the interactive view,"
echo "or query data/retention.db directly with the scripts in sql/ (Postgres-flavored SQL,"
echo "minor syntax translation needed for SQLite -- see README)."
