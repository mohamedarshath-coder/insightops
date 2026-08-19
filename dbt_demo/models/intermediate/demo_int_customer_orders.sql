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
        c.email,
        c.loyalty_score_v2 as loyalty_tier, -- Maps new score to loyalty_tier for downstream safety
        c.acq_channel,
        count(o.order_id) as total_orders,
        sum(o.net_sales_amount) as lifetime_spend,
        avg(o.net_sales_amount) as avg_order_value
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.loyalty_score_v2,
        c.acq_channel
)
select * from aggregated
