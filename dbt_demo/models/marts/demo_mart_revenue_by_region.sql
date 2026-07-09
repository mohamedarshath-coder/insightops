with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
regional as (
    select
        region_code,
        sales_channel,
        payment_type,
        count(order_id)         as total_orders,
        sum(order_amount)       as gross_revenue,
        sum(net_amount)         as net_revenue,
        avg(order_amount)       as avg_order_value,
        sum(is_completed)       as completed_orders
    from fct
    group by region_code, sales_channel, payment_type
)
select * from regional
