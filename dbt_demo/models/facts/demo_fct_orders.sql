{{ config(materialized='table') }}

with order_items as (
    select * from {{ ref('demo_int_order_items') }}
),
final as (
    select
        order_id,
        customer_id,
        order_ts,
        order_status                                           as status,
        payment_method                                         as payment_type,
        sales_region_code,
        sales_channel,
        discount_usd,
        shipping_amount,
        currency,
        is_gift,
        product_name,
        category,
        unit_price,
        unit_cost,
        revenue_usd                                            as order_amount,
        revenue_usd - discount_usd                             as net_amount
    from order_items
)
select * from final