{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('demo_fct_orders') }}
),
breakdown as (
    select
        sales_region_code,
        payment_type,
        count(order_id)     as order_count,
        sum(order_amount)   as total_revenue
    from orders
    group by sales_region_code, payment_type
)
select * from breakdown
order by sales_region_code, payment_type
