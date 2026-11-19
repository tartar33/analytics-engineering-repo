with source_data as (

    select *
    from {{ ref('product_actions') }}

),

standardized as (

    select
        event_id,
        cast(event_ts as timestamp) as event_ts,
        source as event_source,
        account_id,
        device_id,
        nullif(trim(document_id), '') as document_id,
        action_name

    from source_data

)

select *
from standardized
