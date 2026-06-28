with customers as (
    select * from {{ ref('int_customer_order_summary') }}
),

memberships as (
    select
        customer_id,
        bool_or(status = 'active') as is_active_member
    from {{ ref('stg_memberships') }}
    group by customer_id
)

select
    c.customer_id,
    c.country,
    c.registration_date,
    c.signup_cohort,
    c.lifetime_orders,
    c.lifetime_revenue,
    c.avg_order_value,
    c.first_order_date,
    c.last_order_date,
    c.completed_orders,
    c.cancelled_orders,
    c.lifetime_returns,
    c.customer_segment,
    c.customer_lifespan_days,
    coalesce(m.is_active_member, false) as is_active_member,
    case
        when c.lifetime_orders = 0 then 0
        else round(c.lifetime_revenue / nullif(c.lifetime_orders, 0), 2)
    end as revenue_per_order,
    case
        when c.customer_lifespan_days is null or c.customer_lifespan_days = 0 then c.lifetime_revenue
        else round(c.lifetime_revenue / (c.customer_lifespan_days / 30.0), 2)
    end as monthly_revenue_run_rate

from customers c
left join memberships m on c.customer_id = m.customer_id
where c.lifetime_orders > 0
