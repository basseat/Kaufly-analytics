with sessions as (
    select * from {{ ref('int_session_funnel') }}
),

funnel as (
    select
        s.session_date,
        count(distinct s.session_id) as total_sessions,
        count(distinct s.session_id) filter (where s.reached_product_view) as product_view_sessions,
        count(distinct s.session_id) filter (where s.reached_add_to_cart) as add_to_cart_sessions,
        count(distinct s.session_id) filter (where s.reached_checkout_start) as checkout_start_sessions,
        count(distinct s.session_id) filter (where s.reached_purchase) as purchase_sessions,
        avg(s.session_duration_minutes) as avg_session_duration_minutes
    from sessions s
    group by s.session_date
)

select
    session_date,
    total_sessions,
    product_view_sessions,
    add_to_cart_sessions,
    checkout_start_sessions,
    purchase_sessions,
    avg_session_duration_minutes,
    round(100.0 * product_view_sessions / nullif(total_sessions, 0), 2) as view_rate,
    round(100.0 * add_to_cart_sessions / nullif(product_view_sessions, 0), 2) as view_to_cart_rate,
    round(100.0 * checkout_start_sessions / nullif(add_to_cart_sessions, 0), 2) as cart_to_checkout_rate,
    round(100.0 * purchase_sessions / nullif(checkout_start_sessions, 0), 2) as checkout_to_purchase_rate,
    round(100.0 * purchase_sessions / nullif(total_sessions, 0), 2) as overall_conversion_rate

from funnel
