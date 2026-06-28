with source as (
    select * from {{ source('kaufly', 'events') }}
)

select
    event_id,
    customer_id,
    event_name,
    event_timestamp,
    date(event_timestamp) as event_date,
    properties
from source
