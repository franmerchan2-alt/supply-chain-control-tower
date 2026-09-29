-- =====================================
-- PHASE 2 - DIMENSIONAL MODELING
-- DIM_DATE CREATION
-- =====================================

-- Create analytics schema for dimensional model.
CREATE SCHEMA analytics;

-- Create date dimension table.
CREATE TABLE analytics.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE
);

-- Populate date dimension using one generated row per calendar day
-- across the full date range detected in the raw dataset.
INSERT INTO analytics.dim_date (date_key, full_date)
SELECT
    TO_CHAR(date_series, 'YYYYMMDD')::INTEGER AS date_key,
    date_series::DATE AS full_date
FROM generate_series(
    '2015-01-01'::DATE,
    '2018-02-06'::DATE,
    INTERVAL '1 day'
) AS date_series;

-- Validation
SELECT *
FROM analytics.dim_date
LIMIT 10;

-- Add analytical attribute: year
ALTER TABLE analytics.dim_date
ADD COLUMN year INTEGER;
UPDATE analytics.dim_date
SET year = EXTRACT(YEAR FROM full_date);
-- First we add the column, then we enrich the inside.

-- Add analytical attribute: month and day (separate)
ALTER TABLE analytics.dim_date
ADD COLUMN month INTEGER;
UPDATE analytics.dim_date
SET month = EXTRACT(MONTH FROM full_date);

ALTER TABLE analytics.dim_date
ADD COLUMN day INTEGER;
UPDATE analytics.dim_date
SET day = EXTRACT(DAY FROM full_date);

--Add month_name:
ALTER TABLE analytics.dim_date
ADD COLUMN month_name TEXT;
UPDATE analytics.dim_date
SET month_name = TO_CHAR(full_date, 'Month');

--WRONG!!!!  Add day_of_week (number):
ALTER TABLE analytics.dim_date
ADD COLUMN day_of_week TEXT;
UPDATE analytics.dim_date
SET day_of_week = TRIM(TO_CHAR(full_date, 'Day'));
--Fixing day of the week (name) to align with STAR SCHEMA:
ALTER TABLE analytics.dim_date
RENAME COLUMN day_of_week TO day_name;

--Add day of the week as number:
ALTER TABLE analytics.dim_date
ADD COLUMN day_of_week INTEGER;
UPDATE analytics.dim_date
SET day_of_week = EXTRACT(DOW FROM full_date);

--Add quarter:
ALTER TABLE analytics.dim_date
ADD COLUMN quarter INTEGER;
UPDATE analytics.dim_date
SET quarter = EXTRACT(QUARTER FROM full_date);

--Add if it is weekend attribute:
ALTER TABLE analytics.dim_date
ADD COLUMN is_weekend BOOLEAN;

UPDATE analytics.dim_date
SET is_weekend = CASE
    WHEN day_of_week BETWEEN 1 AND 5 THEN FALSE
    ELSE TRUE
END;
--This time day_of_week already exists so no FROM in the UPDATE clause.