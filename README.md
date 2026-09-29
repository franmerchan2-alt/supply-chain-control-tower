# Supply Chain Control Tower — P1: Descriptive Analytics & Data Warehouse

**Project 1 of 3** in a progressive Data Science portfolio built on the DataCo Smart Supply Chain dataset.

---

## What this project does

Transforms 180,519 raw supply chain order records into a clean PostgreSQL star schema warehouse, then surfaces operational KPIs through a Power BI dashboard — late delivery risk, profit by segment, fulfillment performance by region and shipping mode.

---

## Stack

| Layer | Tool |
|---|---|
| Warehouse | PostgreSQL 16 |
| Transformation | SQL (pure — no dbt) |
| Analysis | Python (pandas, matplotlib, seaborn) |
| Visualization | Power BI Desktop |

---

## Star schema

```
                    dim_date (order_date_key)
                         │
dim_customer ──── fact_order_fulfillment ──── dim_product
                         │
                    dim_date (shipping_date_key)
                         │
              dim_shipping_fulfillment
```

**Grain:** 1 row = 1 order item (`order_item_id`)

| Table | Rows | Key design decision |
|---|---|---|
| `fact_order_fulfillment` | 180,519 | Degenerate dimension: `order_id` kept in fact |
| `dim_date` | 1,132 | Role-playing: same table for order date and shipping date |
| `dim_customer` | 20,652 | Market dropped — order-level attribute, not customer-level |
| `dim_product` | 118 | Category + department denormalized (MVP) |
| `dim_shipping_fulfillment` | 16,606 | SERIAL surrogate key — no natural key exists |

---

## SQL scripts

Run in order:

```
sql/
├── 00_validation_raw_data.sql       # Phase 1 — grain check, date validation
├── 01_dim_date.sql                  # Phase 2 — date dimension
├── 02_dim_customer.sql              # Phase 2 — customer dimension
├── 03_dim_product.sql               # Phase 2 — product dimension
├── 04_dim_shipping_fulfillment.sql  # Phase 2 — shipping/fulfillment dimension
├── 05_fact_order_fulfillment.sql    # Phase 2 — fact table
└── 06_warehouse_validation.sql      # Phase 3 — row count, RI, business logic
```

Each script includes investigation queries and documented decisions alongside the DDL/DML.

---

## Setup

**Prerequisites:** PostgreSQL 16, Python 3.10+

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/supply-chain-control-tower.git
cd supply-chain-control-tower

# 2. Python environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Data
# Download DataCo dataset from Kaggle — see data/README.md
# Load into PostgreSQL as supply_chain.raw_dataco

# 4. Run SQL scripts in order (00 → 06)
```

---

## Dashboard

Power BI dashboard connected to the PostgreSQL warehouse. Screenshots in `dashboard/screenshots/`.

---

## Part of a 3-project portfolio

| Project | Focus | Status |
|---|---|---|
| P1 — Supply Chain Control Tower | Descriptive analytics + warehouse | ✅ Complete |
| P2 — Predictive Operations Analytics | Demand forecasting + lead-time risk (scikit-learn, statsmodels) | 🔜 Next |
| P3 — Optimization & Decision Models | Route + inventory optimization (OR-Tools) | 📋 Planned |
