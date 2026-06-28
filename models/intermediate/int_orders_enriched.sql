with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

memberships as (
    select * from {{ ref('stg_memberships') }}
),

deliveries as (
    select * from {{ ref('stg_deliveries') }}
),

order_items_agg as (
    select
        order_id,
        count(*) as item_count,
        sum(quantity) as total_units
    from {{ ref('stg_order_items') }}
    group by order_id
),

active_membership_at_order as (
    select
        m.customer_id,
        o.order_id,
        m.membership_id,
        m.plan_name as membership_plan
    from memberships m
    inner join orders o
        on m.customer_id = o.customer_id
        and o.order_date between m.started_at and coalesce(m.ended_at, current_date)
)

select
    o.order_id,
    o.customer_id,
    c.country,
    o.order_date,
    o.status as order_status,
    o.total_amount,
    o.net_amount,
    o.is_free_shipping,
    oi.item_count,
    oi.total_units,
    d.carrier,
    d.transit_days,
    d.delay_days,
    d.is_on_time,
    am.membership_id is not null as is_member_order,
    am.membership_plan,
    extract(year from o.order_date) as order_year,
    extract(month from o.order_date) as order_month,
    date_trunc('week', o.order_date)::date as order_week

from orders o
left join customers c on o.customer_id = c.customer_id
left join order_items_agg oi on o.order_id = oi.order_id
left join deliveries d on o.order_id = d.order_id
left join active_membership_at_order am on o.order_id = am.order_id
