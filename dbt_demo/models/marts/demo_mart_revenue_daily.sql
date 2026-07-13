with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
daily as (
    select
        order_ts,
        sales_region_code,
        sales_channel,
        count(order_id)         as total_orders,
        sum(order_amount)       as gross_revenue,
        avg(order_amount)       as avg_order_value,
        sum(discount_usd)    as total_discounts,
        sum(case when status = 'completed' then 1 else 0 end) as completed_orders,
        sum(case when status = 'failed' then 1 else 0 end) as failed_orders
    from fct
    group by order_ts, sales_region_code, sales_channel
)
select * from daily