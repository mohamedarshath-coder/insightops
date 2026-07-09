with orders as (
    select * from {{ ref('demo_stg_orders') }}
),
products as (
    select * from {{ ref('demo_stg_products') }}
),
joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.revenue_usd as gross_revenue,
        o.order_status,
        o.payment_method,
        o.promo_code,
        o.region_code,
        o.sales_channel,
        o.discount_amount,
        o.tax_amount,
        o.shipping_amount,
        o.currency,
        o.is_gift,
        o.estimated_delivery_date,
        o.actual_delivery_date,
        o.return_requested,
        p.product_name,
        p.category,
        p.unit_price,
        p.unit_cost
    from orders o
    left join products p on o.order_id = p.product_id
)
select * from joined