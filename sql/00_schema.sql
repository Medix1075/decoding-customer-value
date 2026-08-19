-- =============================================================================
-- 00_schema.sql
-- Schema for the analytical table produced by python/feature_engineering.py
-- Target dialect: PostgreSQL (portable to MySQL / SQLite with minor tweaks)
-- =============================================================================

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id             INTEGER PRIMARY KEY,
    age                     INTEGER,
    gender                  VARCHAR(10),
    item_purchased           VARCHAR(50),
    category                VARCHAR(30),
    purchase_amount_usd      NUMERIC(10,2),
    location                VARCHAR(50),
    size                    VARCHAR(5),
    color                   VARCHAR(30),
    season                  VARCHAR(10),
    review_rating            NUMERIC(3,1),
    subscription_status      BOOLEAN,
    shipping_type            VARCHAR(30),
    discount_applied         BOOLEAN,
    promo_code_used          BOOLEAN,
    previous_purchases       INTEGER,
    payment_method           VARCHAR(30),
    frequency_of_purchases    VARCHAR(20),

    -- Engineered features (see python/feature_engineering.py for derivation logic)
    purchase_cadence_days    INTEGER,        -- approx. days between orders, from stated frequency
    est_annual_orders        NUMERIC(6,2),    -- 365 / purchase_cadence_days
    est_annual_value         NUMERIC(10,2),   -- annualized spend proxy
    tenure_orders            INTEGER,        -- = previous_purchases, loyalty/tenure proxy
    is_high_tenure           BOOLEAN,        -- top quartile of tenure_orders
    lifetime_value_proxy     NUMERIC(10,2),   -- purchase_amount * (previous_purchases + 1)
    promo_dependency_score   INTEGER,        -- 0-3, sum of discount/promo/subscription flags
    is_promo_dependent       BOOLEAN,        -- promo_dependency_score >= 2
    is_organic_high_value    BOOLEAN,        -- above-median spend, zero discount/promo usage
    satisfaction_score       NUMERIC(3,1),   -- = review_rating (imputed)
    is_at_risk_dissatisfied  BOOLEAN,        -- review_rating <= 2.5
    customer_value_score     NUMERIC(5,1),   -- 0-100 composite percentile score
    value_tier               VARCHAR(10),     -- Platinum / Gold / Silver / Bronze
    category_role            VARCHAR(25)      -- Retention Category / Entry-Point Category
);

CREATE INDEX idx_customers_value_tier ON customers (value_tier);
CREATE INDEX idx_customers_location   ON customers (location);
CREATE INDEX idx_customers_category   ON customers (category);
