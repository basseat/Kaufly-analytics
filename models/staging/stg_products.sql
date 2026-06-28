with source as (
    select * from {{ source('kaufly', 'products') }}
)

select
    product_id,
    category,
    subcategory,
    brand,
    price,
    listed_at
from source
