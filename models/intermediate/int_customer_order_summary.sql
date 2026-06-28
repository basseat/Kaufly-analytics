with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

order_agg as (
    select
        customer_id,
        count(*) as lifetime_orders,
        sum(net_amount) as lifetime_revenue,
        avg(net_amount) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(*) filter (where status = 'completed') as completed_orders,
        count(*) filter (where status = 'cancelled') as cancelled_orders
    from orders
    group by customer_id
),

returns_agg as (
    select
        o.customer_id,
        count(*) as lifetime_returns
    from {{ ref('stg_returns') }} r
    inner join orders o on r.order_id = o.order_id
    group by o.customer_id
)

select
    c.customer_id,
    c.country,
    c.registration_date,
    date_trunc('month', c.registration_date)::date as signup_cohort,
    coalesce(oa.lifetime_orders, 0) as lifetime_orders,
    coalesce(oa.lifetime_revenue, 0) as lifetime_revenue,
    coalesce(oa.avg_order_value, 0) as avg_order_value,
    oa.first_order_date,
    oa.last_order_date,
    coalesce(oa.completed_orders, 0) as completed_orders,
    coalesce(oa.cancelled_orders, 0) as cancelled_orders,
    coalesce(ra.lifetime_returns, 0) as lifetime_returns,
    case
        when oa.lifetime_orders is null then 'never_ordered'
        when oa.lifetime_orders = 1 then 'one_time'
        when oa.lifetime_orders between 2 and 4 then 'repeat'
        else 'loyal'
    end as customer_segment,
    oa.last_order_date - oa.first_order_date as customer_lifespan_days

from customers c
left join order_agg oa on c.customer_id = oa.customer_id
left join returns_agg ra on c.customer_id = ra.customer_id
