with events as (
    select
        event_id,
        customer_id,
        event_name,
        event_timestamp,
        event_date,
        lag(event_timestamp) over (
            partition by customer_id order by event_timestamp
        ) as prev_event_timestamp
    from {{ ref('stg_events') }}
    where event_name in (
        'page_view', 'product_viewed', 'added_to_cart',
        'checkout_started', 'order_confirmed', 'payment_submitted'
    )
),

sessioned as (
    select
        *,
        sum(
            case
                when prev_event_timestamp is null then 1
                when extract(epoch from (event_timestamp - prev_event_timestamp)) > 1800 then 1
                else 0
            end
        ) over (partition by customer_id order by event_timestamp) as session_seq
    from events
),

events_with_session as (
    select
        *,
        customer_id || '-' || session_seq as session_id
    from sessioned
),

session_events as (
    select
        session_id,
        customer_id,
        min(event_timestamp) as session_start,
        max(event_timestamp) as session_end,
        count(*) as total_events,
        count(*) filter (where event_name = 'page_view') as page_views,
        count(*) filter (where event_name = 'product_viewed') as product_views,
        count(*) filter (where event_name = 'added_to_cart') as add_to_carts,
        count(*) filter (where event_name = 'checkout_started') as checkout_starts,
        count(*) filter (where event_name in ('order_confirmed', 'payment_submitted')) as purchases,
        bool_or(event_name = 'page_view') as reached_page_view,
        bool_or(event_name = 'product_viewed') as reached_product_view,
        bool_or(event_name = 'added_to_cart') as reached_add_to_cart,
        bool_or(event_name = 'checkout_started') as reached_checkout_start,
        bool_or(event_name in ('order_confirmed', 'payment_submitted')) as reached_purchase
    from events_with_session
    group by session_id, customer_id
)

select
    session_id,
    customer_id,
    session_start,
    session_end,
    extract(epoch from (session_end - session_start)) / 60.0 as session_duration_minutes,
    total_events,
    page_views,
    product_views,
    add_to_carts,
    checkout_starts,
    purchases,
    reached_page_view,
    reached_product_view,
    reached_add_to_cart,
    reached_checkout_start,
    reached_purchase,
    case
        when reached_purchase then 'purchase'
        when reached_checkout_start then 'checkout_start'
        when reached_add_to_cart then 'add_to_cart'
        when reached_product_view then 'product_view'
        when reached_page_view then 'page_view'
        else 'bounce'
    end as furthest_stage,
    date_trunc('day', session_start)::date as session_date

from session_events
