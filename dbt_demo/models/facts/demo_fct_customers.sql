{{ config(materialized='table') }}

with customer_orders as (
    select * from {{ ref('demo_int_customer_orders') }}
),
final as (
    select
        customer_id,
        first_name,
        last_name,
        loyalty_segment                  as loyalty_score,
        client_segment,
        account_active,
        acq_channel,
        total_orders,
        lifetime_spend,
        first_order_date,
        last_order_date,
        completed_orders,
        failed_orders,
        case
            when total_orders >= 10 then 'platinum'
            when total_orders >= 5  then 'gold'
            when total_orders >= 2  then 'silver'
            else                         'bronze'
        end as loyalty_class
    from customer_orders
)
select * from final