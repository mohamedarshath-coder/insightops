with fct as (
    select * from {{ ref('demo_fct_orders') }}
),
regional as (
    select
        sales_region_code,
        sales_channel,
        payment_type,
        count(order_id)         as total_orders,
        sum(case when status = 'completed' then 1 else 0 end) as is_completed
    from fct
    group by sales_region_code, sales_channel, payment_type
)
select * from regional
