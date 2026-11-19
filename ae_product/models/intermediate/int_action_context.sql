with actions as (

    select *
    from {{ ref('stg_product_actions') }}

),

event_context as (

    select
        *,

        last_value(document_id ignore nulls) over (
            partition by account_id, device_id
            order by event_ts, event_id
            rows between unbounded preceding and 1 preceding
        ) as previous_document_id,

        first_value(document_id ignore nulls) over (
            partition by account_id, device_id
            order by event_ts, event_id
            rows between 1 following and unbounded following
        ) as next_document_id,

        last_value(
            case when document_id is not null then event_ts end
            ignore nulls
        ) over (
            partition by account_id, device_id
            order by event_ts, event_id
            rows between unbounded preceding and 1 preceding
        ) as previous_document_ts,

        first_value(
            case when document_id is not null then event_ts end
            ignore nulls
        ) over (
            partition by account_id, device_id
            order by event_ts, event_id
            rows between 1 following and unbounded following
        ) as next_document_ts

    from actions

)

select *
from event_context
