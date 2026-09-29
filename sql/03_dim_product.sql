-- =====================================
-- PHASE 2 - DIMENSIONAL MODELING
-- DIM_PRODUCT CREATION
-- =====================================

-- =====================================
-- PK INVESTIGATION
-- =====================================

-- Two candidate columns for PK: Order Item Cardprod Id and Product Card Id.
-- Check if they carry the same values.
SELECT DISTINCT
    "Order Item Cardprod Id",
    "Product Card Id",
    "Product Name"
FROM supply_chain.raw_dataco
LIMIT 20;
-- Both columns appear identical at first glance.
-- Formal validation needed.

-- Validate 1-to-1 relationship between both ID columns.
SELECT "Order Item Cardprod Id", COUNT(DISTINCT "Product Card Id")
FROM supply_chain.raw_dataco
GROUP BY "Order Item Cardprod Id"
HAVING COUNT(DISTINCT "Product Card Id") > 1;
-- RESULT: 0 rows returned.
-- Both columns are equivalent — confirmed 1-to-1 mapping.
-- DECISION: order_item_cardprod_id used as PK for consistency 
-- with the fact table foreign key. product_card_id kept as attribute.

-- Validate PK candidate: no NULLs, no zeros.
SELECT "Order Item Cardprod Id"
FROM supply_chain.raw_dataco
WHERE "Order Item Cardprod Id" IS NULL
    OR "Order Item Cardprod Id" = 0;
-- RESULT: 0 rows returned.
-- order_item_cardprod_id is suitable as primary key.

-- =====================================
-- COLUMN INVESTIGATION
-- =====================================

-- Product Description: check for non-null values.
SELECT "Product Description"
FROM supply_chain.raw_dataco
WHERE "Product Description" IS NOT NULL
LIMIT 20;
-- RESULT: 0 rows returned. Column is entirely null.
-- DECISION: Product Description excluded from dimension.

-- Product Status: check distinct values.
SELECT DISTINCT "Product Status"
FROM supply_chain.raw_dataco;
-- RESULT: Only value is 0. No analytical value.
-- DECISION: Product Status excluded from dimension.

-- Category Id vs Product Category Id: check if identical.
SELECT DISTINCT
    "Category Id",
    "Product Category Id"
FROM supply_chain.raw_dataco
LIMIT 20;
-- Both appear identical. Formal validation:

SELECT "Category Id", COUNT(DISTINCT "Product Category Id")
FROM supply_chain.raw_dataco
GROUP BY "Category Id"
HAVING COUNT(DISTINCT "Product Category Id") > 1;
-- RESULT: 0 rows returned. Both columns are identical.
-- DECISION: product_category_id excluded. category_id kept.

-- NOTE: Category and Department kept inside dim_product (not split).
-- MVP decision — no business question requires standalone 
-- category or department dimensions at this stage.

-- =====================================
-- CREATE TABLE
-- =====================================

CREATE TABLE analytics.dim_product (
    order_item_cardprod_id BIGINT PRIMARY KEY,
    product_card_id        BIGINT,
    product_name           TEXT,
    product_price          NUMERIC,
    category_id            BIGINT,
    category_name          TEXT,
    department_id          BIGINT,
    department_name        TEXT
);

-- =====================================
-- INSERT
-- =====================================

INSERT INTO analytics.dim_product
SELECT DISTINCT
    "Order Item Cardprod Id"::BIGINT,
    "Product Card Id"::BIGINT,
    "Product Name",
    "Product Price"::NUMERIC,
    "Category Id"::BIGINT,
    "Category Name",
    "Department Id"::BIGINT,
    "Department Name"
FROM supply_chain.raw_dataco;

-- =====================================
-- VALIDATION
-- =====================================

SELECT order_item_cardprod_id, COUNT(*)
FROM analytics.dim_product
GROUP BY order_item_cardprod_id
HAVING COUNT(*) > 1;
-- RESULT: 0 rows returned. No duplicate primary keys.
-- 118 unique products loaded successfully.
-- dim_product complete.