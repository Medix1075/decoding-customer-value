-- =============================================================================
-- 04_geographic_opportunity.sql
-- Business question answered: "Are there cities or regions where the brand
-- has strong traction that it has not yet deliberately targeted? Which
-- geographies signal organic demand versus discount-driven volume?"
-- Powers: Founder Dashboard - Panel 3 (Geographic Opportunity Map)
-- =============================================================================

WITH state_stats AS (
    SELECT
        location,
        COUNT(*)                                                            AS customers,
        ROUND(AVG(purchase_amount_usd), 2)                                  AS avg_spend,
        ROUND(AVG(est_annual_value), 2)                                     AS avg_annual_value,
        ROUND(100.0 * SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                             AS pct_promo_dependent,
        ROUND(AVG(customer_value_score), 1)                                 AS avg_value_score
    FROM customers
    GROUP BY location
)
SELECT
    location,
    customers,
    avg_spend,
    avg_annual_value,
    pct_promo_dependent,
    avg_value_score,
    CASE
        WHEN avg_spend >= (SELECT AVG(avg_spend) FROM state_stats)
             AND pct_promo_dependent <= (SELECT AVG(pct_promo_dependent) FROM state_stats)
            THEN 'Organic High-Traction'          -- high spend, low promo need = real brand pull
        WHEN avg_spend >= (SELECT AVG(avg_spend) FROM state_stats)
             AND pct_promo_dependent > (SELECT AVG(pct_promo_dependent) FROM state_stats)
            THEN 'Discount-Propped'                -- high spend but only because of promos
        WHEN avg_spend < (SELECT AVG(avg_spend) FROM state_stats)
             AND pct_promo_dependent <= (SELECT AVG(pct_promo_dependent) FROM state_stats)
            THEN 'Underleveraged'                  -- low spend, low promo dependency = untapped, not undervalued
        ELSE 'Low-Priority'
    END AS geo_opportunity_type
FROM state_stats
ORDER BY avg_spend DESC;

-- Interpretation for marketing budget allocation:
--   Organic High-Traction   -> double down: this demand exists without discounting
--   Underleveraged          -> the real growth opportunity: people already buy at
--                               full price, brand just hasn't invested in them
--   Discount-Propped        -> revenue looks fine but is a promo mirage; risky
--                               to raise spend targets here without margin review
--   Low-Priority            -> lowest ROI for incremental marketing spend
