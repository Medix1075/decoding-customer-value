-- =============================================================================
-- 06_promotional_sunset_candidates.sql
-- Business question answered: "How should the brand restructure its
-- promotional strategy to protect margins without losing volume?"
-- Powers: Retention Playbook - Promotional Sunset Plan deliverable
--
-- Logic: a (value_tier x category_role) cell is a SAFE candidate to reduce
-- discounting on when its ORGANIC customers already show tenure and spend
-- at or above the DISCOUNT-DRIVEN customers in the same cell. If organic
-- customers in a cell under-perform the discount-driven ones, that segment
-- still needs the incentive -- pulling it would cost volume, not just margin.
-- =============================================================================

WITH cell_stats AS (
    SELECT
        value_tier,
        category_role,
        is_promo_dependent,
        COUNT(*)                             AS customers,
        ROUND(AVG(tenure_orders), 1)         AS avg_tenure,
        ROUND(AVG(purchase_amount_usd), 2)   AS avg_order_value
    FROM customers
    GROUP BY value_tier, category_role, is_promo_dependent
),
pivoted AS (
    SELECT
        value_tier,
        category_role,
        MAX(CASE WHEN is_promo_dependent THEN customers END)       AS discount_driven_customers,
        MAX(CASE WHEN is_promo_dependent THEN avg_order_value END) AS discount_driven_avg_order,
        MAX(CASE WHEN NOT is_promo_dependent THEN customers END)      AS organic_customers,
        MAX(CASE WHEN NOT is_promo_dependent THEN avg_order_value END) AS organic_avg_order
    FROM cell_stats
    GROUP BY value_tier, category_role
)
SELECT
    value_tier,
    category_role,
    organic_customers,
    organic_avg_order,
    discount_driven_customers,
    discount_driven_avg_order,
    CASE
        WHEN organic_avg_order >= discount_driven_avg_order
             AND value_tier IN ('Platinum', 'Gold')
            THEN 'SUNSET CANDIDATE'
        ELSE 'KEEP PROMOTING'
    END AS recommendation
FROM pivoted
ORDER BY value_tier, category_role;

-- This table is the evidence base for the Promotional Sunset Plan: every
-- row flagged SUNSET CANDIDATE names a specific (tier, category role) cell
-- where full-price behavior is already proven, so the trigger, rollout, and
-- tracking metric in the written recommendation can cite these numbers directly.
