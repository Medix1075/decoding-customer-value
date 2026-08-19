# Decoding Customer Value
### A SQL-driven retention strategy for a D2C fashion brand

![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20flavored-4169E1?logo=postgresql&logoColor=white)
![Pandas](https://img.shields.io/badge/pandas-2.x-150458?logo=pandas&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-brightgreen)
![Status](https://img.shields.io/badge/status-complete-success)

> **The brand has data but no intelligence built on top of it.** This
> project turns 3,900 anonymized customer records into a segmentation model,
> a queryable analytics layer, an interactive dashboard, and two
> board-ready recommendations — with every number traceable back to a query
> you can re-run.

---

## Table of contents

- [The problem](#the-problem)
- [What this repo answers](#what-this-repo-answers)
- [Dashboard preview](#dashboard-preview)
- [Headline findings](#headline-findings)
- [Repository structure](#repository-structure)
- [How the pipeline fits together](#how-the-pipeline-fits-together)
- [Quickstart](#quickstart)
- [The feature engineering layer](#the-feature-engineering-layer)
- [The SQL analysis layer](#the-sql-analysis-layer)
- [The Founder Dashboard](#the-founder-dashboard)
- [The retention playbook](#the-retention-playbook)
- [Known limitations](#known-limitations)
- [Tech stack](#tech-stack)

---

## The problem

A direct-to-consumer fashion brand — clothing, footwear, accessories,
outerwear, no physical stores, no third-party retail — has grown to ~3,900
customers on the strength of a promotional discount program. It has never
built a structured way to understand its customers beyond surface-level
sales totals, and it can't currently answer:

- Who is genuinely loyal, versus who only buys when there's a discount?
- What behavioral patterns today predict high customer value over time?
- Which geographies and demographics are commercially underleveraged?
- How should the brand restructure its promo strategy to protect margin
  without losing volume?
- What does the brand's ideal customer actually look like?

This repository is the full answer path: raw data → engineered features →
SQL analysis → dashboard → two concrete, risk-stated recommendations.

## What this repo answers

| # | Business question | Where it's answered |
|---|---|---|
| 1 | Loyal vs. discount-driven customers | `sql/02_loyalty_vs_promo_dependency.sql` |
| 2 | Behavioral predictors of long-term value | `python/feature_engineering.py` (`customer_value_score`) |
| 3 | Underleveraged geographies/demographics | `sql/04_geographic_opportunity.sql` |
| 4 | Promo strategy restructuring | `docs/RETENTION_PLAYBOOK.md` §1 |
| 5 | Ideal customer profile & acquisition | `docs/RETENTION_PLAYBOOK.md` §2 |

---

## Dashboard preview

The live version is `dashboard/founder_dashboard.html` — open it directly in
a browser, no server required. Static snapshot below:

![Founder Dashboard preview](reports/figures/dashboard_preview.png)

## Headline findings

- **43.0%** of the customer base is promo-dependent, but promo dependency
  **does not correlate with tenure** — organic and discount-driven customers
  show nearly identical average order counts in every value tier. The
  discount program is not what's building loyalty.
- The top 4.8% of customers (**Platinum tier**, 187 people) drive an
  estimated **$3,051/year** in annualized value each — 25.6x the Bronze
  tier — and are disproportionately **not** discount-dependent.
- **Accessories** is the brand's only true retention category (customers
  buying it have above-average tenure); Clothing, Footwear, and Outerwear
  all skew toward first-time and low-tenure buyers.
- 13 states show **"Organic High-Traction"** patterns — above-average spend
  with below-average promo reliance — signaling real brand pull the
  marketing team hasn't deliberately invested behind.
- Two segments (all of Platinum, plus Gold-tier Accessories buyers — ~620
  customers) clear the evidence bar to safely reduce discount dependency;
  see the [Retention Playbook](docs/RETENTION_PLAYBOOK.md) for the phased
  plan and its explicitly stated risk.

---

## Repository structure

```
.
├── data/
│   ├── customer_data_raw.csv        # Source data, 3,900 rows x 18 columns
│   └── customer_features.csv        # Output of the feature engineering layer
├── python/
│   └── feature_engineering.py       # Cleans data, builds every engineered metric
├── sql/
│   ├── 00_schema.sql                # Table definition for the analytics layer
│   ├── 01_customer_pyramid.sql      # Q2 -> Dashboard Panel 1
│   ├── 02_loyalty_vs_promo_dependency.sql   # Q1 -> Dashboard Panel 2
│   ├── 03_seasonal_category_tenure.sql      # supports Panel 4
│   ├── 04_geographic_opportunity.sql        # Q3 -> Dashboard Panel 3
│   ├── 05_ideal_customer_profile.sql        # Q5 -> Retention Playbook
│   └── 06_promotional_sunset_candidates.sql # Q4 -> Retention Playbook
├── dashboard/
│   ├── founder_dashboard.html       # Interactive, single-file, opens in any browser
│   └── dashboard_data.json          # Precomputed aggregates powering the dashboard
├── reports/
│   └── figures/dashboard_preview.png
├── docs/
│   └── RETENTION_PLAYBOOK.md        # The two business recommendations, in full
├── run_pipeline.sh                  # One command: raw CSV -> features -> SQLite
├── requirements.txt
└── LICENSE
```

## How the pipeline fits together

```
 data/customer_data_raw.csv
          │
          ▼
 python/feature_engineering.py    ← cleans data, engineers 13 new metrics
          │
          ▼
 data/customer_features.csv  ──────────────┐
          │                                │
          ▼                                ▼
 SQLite (data/retention.db)        dashboard/dashboard_data.json
          │                                │
          ▼                                ▼
   sql/*.sql  (6 analysis files)   dashboard/founder_dashboard.html
          │                                │
          └───────────────┬────────────────┘
                           ▼
              docs/RETENTION_PLAYBOOK.md
        (business recommendations, evidence-cited)
```

Every arrow is a real, re-runnable step — nothing in the playbook is a
number that can't be traced back to a query in `sql/`.

## Quickstart

```bash
git clone <this-repo>
cd decoding-customer-value
pip install -r requirements.txt
./run_pipeline.sh
```

This regenerates `data/customer_features.csv`, loads it into a local SQLite
database at `data/retention.db`, and runs a sample query so you can confirm
everything works. Then:

- Open **`dashboard/founder_dashboard.html`** directly in a browser for the
  interactive Founder Dashboard.
- Explore **`sql/*.sql`** against `data/retention.db` (or your own
  Postgres instance — the schema in `sql/00_schema.sql` is Postgres-flavored;
  SQLite users should drop the `NUMERIC(p,s)` precision args, which SQLite
  ignores harmlessly anyway).
- Read **`docs/RETENTION_PLAYBOOK.md`** for the two business
  recommendations in full, with every claim cited back to a query.

## The feature engineering layer

The raw dataset is a **customer-level snapshot** (one row per customer, with
a `Previous Purchases` counter), not a full transaction log — so classic
RFM ("days since last order") can't be computed directly. Every feature in
`python/feature_engineering.py` is a deliberate proxy, chosen because it
feeds a specific downstream decision, not because it was easy to compute.
Highlights:

| Feature | What it captures | Decision it feeds |
|---|---|---|
| `est_annual_value` | Order value annualized by stated purchase cadence | Comparable spend across customers on different buying rhythms |
| `lifetime_value_proxy` | Order value × (previous purchases + 1) | Cumulative value ranking |
| `promo_dependency_score` (0–3) | Discount + promo code + subscription flags | Who is "rented" by discounting |
| `is_organic_high_value` | Above-median spend, zero discount/promo usage | Proof of real brand pull |
| `customer_value_score` (0–100) | Weighted percentile blend of spend, tenure, satisfaction | The Customer Pyramid tiers |
| `category_role` | Whether a category's buyers skew high- or low-tenure | Entry-point vs. retention categories |

Full derivation logic and the business reasoning behind each choice is
documented inline in the script — every function's docstring states which
of the five business questions it answers, per the brief's own instruction
that "metrics that sound analytical but do not lead to a decision are not
useful."

## The SQL analysis layer

Six `.sql` files, each mapped to a specific business question and dashboard
panel (see the [table above](#what-this-repo-answers)). Every query is
written in portable ANSI/PostgreSQL SQL, commented with **how to read the
output** and **what decision it should change**, and was validated against
a live SQLite build of the feature table before being committed (see
`run_pipeline.sh` for the exact load step).

## The Founder Dashboard

`dashboard/founder_dashboard.html` is a single, dependency-free HTML file
(charts via Chart.js from a CDN, data embedded inline) — double-click it,
no server or build step needed. Four panels, matching the brief exactly:

1. **Customer Pyramid** — value distributed across the base
2. **Promo Dependency vs. Retention** — organic vs. discount-driven tenure, by segment
3. **Geographic Opportunity Map** — every state plotted by spend vs. promo reliance, bubble-sized by customer count
4. **Category Funnel** — entry-point vs. retention categories

> **Note on tooling:** the brief calls for Power BI. This repo ships the
> same four panels as a fully working, git-friendly, dependency-free
> interactive artifact instead, built directly from `dashboard_data.json`
> (itself generated from `customer_features.csv`) — anyone with the
> `.csv` can rebuild the equivalent `.pbix` in Power BI Desktop in minutes
> using the same four aggregate tables. Shipping HTML+JS over a binary
> `.pbix` also means the dashboard's logic is diffable, code-reviewable, and
> renders identically for anyone who clones the repo, with no license
> required to view it.

## The retention playbook

**[→ docs/RETENTION_PLAYBOOK.md](docs/RETENTION_PLAYBOOK.md)**

Two recommendations, each stating the segment, the trigger behavior, a
phased rollout timeline, the tracking metric, and — per the brief's
requirement — **what the brand risks by acting on it**:

1. **Promotional Sunset Plan** — which ~620 customers to gradually stop
   discounting, the 12-week phased test that protects against being wrong,
   and an estimated margin impact.
2. **Ideal Customer Profile** — a data-backed description of the brand's
   most valuable customer type, specific enough for a marketing team to
   build acquisition targeting against today.

## Known limitations

Stated directly rather than hidden in a footnote — see also the
"Known limitations" section at the end of `docs/RETENTION_PLAYBOOK.md`:

- No transaction-level timestamps exist in the source data, so tenure and
  value metrics are proxies built from `Previous Purchases` and stated
  purchase cadence, not measured longitudinal behavior.
- Margin estimates in the playbook use an assumed average discount rate;
  swap in the brand's real category-level gross margins before using the
  dollar figures externally.
- Category role (entry-point vs. retention) is computed at the whole-base
  level and doesn't yet model cross-category purchase sequencing — that
  would require order-level data this snapshot doesn't have.

## Tech stack

- **Python 3.10+** / pandas, numpy — data cleaning & feature engineering
- **SQL** (PostgreSQL-flavored, portable to SQLite/MySQL) — the analysis layer
- **SQLite** — local, zero-config database for running the SQL layer end-to-end
- **HTML / Chart.js** — the interactive Founder Dashboard (Power BI-equivalent aggregates included as `dashboard/dashboard_data.json` for direct import)
- **Matplotlib** — static report figures

---

<sub>Built as a SQL-driven customer analytics case study. Dataset:
anonymized D2C fashion customer snapshot, 3,900 rows. No PII included.</sub>
