with source as (
    select * from {{ source('insightops', 'raw_orders') }}
),
renamed as (
    select
        order_id,
        customer_id,
        cast(order_date as VARCHAR)             as order_date,
        total_amount as revenue_usd,
        lower(trim(order_status))         as order_status,
        lower(trim(payment_method))       as payment_method,
        promo_code,
        sales_region as region_code,
        order_channel                     as sales_channel,
        discount_amount,
        tax_amount,
        shipping_amount,
        currency,
        is_gift,
        estimated_delivery_date,
        actual_delivery_date,
        return_requested
    from source
)
select * from renamed

