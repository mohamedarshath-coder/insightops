with source as (
    select * from {{ source('insightops', 'raw_customers') }}
),
customers_with_orders as (
    select distinct customer_id from {{ ref('demo_int_customer_orders') }}
),
renamed as (
    select
        customer_id,
        first_name,
        last_name,
        email as contact_email,
        phone,
        customer_segment                    as customer_tier,
        loyalty_tier,
        registration_date,
        date_of_birth,
        city,
        state,
        country,
        is_active                           as account_active,
        marketing_opt_in,
        acquisition_channel                 as channel_source
    from source
    where customer_id in (select customer_id from customers_with_orders)
)
select * from renamed
