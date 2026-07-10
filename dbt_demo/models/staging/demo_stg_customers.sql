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
        customer_segment                  as client_segment,
        loyalty_tier                      as loyalty_segment,
        registration_date,
        date_of_birth,
        city,
        state,
        country,
        is_active                         as account_active,
        marketing_opt_in,
        acquisition_channel               as acq_source
    from source
)
select * from renamed