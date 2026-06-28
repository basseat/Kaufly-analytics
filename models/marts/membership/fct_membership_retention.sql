with memberships as (
    select
        membership_id,
        customer_id,
        started_at,
        ended_at,
        status,
        plan_name,
        tenure_days,
        date_trunc('month', started_at)::date as start_cohort
    from {{ ref('stg_memberships') }}
),

cohort_summary as (
    select
        start_cohort,
        plan_name,
        count(*) as total_signups,
        count(*) filter (where status = 'active') as active_members,
        count(*) filter (where status = 'cancelled') as cancelled_members,
        round(100.0 * count(*) filter (where status = 'cancelled') / nullif(count(*), 0), 2) as churn_rate,
        round(avg(tenure_days), 0) as avg_tenure_days,
        percentile_cont(0.5) within group (order by tenure_days) as median_tenure_days
    from memberships
    group by start_cohort, plan_name
),

monthly_active as (
    select
        date_trunc('month', d.month_date)::date as report_month,
        m.plan_name,
        count(distinct m.membership_id) as active_members_count
    from memberships m
    cross join generate_series(
        m.started_at,
        coalesce(m.ended_at, current_date),
        interval '1 month'
    ) as d(month_date)
    where m.status = 'active'
       or d.month_date <= coalesce(m.ended_at, current_date)
    group by 1, 2
)

select
    cs.start_cohort,
    cs.plan_name,
    cs.total_signups,
    cs.active_members,
    cs.cancelled_members,
    cs.churn_rate,
    cs.avg_tenure_days,
    cs.median_tenure_days,
    ma.active_members_count as current_month_active,
    round(100.0 * cs.active_members / nullif(cs.total_signups, 0), 2) as retention_rate

from cohort_summary cs
left join monthly_active ma
    on cs.start_cohort = ma.report_month
    and cs.plan_name = ma.plan_name
