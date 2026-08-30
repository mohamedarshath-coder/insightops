{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('demo_fct_orders') }}
),
velocity as (
    select
        customer_id,
        sales_region_code,
        count(order_id)                                  as order_count,
        {{ compute_velocity_score('order_count') }}       as velocity_score
    from orders
    group by customer_id, sales_region_code
)
select * from velocity
