-- =====================================
-- PHASE 1 - RAW DATA VALIDATION
-- supply_chain.raw_dataco
-- =====================================

-- =====================================
-- GRAIN CHECK
-- =====================================

-- Confirm grain: 1 row = 1 order item (Order Item Id)
SELECT "Order Item Id", COUNT(*)
FROM supply_chain.raw_dataco
GROUP BY "Order Item Id"
HAVING COUNT(*) > 1;
-- RESULT: 0 rows returned. Grain confirmed.

-- Total row count
SELECT COUNT(*) FROM supply_chain.raw_dataco;
-- RESULT: 180,519 rows.

-- =====================================
-- DATE VALIDATION
-- =====================================

-- Check for NULL dates
SELECT
    COUNT(*) FILTER (WHERE "order date (DateOrders)" IS NULL)    AS null_order_date,
    COUNT(*) FILTER (WHERE "shipping date (DateOrders)" IS NULL) AS null_shipping_date
FROM supply_chain.raw_dataco;
-- RESULT: 0 nulls on both date columns.

-- Date range
SELECT
    MIN(TO_TIMESTAMP("order date (DateOrders)", 'MM/DD/YYYY HH24:MI'))::DATE AS min_order_date,
    MAX(TO_TIMESTAMP("order date (DateOrders)", 'MM/DD/YYYY HH24:MI'))::DATE AS max_order_date
FROM supply_chain.raw_dataco;
-- RESULT: 2015-01-01 to 2018-02-06

-- =====================================
-- DELIVERY TIME DISTRIBUTION
-- =====================================

-- Days for shipping (real) by shipping mode
SELECT
    "Shipping Mode",
    AVG("Days for shipping (real)")        AS avg_real_days,
    AVG("Days for shipment (scheduled)")   AS avg_scheduled_days,
    COUNT(*)                                AS order_count
FROM supply_chain.raw_dataco
GROUP BY "Shipping Mode"
ORDER BY avg_real_days;

-- Distribution of late delivery risk
SELECT
    "Late_delivery_risk",
    COUNT(*)                                      AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM supply_chain.raw_dataco
GROUP BY "Late_delivery_risk"
ORDER BY "Late_delivery_risk";
-- RESULT: Binary flag (0/1). ~55% late delivery risk across dataset.

-- Delivery status breakdown
SELECT
    "Delivery Status",
    COUNT(*) AS count
FROM supply_chain.raw_dataco
GROUP BY "Delivery Status"
ORDER BY count DESC;
