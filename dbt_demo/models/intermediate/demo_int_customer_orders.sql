{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('demo_stg_customers') }}
),
orders as (
    select * from {{ ref('demo_stg_orders') }}
),
aggregated as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.loyalty_segment,
        c.customer_segment,
        c.is_active,
        c.acquisition_channel,
        count(o.order_id)                                        as total_orders,
        sum(o.total_amount)                                      as lifetime_spend,
        avg(o.total_amount)                                      as avg_order_value,
        min(o.order_date)                                        as first_order_date,
        max(o.order_date)                                        as last_order_date,
        count(case when o.order_status = 'completed' then 1 end) as completed_orders,
        count(case when o.order_status = 'failed'    then 1 end) as failed_orders,
        MIN(CAST(o.order_status AS INTEGER))                     as status_num
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by
        c.customer_id, c.first_name, c.last_name,
        c.loyalty_segment, c.customer_segment, c.is_active, c.acquisition_channel
)
select * from aggregated
