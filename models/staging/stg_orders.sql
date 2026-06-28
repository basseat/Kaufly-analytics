with source as (
    select * from {{ source('kaufly', 'orders') }}
)

select
    order_id,
    customer_id,
    ordered_at,
    date(ordered_at) as order_date,
    status,
    total_amount,
    discount_amount,
    total_amount - discount_amount as net_amount,
    payment_method,
    shipping_method,
    case
        when shipping_method = 'standard_free' then true
        else false
    end as is_free_shipping
from source
