{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('demo_fct_customers') }}
),
engagement as (
    select
        customer_id,
        first_name || ' ' || last_name as customer_name,
        loyalty_score,
        client_segment,
        total_orders,
        lifetime_spend,
        case
            when total_orders >= 10 then 'highly_engaged'
            when total_orders >= 3  then 'engaged'
            else                         'at_risk'
        end as engagement_tier
    from customers
)
select * from engagement
