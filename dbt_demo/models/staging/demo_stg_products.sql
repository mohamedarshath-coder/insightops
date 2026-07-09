with source as (
    select * from {{ source('insightops', 'raw_products') }}
),
renamed as (
    select
        product_id                        as item_id,
        product_name,
        sku,
        category,
        sub_category,
        brand,
        supplier,
        unit_cost,
        unit_price,
        is_active,
        launch_date
    from source
)
select * from renamed
