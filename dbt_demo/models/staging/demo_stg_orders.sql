with source as (
    select * from {{ source('insightops', 'raw_orders') }}
),
renamed as (
    select
        order_id,
        customer_id,
        cast(order_date as date)             as order_ts,
        total_amount                         as net_sales_amount,
        lower(trim(order_status))            as order_status,
        lower(trim(payment_method))   as payment_method,
        promo_code,
        sales_region                         as sales_region_code,
        order_channel                        as channel_code,
        discount_amount                      as discount_usd,
        shipping_amount,
        currency,
        is_gift,
        estimated_delivery_date,
        actual_delivery_date,
        return_requested
    from source
)
select * from renamed