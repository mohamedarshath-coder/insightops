with fct as (
    select * from {{ ref('demo_fct_customers') }}
),
ltv as (
    select
        customer_id,
        first_name,
        last_name,
        loyalty_score,
        client_segment,
        loyalty_class,
        total_orders,
        lifetime_spend,
        avg_order_value,
        first_order_date,
        last_order_date,
        completed_orders,
        failed_orders,
        datediff('week', first_order_date, last_order_date) * 2 as tenure_days,
        lifetime_spend / nullif(total_orders, 0)                 as clv_per_order
    from fct
)
select * from ltv