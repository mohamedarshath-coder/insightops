{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('demo_fct_customers') }}
),
orders as (
    select * from {{ ref('demo_fct_orders') }}
),
cohort_base as (
    select
        customer_id,
        date_trunc('month', customers.first_order_date)                     as cohort_month,
        orders.order_ts,
        row_number() over (
            partition by customers.customer_id order by orders.order_ts
        )                                                                    as order_sequence
    from customers
    join orders on customers.customer_id = orders.customer_id
),
retention as (
    select
        cohort_month,
        datediff('month', cohort_month, date_trunc('month', order_ts))       as months_since_cohort,
        count(distinct customer_id)                                          as active_customers
    from cohort_base
    group by cohort_month, months_since_cohort
)
select * from retention
order by cohort_month, months_since_cohort
