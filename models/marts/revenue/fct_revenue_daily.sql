with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

order_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

daily_revenue as (
    select
        o.order_date,
        o.country,
        oi.category,
        o.is_member_order,
        count(distinct o.order_id) as order_count,
        sum(oi.line_total) as gross_revenue,
        count(distinct o.customer_id) as unique_customers,
        sum(oi.quantity) as units_sold,
        avg(o.net_amount) as avg_order_value
    from orders o
    inner join order_items oi on o.order_id = oi.order_id
    where o.order_status = 'delivered'
    group by o.order_date, o.country, oi.category, o.is_member_order
)

select
    order_date,
    country,
    category,
    is_member_order,
    order_count,
    gross_revenue,
    unique_customers,
    units_sold,
    avg_order_value,
    sum(gross_revenue) over (
        partition by country, category
        order by order_date
        rows between 6 preceding and current row
    ) as revenue_7d_rolling,
    sum(order_count) over (
        partition by country, category
        order by order_date
        rows between 6 preceding and current row
    ) as orders_7d_rolling

from daily_revenue
