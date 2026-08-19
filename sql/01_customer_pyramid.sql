-- =============================================================================
-- 01_customer_pyramid.sql
-- Business question answered: "What separates high-value customers from
-- low-value ones, and which profiles show the strongest repeat purchase
-- behavior?"
-- Powers: Founder Dashboard - Panel 1 (Customer Pyramid)
-- =============================================================================

SELECT
    value_tier,
    COUNT(*)                                                    AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)          AS pct_of_base,
    ROUND(AVG(est_annual_value), 2)                             AS avg_annual_value,
    ROUND(SUM(est_annual_value), 0)                             AS segment_annual_value,
    ROUND(AVG(tenure_orders), 1)                                AS avg_tenure_orders,
    ROUND(100.0 * SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                 AS pct_promo_dependent,
    ROUND(AVG(satisfaction_score), 2)                           AS avg_satisfaction
FROM customers
GROUP BY value_tier
ORDER BY avg_annual_value DESC;

-- Reading this table:
--   * Platinum/Gold tiers with LOW pct_promo_dependent + HIGH avg_tenure_orders
--     are the brand's real loyalty base -> protect and study them.
--   * Any tier where pct_promo_dependent is high AND avg_tenure_orders is low
--     is a rented, not owned, customer -> discount is doing all the work.
--   * segment_annual_value shows where revenue concentration actually sits,
--     which is what should drive where retention budget goes.
