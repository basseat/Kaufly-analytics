with source as (
    select * from {{ source('kaufly', 'customers') }}
)

select
    customer_id,
    registered_at,
    country,
    city,
    acquisition_channel,
    date(registered_at) as registration_date
from source
