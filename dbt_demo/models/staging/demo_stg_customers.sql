with source as (
    select * from {{ source('insightops', 'raw_customers') }}
),
renamed as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        customer_segment                    as customer_tier,
        case when loyalty_tier in ('gold','platinum') then true else false end as is_premium_customer,
        registration_date,
        date_of_birth,
        city,
        state,
        country,
        is_active                           as account_active,
        marketing_opt_in,
        acquisition_channel                 as acq_channel
    from source
)
select * from renamed
