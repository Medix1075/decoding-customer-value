-- =============================================================================
-- 05_ideal_customer_profile.sql
-- Business question answered: "What does the brand's best customer actually
-- look like in terms of age, purchase habits, payment preferences, and
-- satisfaction? What does the brand's ideal customer profile look like, and
-- how can it acquire more of them?"
-- Powers: Retention Playbook - Ideal Customer Profile deliverable
-- =============================================================================

-- Step 1: isolate the Platinum tier (top ~5% by composite value score) and
-- profile it against the base population on every dimension marketing can
-- act on (age band, category, payment method, shipping, gender, season).

WITH platinum AS (
    SELECT * FROM customers WHERE value_tier = 'Platinum'
)
SELECT 'Age band' AS dimension,
       CASE
           WHEN age < 25 THEN '18-24'
           WHEN age < 35 THEN '25-34'
           WHEN age < 45 THEN '35-44'
           WHEN age < 55 THEN '45-54'
           ELSE '55+'
       END AS value,
       COUNT(*) AS platinum_customers,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM platinum), 1) AS pct_of_platinum
FROM platinum
GROUP BY 2
ORDER BY platinum_customers DESC;

-- Repeat the same pattern for the other acquisition-relevant dimensions:
WITH platinum AS (SELECT * FROM customers WHERE value_tier = 'Platinum')
SELECT 'Category' AS dimension, category AS value, COUNT(*) AS platinum_customers,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM platinum),1) AS pct_of_platinum
FROM platinum GROUP BY category ORDER BY platinum_customers DESC;

WITH platinum AS (SELECT * FROM customers WHERE value_tier = 'Platinum')
SELECT 'Payment Method' AS dimension, payment_method AS value, COUNT(*) AS platinum_customers,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM platinum),1) AS pct_of_platinum
FROM platinum GROUP BY payment_method ORDER BY platinum_customers DESC;

WITH platinum AS (SELECT * FROM customers WHERE value_tier = 'Platinum')
SELECT 'Shipping Type' AS dimension, shipping_type AS value, COUNT(*) AS platinum_customers,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM platinum),1) AS pct_of_platinum
FROM platinum GROUP BY shipping_type ORDER BY platinum_customers DESC;

-- Step 2: benchmark Platinum against the full base on the numeric signals
-- so the profile can be stated as "X% higher/lower than an average customer".
SELECT
    'Platinum' AS cohort,
    ROUND(AVG(age),1) AS avg_age,
    ROUND(AVG(purchase_amount_usd),2) AS avg_order_value,
    ROUND(AVG(tenure_orders),1) AS avg_tenure_orders,
    ROUND(AVG(satisfaction_score),2) AS avg_satisfaction,
    ROUND(100.0*SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_promo_dependent,
    ROUND(100.0*SUM(CASE WHEN subscription_status THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_subscribed
FROM customers WHERE value_tier = 'Platinum'
UNION ALL
SELECT
    'All Customers',
    ROUND(AVG(age),1), ROUND(AVG(purchase_amount_usd),2), ROUND(AVG(tenure_orders),1),
    ROUND(AVG(satisfaction_score),2),
    ROUND(100.0*SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END)/COUNT(*),1),
    ROUND(100.0*SUM(CASE WHEN subscription_status THEN 1 ELSE 0 END)/COUNT(*),1)
FROM customers;
