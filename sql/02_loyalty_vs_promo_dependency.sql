-- =============================================================================
-- 02_loyalty_vs_promo_dependency.sql
-- Business question answered: "Who are the genuinely loyal customers vs.
-- those who only buy when there is a discount? Is the discount/promo program
-- actually building a loyal customer base, or just attracting one-time
-- bargain hunters?"
-- Powers: Founder Dashboard - Panel 2 (Promo Dependency vs. Retention Rate)
-- =============================================================================

SELECT
    CASE WHEN is_promo_dependent THEN 'Discount-Driven' ELSE 'Organic / Loyal' END AS customer_type,
    COUNT(*)                                                          AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                AS pct_of_base,
    ROUND(AVG(tenure_orders), 1)                                      AS avg_tenure_orders,
    ROUND(100.0 * SUM(CASE WHEN is_high_tenure THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                       AS pct_high_tenure,
    ROUND(AVG(est_annual_value), 2)                                   AS avg_annual_value,
    ROUND(AVG(satisfaction_score), 2)                                 AS avg_satisfaction
FROM customers
GROUP BY customer_type;

-- Deeper cut: does promo dependency change by value tier?
-- This is the number the "Promotional Sunset Plan" recommendation is graded
-- against -- a tier can only be safely weaned off discounts if its
-- non-discount cohort already proves people will pay full price.
SELECT
    value_tier,
    ROUND(100.0 * SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promo_dependent,
    ROUND(AVG(CASE WHEN is_promo_dependent THEN tenure_orders END), 1)   AS avg_tenure_if_promo_driven,
    ROUND(AVG(CASE WHEN NOT is_promo_dependent THEN tenure_orders END), 1) AS avg_tenure_if_organic
FROM customers
GROUP BY value_tier
ORDER BY pct_promo_dependent DESC;

-- Interpretation: if avg_tenure_if_organic >= avg_tenure_if_promo_driven for
-- a tier, that tier's loyalty is NOT explained by discounting -- it's a safe
-- candidate to reduce promo spend on. If the discount-driven cohort shows
-- HIGHER tenure, the tier still needs the incentive to stay engaged.
