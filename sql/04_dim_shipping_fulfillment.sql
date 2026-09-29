-- =====================================
-- PHASE 2 - DIMENSIONAL MODELING
-- DIM_SHIPPING_FULFILLMENT CREATION
-- =====================================

-- =====================================
-- GRAIN & PK DECISION
-- =====================================

-- No natural key exists for this dimension.
-- Grain: one row = one unique combination of shipping attributes.
-- PK: surrogate key generated with SERIAL (auto-incrementing integer).
-- Unlike dim_customer and dim_product, no source ID uniquely 
-- identifies a fulfillment profile.

-- =====================================
-- VALIDATION
-- =====================================

-- Null check across all attributes.
SELECT 
    COUNT(*) FILTER (WHERE "Shipping Mode" IS NULL)    AS null_shipping_mode,
    COUNT(*) FILTER (WHERE "Delivery Status" IS NULL)  AS null_delivery_status,
    COUNT(*) FILTER (WHERE "Market" IS NULL)           AS null_market,
    COUNT(*) FILTER (WHERE "Order Region" IS NULL)     AS null_order_region,
    COUNT(*) FILTER (WHERE "Order Country" IS NULL)    AS null_order_country,
    COUNT(*) FILTER (WHERE "Order State" IS NULL)      AS null_order_state,
    COUNT(*) FILTER (WHERE "Order City" IS NULL)       AS null_order_city
FROM supply_chain.raw_dataco;
-- RESULT: 0 nulls across all columns.

-- Empty string check — different from NULL, equally problematic.
SELECT 
    COUNT(*) FILTER (WHERE "Shipping Mode" = '')    AS empty_shipping_mode,
    COUNT(*) FILTER (WHERE "Delivery Status" = '')  AS empty_delivery_status,
    COUNT(*) FILTER (WHERE "Market" = '')           AS empty_market,
    COUNT(*) FILTER (WHERE "Order Region" = '')     AS empty_order_region,
    COUNT(*) FILTER (WHERE "Order Country" = '')    AS empty_order_country,
    COUNT(*) FILTER (WHERE "Order State" = '')      AS empty_order_state,
    COUNT(*) FILTER (WHERE "Order City" = '')       AS empty_order_city
FROM supply_chain.raw_dataco;
-- RESULT: 0 empty strings across all columns.
-- Data is clean. Safe to proceed with INSERT.

-- NOTE: Market and Order Region carry different information.
-- Market = commercial grouping (Europe, LATAM, USCA...).
-- Order Region = geographic grouping (Western Europe, Southeast Asia...).
-- Both retained as they support different levels of analysis.

-- =====================================
-- CREATE TABLE
-- =====================================

CREATE TABLE analytics.dim_shipping_fulfillment (
    shipping_fulfillment_id SERIAL PRIMARY KEY,
    shipping_mode           TEXT,
    delivery_status         TEXT,
    market                  TEXT,
    order_region            TEXT,
    order_country           TEXT,
    order_state             TEXT,
    order_city              TEXT
);

-- =====================================
-- INSERT
-- =====================================

-- Column list required here because shipping_fulfillment_id 
-- is SERIAL — PostgreSQL fills it automatically.
-- Without the explicit column list, PostgreSQL cannot map
-- the 7 selected values to the 8 defined columns correctly.
INSERT INTO analytics.dim_shipping_fulfillment (
    shipping_mode,
    delivery_status,
    market,
    order_region,
    order_country,
    order_state,
    order_city
)
SELECT DISTINCT
    "Shipping Mode",
    "Delivery Status",
    "Market",
    "Order Region",
    "Order Country",
    "Order State",
    "Order City"
FROM supply_chain.raw_dataco;
-- RESULT: 16,606 unique fulfillment profiles loaded.

-- =====================================
-- VALIDATION
-- =====================================

SELECT shipping_fulfillment_id, COUNT(*)
FROM analytics.dim_shipping_fulfillment
GROUP BY shipping_fulfillment_id
HAVING COUNT(*) > 1;
-- RESULT: 0 rows returned. No duplicate primary keys.
-- dim_shipping_fulfillment complete.