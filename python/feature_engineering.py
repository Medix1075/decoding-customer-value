"""
feature_engineering.py
=======================
Turns the raw customer/transaction snapshot into a customer-level analytical
table that the SQL layer and the Founder Dashboard are built on top of.

WHY THIS FILE EXISTS
---------------------
The raw dataset gives one row per customer with their most recent purchase
plus a `Previous Purchases` counter. It does NOT give a full transaction log,
so classic RFM ("days since last order") can't be computed directly. Instead,
every feature below is a deliberate PROXY, built from signals that *are*
available, and every proxy is designed to answer one of the brand's five
business questions (see README.md -> Business Questions).

Design principle enforced throughout: a metric only ships if it changes a
decision. Each function docstring states which decision it feeds.

Run:
    python3 feature_engineering.py
Output:
    ../data/customer_features.csv
"""

import numpy as np
import pandas as pd

RAW_PATH = "../data/customer_data_raw.csv"
OUT_PATH = "../data/customer_features.csv"

# ---------------------------------------------------------------------------
# Reference maps
# ---------------------------------------------------------------------------

# Maps a stated purchase cadence to an approximate number of days between
# orders. Used to annualize spend so customers on different cadences become
# comparable ("weekly $50 shopper" vs "annual $50 shopper" are NOT the same
# value to the business, even though their single order looks identical).
FREQUENCY_TO_DAYS = {
    "Weekly": 7,
    "Fortnightly": 14,
    "Bi-Weekly": 14,
    "Monthly": 30,
    "Every 3 Months": 90,
    "Quarterly": 90,
    "Annually": 365,
}

DISCOUNT_ENTRY_CATEGORIES_HINT = None  # computed at runtime, kept for clarity


def load_raw(path: str = RAW_PATH) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]
    return df


def clean(df: pd.DataFrame) -> pd.DataFrame:
    """
    Data quality pass.
    Decision fed: nothing downstream should silently break because of a
    missing review score or stray whitespace in a categorical field.
    """
    df = df.copy()

    # Review Rating has ~1% missing values. Median imputation is used
    # instead of mean because ratings are bounded/ordinal (1-5) and skewed
    # toward the 3.0-4.5 band; median is more robust to that skew.
    df["Review Rating"] = df["Review Rating"].fillna(df["Review Rating"].median())

    # Normalize Yes/No style categoricals to booleans early so every
    # downstream feature reads cleanly instead of re-parsing strings.
    for col in ["Subscription Status", "Discount Applied", "Promo Code Used"]:
        df[col] = df[col].str.strip().eq("Yes")

    df["Frequency of Purchases"] = df["Frequency of Purchases"].str.strip()
    df["Category"] = df["Category"].str.strip()
    df["Location"] = df["Location"].str.strip()

    return df


def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # -----------------------------------------------------------------
    # 1) Cadence -> annualized behavioral metrics
    #    Decision fed: Q2 (is the discount program building loyalty or
    #    attracting bargain hunters?) and the customer pyramid, both of
    #    which need spend on a common time basis.
    # -----------------------------------------------------------------
    df["purchase_cadence_days"] = df["Frequency of Purchases"].map(FREQUENCY_TO_DAYS)
    df["est_annual_orders"] = 365 / df["purchase_cadence_days"]

    # Annualized spend proxy: current order value x how often that order
    # repeats in a year. This is the single most decision-relevant number
    # in the table because it is what the brand should actually budget
    # marketing spend against, not the one-off order value.
    df["est_annual_value"] = (df["Purchase Amount (USD)"] * df["est_annual_orders"]).round(2)

    # -----------------------------------------------------------------
    # 2) Tenure / loyalty proxy
    #    Decision fed: Q1 (loyal vs. discount-driven) and the customer
    #    pyramid's "how long have they stuck around" axis.
    # -----------------------------------------------------------------
    df["tenure_orders"] = df["Previous Purchases"]  # already an order count
    df["is_high_tenure"] = df["tenure_orders"] >= df["tenure_orders"].quantile(0.75)

    # Cumulative lifetime value proxy: order value scaled by the number of
    # orders the customer is known to have already placed. Deliberately
    # simple (no discounting/decay) because the raw data gives no purchase
    # dates to discount against — flagged as a known limitation in the
    # README rather than faked with invented dates.
    df["lifetime_value_proxy"] = (
        df["Purchase Amount (USD)"] * (df["Previous Purchases"] + 1)
    ).round(2)

    # -----------------------------------------------------------------
    # 3) Promotional dependency score (0-3)
    #    Decision fed: Q1 and the Promotional Sunset Plan — this is the
    #    single feature the "reduce discount dependency" recommendation
    #    is graded against.
    # -----------------------------------------------------------------
    df["promo_dependency_score"] = (
        df["Discount Applied"].astype(int)
        + df["Promo Code Used"].astype(int)
        + df["Subscription Status"].astype(int)  # subscribers skew promo-fed in this brand's model
    )
    df["is_promo_dependent"] = df["promo_dependency_score"] >= 2

    # Organic-demand flag: spends at/above the population median WITHOUT
    # any discount or promo code. This is the customer the brand wants
    # more of — proof that pull, not price, is doing the work.
    median_spend = df["Purchase Amount (USD)"].median()
    df["is_organic_high_value"] = (
        (~df["Discount Applied"]) & (~df["Promo Code Used"]) & (df["Purchase Amount (USD)"] >= median_spend)
    )

    # -----------------------------------------------------------------
    # 4) Satisfaction
    #    Decision fed: whether a segment is worth investing retention
    #    budget in at all — a high-value but low-satisfaction segment is
    #    a churn risk, not a loyalty story.
    # -----------------------------------------------------------------
    df["satisfaction_score"] = df["Review Rating"]
    df["is_at_risk_dissatisfied"] = df["Review Rating"] <= 2.5

    # -----------------------------------------------------------------
    # 5) Composite Customer Value Score (0-100) -> Customer Pyramid tier
    #    Decision fed: Founder Dashboard panel 1 (Customer Pyramid) and
    #    the "ideal customer profile" deliverable. Built from percentile
    #    ranks so the three inputs (spend, tenure, satisfaction) are
    #    comparable regardless of their raw scale, then weighted toward
    #    the two inputs the brand can act on (spend, tenure) over the
    #    one it can only observe (satisfaction).
    # -----------------------------------------------------------------
    pct_value = df["est_annual_value"].rank(pct=True)
    pct_tenure = df["tenure_orders"].rank(pct=True)
    pct_satisfaction = df["satisfaction_score"].rank(pct=True)

    df["customer_value_score"] = (
        0.5 * pct_value + 0.3 * pct_tenure + 0.2 * pct_satisfaction
    ) * 100
    df["customer_value_score"] = df["customer_value_score"].round(1)

    def tier(score: float) -> str:
        if score >= 80:
            return "Platinum"
        elif score >= 55:
            return "Gold"
        elif score >= 30:
            return "Silver"
        return "Bronze"

    df["value_tier"] = df["customer_value_score"].apply(tier)

    # -----------------------------------------------------------------
    # 6) Category role: entry-point vs retention category
    #    Decision fed: Founder Dashboard panel 4 (Category Funnel) and
    #    which categories to keep discounting vs. protect margin on.
    #    A category is "entry-point" if its buyers skew low-tenure; it's
    #    "retention" if its buyers skew high-tenure. Computed at the
    #    dataset level and joined back so every row carries its
    #    category's role.
    # -----------------------------------------------------------------
    category_tenure = df.groupby("Category")["tenure_orders"].mean()
    overall_avg_tenure = df["tenure_orders"].mean()
    category_role = category_tenure.apply(
        lambda x: "Retention Category" if x >= overall_avg_tenure else "Entry-Point Category"
    )
    df["category_role"] = df["Category"].map(category_role)

    return df


def summarize(df: pd.DataFrame) -> None:
    print("Rows:", len(df))
    print("\nValue tier distribution:")
    print(df["value_tier"].value_counts())
    print("\nPromo dependency rate:", round(df["is_promo_dependent"].mean() * 100, 1), "%")
    print("\nOrganic high-value customers:", int(df["is_organic_high_value"].sum()))
    print("\nCategory roles:")
    print(df.groupby("Category")["category_role"].first())


def main():
    raw = load_raw()
    cleaned = clean(raw)
    features = engineer_features(cleaned)
    features.to_csv(OUT_PATH, index=False)
    summarize(features)
    print(f"\nSaved -> {OUT_PATH}")


if __name__ == "__main__":
    main()
