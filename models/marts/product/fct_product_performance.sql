with items as (
    select * from {{ ref('int_order_items_enriched') }}
),

product_sales as (
    select
        product_id,
        brand,
        category,
        subcategory,
        count(distinct order_id) as orders_containing_product,
        sum(quantity) as total_units_sold,
        sum(line_total) as total_revenue,
        avg(unit_price) as avg_selling_price,
        count(distinct customer_id) as unique_buyers,
        min(order_date) as first_sold_date,
        max(order_date) as last_sold_date
    from items
    where order_status = 'completed'
    group by product_id, brand, category, subcategory
),

product_returns as (
    select
        oi.product_id,
        count(*) as return_count
    from {{ ref('stg_returns') }} r
    inner join {{ ref('stg_order_items') }} oi on r.order_id = oi.order_id
    group by oi.product_id
)

select
    ps.product_id,
    ps.brand,
    ps.category,
    ps.subcategory,
    ps.orders_containing_product,
    ps.total_units_sold,
    ps.total_revenue,
    ps.avg_selling_price,
    ps.unique_buyers,
    ps.first_sold_date,
    ps.last_sold_date,
    coalesce(pr.return_count, 0) as return_count,
    round(100.0 * coalesce(pr.return_count, 0) / nullif(ps.total_units_sold, 0), 2) as return_rate,
    round(ps.total_revenue / nullif(ps.unique_buyers, 0), 2) as revenue_per_buyer

from product_sales ps
left join product_returns pr on ps.product_id = pr.product_id
