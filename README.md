# Kaufly Analytics

dbt analytics pipeline for **Kaufly**, a fictional multi-category e-commerce platform serving customers across Germany, Austria, and Switzerland (DACH region).

## About Kaufly

Kaufly is a Berlin-based e-commerce platform offering fashion, electronics, and home & living products from over 2,000 brands. In 2024, Kaufly launched **Kaufly+**, a monthly membership programme (EUR 7.99/month) offering free standard delivery, 10% member discounts, early access to sales, and priority customer support.

## Project overview

This project models 18 months of synthetic e-commerce data (Jan 2024 -- Jun 2025) through a dbt transformation pipeline, producing analytical models across four domains:

- **Product** -- conversion funnels, customer cohorts, repeat purchase analysis
- **Operations** -- delivery performance, return rates, carrier comparison
- **Revenue** -- daily revenue, average order value, customer lifetime value
- **Membership** -- Kaufly+ impact on behaviour, membership retention, benefit usage, LTV uplift

## Data

50,000 customers | 130,000 orders | 960,000 events | 7,300 memberships

Generated using a Python script (`scripts/generate.py`) that simulates realistic e-commerce patterns including seasonal spikes (Black Friday, Christmas), membership-driven behavioural differences, funnel drop-offs, and delivery variability across carriers and countries.

### Source tables

| Table | Description |
|---|---|
| `raw.customers` | Customer registrations with country, city, acquisition channel |
| `raw.events` | Clickstream events (page views, product views, cart, checkout) |
| `raw.orders` | Orders with status, totals, discounts, payment and shipping method |
| `raw.order_items` | Line items per order with product, quantity, unit price |
| `raw.products` | Product catalogue with category, subcategory, brand, price |
| `raw.deliveries` | Shipment tracking with carrier, warehouse, estimated and actual delivery |
| `raw.returns` | Return requests with reason, dates, refund amount |
| `raw.memberships` | Kaufly+ subscriptions with start/end dates and status |
| `raw.membership_benefits` | Benefit usage log (free delivery, discounts) tied to orders |

## Tech stack

- **Warehouse**: PostgreSQL
- **Transformation**: dbt-core
- **Data generation**: Python (pandas, numpy)
- **Visualisation**: Tableau

## Project structure

```
kaufly-analytics/
  scripts/
    generate.py          # synthetic data generator
  models/
    staging/             # cleaned, typed, renamed source tables
    intermediate/        # business logic building blocks
    marts/
      product/           # conversion funnels, cohorts, repeat purchase
      operations/        # delivery performance, returns, carrier comparison
      revenue/           # daily revenue, AOV, CLV
      membership/        # Kaufly+ impact, retention, benefit usage
  tests/                 # data quality tests
  macros/                # reusable SQL macros
```

## Setup

### 1. Generate data

```bash
pip install pandas numpy
cd scripts
python generate.py
```

### 2. Load into PostgreSQL

```bash
psql -d kaufly -f scripts/load_raw.sql
```

### 3. Run dbt

```bash
dbt deps
dbt run
dbt test
```

## Dashboards

Tableau dashboards published at [Tableau Public](https://public.tableau.com/app/profile/abdulbasit.ayoade) (coming soon).

## Author

**Abdulbasit Ayoade**
- [Portfolio](https://portfolio-basit4.vercel.app)
- [GitHub](https://github.com/basseat)
- [Substack](https://basseat.substack.com)
