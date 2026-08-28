with orders as (
    select * from {{ ref('demo_stg_orders') }}
),
joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_ts,
        o.gross_revenue as revenue_usd,
        o.order_status,
        o.payment_method,
        o.promo_code,
        o.sales_region_code,
        o.sales_channel,
        o.discount_pct,
        o.shipping_fee,
        o.currency,
        o.is_gift,
        o.estimated_delivery_date,
        o.actual_delivery_date,
        o.return_requested
    from orders o
)
select * from joined
