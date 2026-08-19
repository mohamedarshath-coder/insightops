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
        discount_pct * revenue_usd / 100 AS discount_usd,
        shipping_fee                                           as shipping_amount,
        currency,
        is_gift,
        product_name,
        category,
        unit_price,
        margin_pct,
        revenue_usd                                            as order_amount
    from order_items
)
select * from final
