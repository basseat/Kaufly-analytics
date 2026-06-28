with source as (
    select * from {{ source('kaufly', 'memberships') }}
)

select
    membership_id,
    customer_id,
    plan_name,
    started_at,
    ended_at,
    monthly_fee,
    status,
    case
        when ended_at is not null then ended_at - started_at
        else current_date - started_at
    end as tenure_days
from source
