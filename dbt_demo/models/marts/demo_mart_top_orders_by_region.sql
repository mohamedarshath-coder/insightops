{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('demo_fct_orders') }}
),
ranked as (
    select
        order_id,
        customer_id,
        sales_region_code,
        order_amount,
        row_number() over (
            partition by sales_region_code order by order_amount desc
        )                                                        as rank_in_region
    from orders
    qualify rank_in_region <= 5
)
select * from ranked
order by sales_region_code, rank_in_region
