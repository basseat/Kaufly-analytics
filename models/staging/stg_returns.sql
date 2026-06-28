with source as (
    select * from {{ source('kaufly', 'returns') }}
)

select
    return_id,
    order_id,
    order_item_id,
    initiated_at,
    received_at,
    reason,
    refund_amount,
    received_at - initiated_at as processing_days
from source
