with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
daily as (
    select
        order_date,
        region_code,
        sales_channel,
        count(order_id)         as total_orders,
        sum(order_amount)       as gross_revenue,
        sum(net_amount)         as net_revenue,
        sum(discount_amount)    as total_discounts,
        avg(order_amount)       as avg_order_value,
        sum(is_completed)       as completed_orders,
        sum(is_failed)          as failed_orders
    from fct
    group by order_date, region_code, sales_channel
)
select * from daily
