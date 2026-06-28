with customer_summary as (
    select * from {{ ref('int_customer_order_summary') }}
),

memberships as (
    select
        customer_id,
        bool_or(status = 'active') as is_active_member,
        min(started_at) as first_membership_date,
        max(ended_at) as last_membership_end
    from {{ ref('stg_memberships') }}
    group by customer_id
),

benefit_usage as (
    select
        m.customer_id,
        count(*) as total_benefits_used,
        count(*) filter (where mb.benefit_type = 'free_delivery') as free_delivery_used,
        count(*) filter (where mb.benefit_type = 'discount_10pct') as discount_used
    from {{ ref('stg_membership_benefits') }} mb
    inner join {{ ref('stg_memberships') }} m on mb.membership_id = m.membership_id
    group by m.customer_id
),

member_orders as (
    select
        customer_id,
        count(*) filter (where is_member_order) as orders_as_member,
        count(*) filter (where not is_member_order) as orders_as_non_member,
        avg(net_amount) filter (where is_member_order) as avg_order_value_as_member,
        avg(net_amount) filter (where not is_member_order) as avg_order_value_as_non_member
    from {{ ref('int_orders_enriched') }}
    group by customer_id
)

select
    cs.customer_id,
    cs.country,
    cs.signup_cohort,
    cs.lifetime_orders,
    cs.lifetime_revenue,
    cs.customer_segment,
    coalesce(m.is_active_member, false) as is_active_member,
    m.first_membership_date,
    mo.orders_as_member,
    mo.orders_as_non_member,
    round(mo.avg_order_value_as_member, 2) as avg_order_value_as_member,
    round(mo.avg_order_value_as_non_member, 2) as avg_order_value_as_non_member,
    coalesce(bu.total_benefits_used, 0) as total_benefits_used,
    coalesce(bu.free_delivery_used, 0) as free_delivery_used,
    coalesce(bu.discount_used, 0) as discount_used,
    case
        when mo.avg_order_value_as_non_member > 0 then
            round(100.0 * (mo.avg_order_value_as_member - mo.avg_order_value_as_non_member)
                / mo.avg_order_value_as_non_member, 2)
        else null
    end as member_aov_uplift_pct

from customer_summary cs
left join memberships m on cs.customer_id = m.customer_id
left join benefit_usage bu on cs.customer_id = bu.customer_id
left join member_orders mo on cs.customer_id = mo.customer_id
where cs.lifetime_orders > 0
