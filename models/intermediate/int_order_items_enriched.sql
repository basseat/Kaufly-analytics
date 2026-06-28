with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_date,
        status as order_status
    from {{ ref('stg_orders') }}
)

select
    oi.order_item_id,
    oi.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    oi.product_id,
    p.brand,
    p.category,
    p.subcategory,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    p.price as current_price

from order_items oi
inner join products p on oi.product_id = p.product_id
inner join orders o on oi.order_id = o.order_id
