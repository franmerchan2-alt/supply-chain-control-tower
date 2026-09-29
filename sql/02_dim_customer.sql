-- =====================================
-- PHASE 2 - DIMENSIONAL MODELING
-- DIM_CUSTOMER CREATION
-- =====================================

-- Create customer dimension table.
CREATE TABLE analytics.dim_customer (
    order_customer_id BIGINT PRIMARY KEY,
    customer_fname TEXT,
    customer_lname TEXT,
    customer_segment TEXT,
    customer_city TEXT,
    customer_state TEXT,
    customer_country TEXT,
    customer_zipcode TEXT,
    customer_region TEXT
);

-- =====================================
-- DATA QUALITY INVESTIGATION
-- =====================================

-- Attempt to insert caused duplicate key error.
-- Investigation to find which column causes inconsistency.

-- Step 1: Check how many customer IDs produce more than one
-- distinct row after DISTINCT across all attributes.
SELECT "Customer Id", COUNT(*)
FROM (
    SELECT DISTINCT
        "Customer Id"::BIGINT,
        "Customer Fname",
        "Customer Lname",
        "Customer Segment",
        "Customer City",
        "Customer Country",
        "Customer Zipcode"::TEXT,
        "Customer State",
        "Market"
    FROM supply_chain.raw_dataco
) subquery
GROUP BY "Customer Id"
HAVING COUNT(*) > 1;

-- RESULT: 11,299 customer IDs produce more than one row.
-- → Market column is causing the split.

-- Step 2: Inspect a specific customer to confirm.
SELECT DISTINCT
    "Customer Id",
    "Customer Fname",
    "Customer Lname",
    "Customer Segment",
    "Customer City",
    "Customer Country",
    "Customer Zipcode"::TEXT,
    "Customer State",
    "Market"
FROM supply_chain.raw_dataco
WHERE "Customer Id" = 11233;

-- RESULT: Same customer (Mary Murphy) appears 3 times
-- with different Market values (Europe, LATAM, USCA).
-- → Market is an order-level attribute, not a customer attribute.
-- → Cannot be used as customer_region in dim_customer.

-- DECISION: Derive customer_region from Customer Country
-- using a CASE statement. More reliable than trusting Market.
-- Next step: query distinct countries to build the mapping.

-- =====================================
-- DATA QUALITY INVESTIGATION
-- customer_region
-- =====================================

-- Check distinct countries to evaluate customer_region feasibility
SELECT DISTINCT
    "Customer Country" AS country
FROM supply_chain.raw_dataco
ORDER BY country ASC;

-- RESULT: Only US and Puerto Rico.
-- customer_region adds no analytical value at customer level.
-- Regional analysis belongs in dim_shipping_fulfillment (order geography).
-- DECISION: Drop customer_region from dim_customer.

ALTER TABLE analytics.dim_customer
DROP COLUMN customer_region;

-- =====================================
-- INSERT
-- =====================================

INSERT INTO analytics.dim_customer
SELECT DISTINCT
    "Customer Id"::BIGINT,
    "Customer Fname",
    "Customer Lname",
    "Customer Segment",
    "Customer City",
    "Customer State",
    "Customer Country",
    "Customer Zipcode"::TEXT
FROM supply_chain.raw_dataco;

-- =====================================
-- VALIDATION
-- =====================================

SELECT order_customer_id, COUNT(*)
FROM analytics.dim_customer
GROUP BY order_customer_id
HAVING COUNT(*) > 1;

-- RESULT: 0 rows returned. No duplicate primary keys.
-- 20,652 unique customers loaded successfully.
-- dim_customer complete.

