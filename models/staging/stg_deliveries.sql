with source as (
    select * from {{ source('kaufly', 'deliveries') }}
)

select
    delivery_id,
    order_id,
    carrier,
    warehouse_city,
    shipped_at,
    estimated_delivery_at,
    delivered_at,
    delivery_status,
    delivered_at - shipped_at as transit_days,
    delivered_at - estimated_delivery_at as delay_days,
    case
        when delivered_at <= estimated_delivery_at then true
        else false
    end as is_on_time
from source
