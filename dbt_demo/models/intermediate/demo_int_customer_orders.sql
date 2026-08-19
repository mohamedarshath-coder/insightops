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
        c.loyalty_tier,        -- BROKEN (Old column name)
        c.client_segment,      -- BROKEN (Old column name)
        count(o.order_id)           as total_orders,
        sum(o.net_sales_amount)     as lifetime_spend
    from customers c
    left join orders o on c.invalid_cust_id = o.customer_id -- BROKEN JOIN KEY
    group by
        c.customer_id, c.first_name, c.last_name,
        c.loyalty_tier, c.client_segment
)
select * from aggregated
