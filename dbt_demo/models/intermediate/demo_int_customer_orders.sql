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
        c.customer_tier                                      as client_segment,
        case 
            when c.loyalty_tier = 'gold' then 'tier_1'
            else 'tier_2'
        end as loyalty_score_v2,
        c.acq_channel,
        count(o.order_id) as total_orders,
        count(case when o.order_status = 'completed' then 1 end) as completed_orders,
        count(case when o.order_status = 'failed' then 1 end) as failed_orders,
        sum(o.gross_revenue) as lifetime_spend,
        avg(o.gross_revenue) as avg_order_value,
        min(o.order_ts) as first_order_date,
        max(o.order_ts) as last_order_date,
        max(case when c.customer_id is not null then true else false end) as account_active
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.customer_tier,
        c.loyalty_tier,
        c.acq_channel
)
select * from aggregated
