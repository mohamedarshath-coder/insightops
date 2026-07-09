with customers as (
    select * from {{ ref('demo_fct_customers') }}
),
orders as (
    select * from {{ ref('demo_fct_orders') }}
),
cohorts as (
    select
        c.segment_code,
        c.loyalty_score,
        c.loyalty_class,
        date_trunc('month', cast(c.first_order_date as date))     as cohort_month,
        count(distinct c.customer_id)                as cohort_size,
        sum(o.order_amount)                          as cohort_revenue,
        avg(c.total_orders)                          as avg_orders_per_customer,
        avg(c.lifetime_spend)                        as avg_ltv
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by c.segment_code, c.loyalty_score, c.loyalty_class,
             date_trunc('month', c.first_order_date)
)
select * from cohorts
