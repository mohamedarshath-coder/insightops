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
        customer_segment                    as client_segment,
        loyalty_tier,
        registration_date,
        date_of_birth,
        city,
        state,
        country,
        marketing_opt_in,
        acquisition_channel                 as acq_channel
    from source
)
select * from renamed
