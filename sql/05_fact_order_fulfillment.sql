-- =====================================
-- PHASE 2 - DIMENSIONAL MODELING
-- FACT TABLE CREATION
-- fact_order_fulfillment
-- =====================================

-- Grain: 1 row = 1 order item (Order Item Id)
-- Foreign keys: dim_customer, dim_product, dim_date (x2), dim_shipping_fulfillment
-- Degenerate dimension: order_id (kept in fact for drill-through to order header)

-- =====================================
-- DATA VALIDATION
-- =====================================

-- Null check on key columns.
SELECT
    COUNT(*) FILTER (WHERE "Order Item Id" IS NULL)           AS null_pk,
    COUNT(*) FILTER (WHERE "Order Id" IS NULL)                AS null_order_id,
    COUNT(*) FILTER (WHERE "Order Customer Id" IS NULL)       AS null_customer_id,
    COUNT(*) FILTER (WHERE "Order Item Cardprod Id" IS NULL)  AS null_product_id,
    COUNT(*) FILTER (WHERE "order date (DateOrders)" IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE "shipping date (DateOrders)" IS NULL) AS null_shipping_date,
    COUNT(*) FILTER (WHERE "Sales" IS NULL)                   AS null_sales,
    COUNT(*) FILTER (WHERE "Order Item Quantity" IS NULL)     AS null_quantity,
    COUNT(*) FILTER (WHERE "Order Profit Per Order" IS NULL)  AS null_profit
FROM supply_chain.raw_dataco;
-- RESULT: 0 nulls across all columns.

-- Zero value check on numeric measures.
SELECT
    COUNT(*) FILTER (WHERE "Sales" = 0)                         AS zero_sales,
    COUNT(*) FILTER (WHERE "Order Item Total" = 0)              AS zero_order_item_total,
    COUNT(*) FILTER (WHERE "Order Item Quantity" = 0)           AS zero_quantity,
    COUNT(*) FILTER (WHERE "Benefit per order" = 0)             AS zero_benefit,
    COUNT(*) FILTER (WHERE "Order Profit Per Order" = 0)        AS zero_profit,
    COUNT(*) FILTER (WHERE "Order Item Profit Ratio" = 0)       AS zero_profit_ratio,
    COUNT(*) FILTER (WHERE "Order Item Discount" = 0)           AS zero_discount,
    COUNT(*) FILTER (WHERE "Order Item Discount Rate" = 0)      AS zero_discount_rate,
    COUNT(*) FILTER (WHERE "Order Item Product Price" = 0)      AS zero_product_price,
    COUNT(*) FILTER (WHERE "Days for shipping (real)" = 0)      AS zero_days_real,
    COUNT(*) FILTER (WHERE "Days for shipment (scheduled)" = 0) AS zero_days_scheduled
FROM supply_chain.raw_dataco;
-- RESULT: Zero values exist but all are operationally valid:
-- zero_benefit / zero_profit / zero_profit_ratio: orders that break even.
-- zero_discount / zero_discount_rate: orders with no discount applied.
-- zero_days_real: same-day shipments.
-- zero_days_scheduled: confirmed below — only Same Day shipping mode.

-- Confirm zero scheduled days belong to Same Day shipping only.
SELECT DISTINCT "Shipping Mode", "Days for shipment (scheduled)"
FROM supply_chain.raw_dataco
WHERE "Days for shipment (scheduled)" = 0
ORDER BY "Shipping Mode";
-- RESULT: Only Same Day shipping has 0 scheduled days. Operationally valid.

-- =====================================
-- CREATE TABLE
-- =====================================

CREATE TABLE analytics.fact_order_fulfillment (
    order_item_id               BIGINT  PRIMARY KEY,
    order_id                    BIGINT,
    order_customer_id           BIGINT  REFERENCES analytics.dim_customer(order_customer_id),
    order_item_cardprod_id      BIGINT  REFERENCES analytics.dim_product(order_item_cardprod_id),
    order_date_key              INTEGER REFERENCES analytics.dim_date(date_key),
    shipping_date_key           INTEGER REFERENCES analytics.dim_date(date_key),
    shipping_fulfillment_id     INTEGER REFERENCES analytics.dim_shipping_fulfillment(shipping_fulfillment_id),
    sales                       NUMERIC,
    order_item_total            NUMERIC,
    order_item_quantity         INTEGER,
    benefit_per_order           NUMERIC,
    order_profit_per_order      NUMERIC,
    order_item_profit_ratio     NUMERIC,
    order_item_discount         NUMERIC,
    order_item_discount_rate    NUMERIC,
    order_item_product_price    NUMERIC,
    days_for_shipping_real      INTEGER,
    days_for_shipment_scheduled INTEGER,
    late_delivery_risk          SMALLINT
);
-- order_date_key and shipping_date_key both reference dim_date(date_key).
-- This is the role-playing pattern — same dimension, two roles.
-- shipping_fulfillment_id is INTEGER to match the SERIAL type in dim_shipping_fulfillment.
-- late_delivery_risk is SMALLINT — binary flag (0 = No, 1 = Yes).
-- order_id kept as degenerate dimension — no separate dim_order created.

-- =====================================
-- INSERT
-- =====================================

-- shipping_fulfillment_id requires a correlated subquery.
-- It does not exist in the raw table — it was generated with SERIAL.
-- For each raw row, the subquery matches shipping attributes against
-- dim_shipping_fulfillment and returns the correct surrogate key.
-- Raw table aliased as r so the subquery can reference outer columns.
INSERT INTO analytics.fact_order_fulfillment
SELECT DISTINCT
    r."Order Item Id"::BIGINT,
    r."Order Id"::BIGINT,
    r."Order Customer Id"::BIGINT,
    r."Order Item Cardprod Id"::BIGINT,
    TO_CHAR(TO_TIMESTAMP(r."order date (DateOrders)", 'MM/DD/YYYY HH24:MI'), 'YYYYMMDD')::INTEGER,
    TO_CHAR(TO_TIMESTAMP(r."shipping date (DateOrders)", 'MM/DD/YYYY HH24:MI'), 'YYYYMMDD')::INTEGER,
    (SELECT d.shipping_fulfillment_id
     FROM analytics.dim_shipping_fulfillment d
     WHERE d.shipping_mode   = r."Shipping Mode"
       AND d.delivery_status = r."Delivery Status"
       AND d.market          = r."Market"
       AND d.order_region    = r."Order Region"
       AND d.order_country   = r."Order Country"
       AND d.order_state     = r."Order State"
       AND d.order_city      = r."Order City"),
    r."Sales"::NUMERIC,
    r."Order Item Total"::NUMERIC,
    r."Order Item Quantity"::INTEGER,
    r."Benefit per order"::NUMERIC,
    r."Order Profit Per Order"::NUMERIC,
    r."Order Item Profit Ratio"::NUMERIC,
    r."Order Item Discount"::NUMERIC,
    r."Order Item Discount Rate"::NUMERIC,
    r."Order Item Product Price"::NUMERIC,
    r."Days for shipping (real)"::INTEGER,
    r."Days for shipment (scheduled)"::INTEGER,
    r."Late_delivery_risk"::SMALLINT
FROM supply_chain.raw_dataco AS r;
-- RESULT: 180,519 rows inserted.

-- =====================================
-- VALIDATION
-- =====================================

SELECT order_item_id, COUNT(*)
FROM analytics.fact_order_fulfillment
GROUP BY order_item_id
HAVING COUNT(*) > 1;
-- RESULT: 0 rows returned. No duplicate primary keys.
-- fact_order_fulfillment complete. M2 complete.