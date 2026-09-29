# Data

The raw dataset used in this project is the **DataCo Smart Supply Chain for Big Data Analysis** dataset, published on Kaggle.

**Download:** https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis

After downloading, place the CSV file in this folder. It is excluded from version control via `.gitignore` — do not commit raw data to this repository.

## Dataset overview

| Property | Value |
|---|---|
| Rows | 180,519 |
| Source | Kaggle / DataCo Global |
| Format | CSV |
| Date range | 2015-01-01 → 2018-02-06 |

Once downloaded, the file is loaded into PostgreSQL under the `supply_chain` schema as `raw_dataco` before running any SQL scripts.
