-- =====================================
-- PHASE 3 - WAREHOUSE VALIDATION
-- 00_warehouse_validation.sql
-- =====================================

-- =====================================
-- CHECK 1: ROW COUNT
-- =====================================

-- Does the fact table have the same number of rows as the raw dataset?
SELECT COUNT(*)
FROM analytics.fact_order_fulfillment;
-- RESULT: 180,519 rows.

-- Side-by-side comparison against raw dataset.
-- No FROM clause needed at outer level — each subquery acts as its own source.
SELECT
    (SELECT COUNT(*) FROM supply_chain.raw_dataco)          AS raw_rows,
    (SELECT COUNT(*) FROM analytics.fact_order_fulfillment) AS fact_rows;
-- RESULT: Both return 180,519. Row count confirmed.

-- =====================================
-- CHECK 2: REFERENTIAL INTEGRITY
-- =====================================

-- Pattern: LEFT JOIN fact to dimension on FK/PK.
-- WHERE dimension PK IS NULL isolates orphaned rows — FKs with no match.
-- 0 rows returned = every FK has a valid match in its dimension.

-- dim_customer
SELECT f.order_customer_id
FROM analytics.fact_order_fulfillment AS f
LEFT JOIN analytics.dim_customer AS c
    ON f.order_customer_id = c.order_customer_id
WHERE c.order_customer_id IS NULL;
-- RESULT: 0 rows. Referential integrity confirmed.

-- dim_product
SELECT f.order_item_cardprod_id
FROM analytics.fact_order_fulfillment AS f
LEFT JOIN analytics.dim_product AS p
    ON f.order_item_cardprod_id = p.order_item_cardprod_id
WHERE p.order_item_cardprod_id IS NULL;
-- RESULT: 0 rows. Referential integrity confirmed.

-- dim_date — order_date_key (two checks required: two FK roles, same dimension)
SELECT f.order_date_key
FROM analytics.fact_order_fulfillment AS f
LEFT JOIN analytics.dim_date AS d
    ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL;
-- RESULT: 0 rows. Referential integrity confirmed.

-- dim_date — shipping_date_key
SELECT f.shipping_date_key
FROM analytics.fact_order_fulfillment AS f
LEFT JOIN analytics.dim_date AS d
    ON f.shipping_date_key = d.date_key
WHERE d.date_key IS NULL;
-- RESULT: 0 rows. Referential integrity confirmed.

-- dim_shipping_fulfillment
SELECT f.shipping_fulfillment_id
FROM analytics.fact_order_fulfillment AS f
LEFT JOIN analytics.dim_shipping_fulfillment AS sf
    ON f.shipping_fulfillment_id = sf.shipping_fulfillment_id
WHERE sf.shipping_fulfillment_id IS NULL;
-- RESULT: 0 rows. Referential integrity confirmed.

-- =====================================
-- CHECK 3: BUSINESS LOGIC
-- =====================================

-- Total sales in fact table vs raw dataset.
-- Values should match — any significant difference indicates data loss during INSERT.
SELECT
    (SELECT SUM(sales) FROM analytics.fact_order_fulfillment)    AS fact_sales,
    (SELECT SUM("Sales") FROM supply_chain.raw_dataco)           AS raw_sales;

-- RESULT:
-- fact_sales: 36,784,735.013379846 (NUMERIC — exact precision)
-- raw_sales:  36,784,735.013376944 (DOUBLE PRECISION — floating point)
-- Difference is in the 12th decimal place — operationally irrelevant.
-- This confirms the NUMERIC type decision in the fact table is correct.
-- The warehouse is more precise than the source data.
-- Business logic check passed. M3 complete.
