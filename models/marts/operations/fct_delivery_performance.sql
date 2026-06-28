with orders as (
    select * from {{ ref('int_orders_enriched') }}
)

select
    order_week,
    country,
    carrier,
    is_member_order,
    count(*) as total_deliveries,
    count(*) filter (where is_on_time) as on_time_deliveries,
    count(*) filter (where not is_on_time) as late_deliveries,
    round(100.0 * count(*) filter (where is_on_time) / nullif(count(*), 0), 2) as on_time_rate,
    round(avg(transit_days), 1) as avg_transit_days,
    round(avg(delay_days), 1) as avg_delay_days,
    percentile_cont(0.5) within group (order by transit_days) as median_transit_days,
    percentile_cont(0.95) within group (order by transit_days) as p95_transit_days

from orders
where carrier is not null
group by order_week, country, carrier, is_member_order
