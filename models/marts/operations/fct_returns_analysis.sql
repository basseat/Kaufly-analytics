with returns as (
    select * from {{ ref('stg_returns') }}
),

order_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

return_details as (
    select
        r.return_id,
        r.order_id,
        r.order_item_id,
        r.initiated_at,
        r.reason,
        r.refund_amount,
        r.processing_days,
        oi.category,
        oi.subcategory,
        oi.line_total as returned_value,
        date_trunc('week', r.initiated_at)::date as return_week,
        date_trunc('month', r.initiated_at)::date as return_month
    from returns r
    inner join order_items oi on r.order_item_id = oi.order_item_id
),

completed_orders as (
    select
        date_trunc('month', order_date)::date as order_month,
        category,
        count(distinct order_id) as total_orders
    from {{ ref('int_order_items_enriched') }}
    where order_status = 'completed'
    group by 1, 2
)

select
    rd.return_month,
    rd.category,
    rd.reason,
    count(*) as return_count,
    sum(rd.refund_amount) as total_refund_amount,
    avg(rd.refund_amount) as avg_refund_amount,
    avg(rd.processing_days) as avg_processing_days,
    round(
        100.0 * count(*) / nullif(co.total_orders, 0), 2
    ) as return_rate

from return_details rd
left join completed_orders co
    on rd.return_month = co.order_month
    and rd.category = co.category
group by rd.return_month, rd.category, rd.reason, co.total_orders
