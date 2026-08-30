{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('demo_fct_orders') }}
),
flagged as (
    select
        order_id,
        customer_id,
        payment_type,
        order_amount,
        case
            when (order_amount > 500 and payment_type = 'credit_card') then 'high_value_review'
            when is_gift and order_amount > 200 then 'gift_review'
            else 'standard'
        end as risk_flag
    from orders
    where status = 'completed'
)
select * from flagged
