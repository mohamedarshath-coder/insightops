{{ config(materialized='table') }}

with order_items as (
    select * from {{ ref('demo_int_order_items') }}
),
final as (
    select
        order_id,
        customer_id,
        order_date,
        order_status                                           as status,
        payment_method                                         as payment_type,
        region_code,
        sales_channel,
        discount_amount,
        tax_amount,
        shipping_amount,
        currency,
        is_gift,
        product_name,
        category,
        gross_revenue                                          as order_amount,
        gross_revenue - discount_amount                        as net_amount,
        case when order_status = 'completed' then 1 else 0 end as is_completed,
        case when order_status = 'failed'    then 1 else 0 end as is_failed
    from order_items
)
select * from final
