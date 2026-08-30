{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('demo_fct_orders') }}
),
summary as (
    select
        sales_region_code,
        sales_channel,
        count(order_id)                as order_count,
        sum(shipping_amount)       as total_shipping_cost,
        avg(shipping_amount)       as avg_shipping_cost
    from orders
    group by sales_region_code, sales_channel
)
select * from summary
order by sales_region_code, sales_channel
