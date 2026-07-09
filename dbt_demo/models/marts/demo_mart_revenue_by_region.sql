with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
regional as (
    select
        region_code,
        sales_channel,
        payment_type,
        count(order_id)         as total_orders,
        sum(is_completed)       as completed_orders
    from fct
    group by region_code, sales_channel, payment_type
)
select * from regional
