with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
daily as (
    select
        region_code,
        sales_channel,
        count(order_id)         as total_orders,
        sum(discount_amount)    as total_discounts,
        sum(is_completed)       as completed_orders,
        sum(is_failed)          as failed_orders
    from fct
    group by order_ts, region_code, sales_channel
)
select * from daily