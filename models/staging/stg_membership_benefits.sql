with source as (
    select * from {{ source('kaufly', 'membership_benefits') }}
)

select
    benefit_id,
    membership_id,
    benefit_type,
    used_at,
    date(used_at) as used_date,
    order_id
from source
