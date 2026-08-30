with source as (
    select * from {{ source('insightops', 'raw_products') }}
),
renamed as (
    select
        product_id                          as product_key,
        product_name,
        sku,
        category,
        sub_category,
        brand,
        supplier,
        round((unit_price - unit_cost) / nullif(unit_price, 0) * 100, 2) as margin_pct,
        unit_price,
        is_active,
        launch_date
    from source
)
select * from renamed
