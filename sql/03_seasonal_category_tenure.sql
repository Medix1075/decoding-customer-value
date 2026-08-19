-- =============================================================================
-- 03_seasonal_category_tenure.sql
-- Business question answered: "Which seasons and categories are associated
-- with lower-tenure customers versus those with high previous purchase
-- counts?"
-- Powers: Founder Dashboard - Panel 4 (Category Funnel) seasonal cut
-- =============================================================================

SELECT
    season,
    category,
    COUNT(*)                              AS customers,
    ROUND(AVG(tenure_orders), 1)          AS avg_tenure_orders,
    ROUND(AVG(purchase_amount_usd), 2)    AS avg_order_value,
    ROUND(100.0 * SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END) / COUNT(*), 1)
                                           AS pct_promo_dependent
FROM customers
GROUP BY season, category
ORDER BY avg_tenure_orders ASC;

-- Category-level roll-up (ignores season) - this is the direct input to the
-- Category Funnel panel and to category_role in the feature table.
SELECT
    category,
    COUNT(*)                              AS customers,
    ROUND(AVG(tenure_orders), 1)          AS avg_tenure_orders,
    ROUND(AVG(purchase_amount_usd), 2)    AS avg_order_value,
    ROUND(100.0 * SUM(CASE WHEN is_promo_dependent THEN 1 ELSE 0 END) / COUNT(*), 1)
                                           AS pct_promo_dependent,
    CASE
        WHEN AVG(tenure_orders) >= (SELECT AVG(tenure_orders) FROM customers)
            THEN 'Retention Category'
        ELSE 'Entry-Point Category'
    END                                    AS category_role
FROM customers
GROUP BY category
ORDER BY avg_tenure_orders DESC;

-- Interpretation: low-avg_tenure categories are where new customers land
-- first (entry points) -- fine to discount here to convert first-timers.
-- High-avg_tenure categories are where retained customers spend once they
-- already trust the brand -- discounting here mostly erodes margin on
-- demand that was already going to happen.
