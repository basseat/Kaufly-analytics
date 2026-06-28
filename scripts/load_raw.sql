CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.membership_benefits;
DROP TABLE IF EXISTS raw.memberships;
DROP TABLE IF EXISTS raw.returns;
DROP TABLE IF EXISTS raw.deliveries;
DROP TABLE IF EXISTS raw.order_items;
DROP TABLE IF EXISTS raw.orders;
DROP TABLE IF EXISTS raw.events;
DROP TABLE IF EXISTS raw.products;
DROP TABLE IF EXISTS raw.customers;

CREATE TABLE raw.customers (
    customer_id TEXT PRIMARY KEY,
    registered_at TIMESTAMP,
    country TEXT,
    city TEXT,
    acquisition_channel TEXT
);

CREATE TABLE raw.products (
    product_id TEXT PRIMARY KEY,
    category TEXT,
    subcategory TEXT,
    brand TEXT,
    price NUMERIC(10, 2),
    listed_at DATE
);

CREATE TABLE raw.events (
    event_id TEXT PRIMARY KEY,
    customer_id TEXT,
    event_name TEXT,
    event_timestamp TIMESTAMP,
    properties JSONB
);

CREATE TABLE raw.orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    ordered_at TIMESTAMP,
    status TEXT,
    total_amount NUMERIC(10, 2),
    discount_amount NUMERIC(10, 2),
    payment_method TEXT,
    shipping_method TEXT
);

CREATE TABLE raw.order_items (
    order_item_id TEXT PRIMARY KEY,
    order_id TEXT,
    product_id TEXT,
    quantity INTEGER,
    unit_price NUMERIC(10, 2)
);

CREATE TABLE raw.deliveries (
    delivery_id TEXT PRIMARY KEY,
    order_id TEXT,
    carrier TEXT,
    warehouse_city TEXT,
    shipped_at DATE,
    estimated_delivery_at DATE,
    delivered_at DATE,
    delivery_status TEXT
);

CREATE TABLE raw.returns (
    return_id TEXT PRIMARY KEY,
    order_id TEXT,
    order_item_id TEXT,
    initiated_at DATE,
    received_at DATE,
    reason TEXT,
    refund_amount NUMERIC(10, 2)
);

CREATE TABLE raw.memberships (
    membership_id TEXT PRIMARY KEY,
    customer_id TEXT,
    plan_name TEXT,
    started_at DATE,
    ended_at DATE,
    monthly_fee NUMERIC(5, 2),
    status TEXT
);

CREATE TABLE raw.membership_benefits (
    benefit_id TEXT PRIMARY KEY,
    membership_id TEXT,
    benefit_type TEXT,
    used_at TIMESTAMP,
    order_id TEXT
);

\copy raw.customers FROM 'data/customers.csv' WITH CSV HEADER
\copy raw.products FROM 'data/products.csv' WITH CSV HEADER
\copy raw.events FROM 'data/events.csv' WITH CSV HEADER
\copy raw.orders FROM 'data/orders.csv' WITH CSV HEADER
\copy raw.order_items FROM 'data/order_items.csv' WITH CSV HEADER
\copy raw.deliveries FROM 'data/deliveries.csv' WITH CSV HEADER
\copy raw.returns FROM 'data/returns.csv' WITH CSV HEADER
\copy raw.memberships FROM 'data/memberships.csv' WITH CSV HEADER
\copy raw.membership_benefits FROM 'data/membership_benefits.csv' WITH CSV HEADER
