with actions as (

    select *
    from {{ ref('int_action_context') }}

),

attributed as (

    select
        *,

        case
            when document_id is not null
                then document_id

            when previous_document_id = next_document_id
                and event_ts - previous_document_ts
                    <= interval '60 seconds'
                and next_document_ts - event_ts
                    <= interval '60 seconds'
                then previous_document_id

            else null
        end as resolved_document_id,

        case
            when document_id is not null
                then 'direct'

            when previous_document_id = next_document_id
                and event_ts - previous_document_ts
                    <= interval '60 seconds'
                and next_document_ts - event_ts
                    <= interval '60 seconds'
                then 'inferred'

            else 'unresolved'
        end as attribution_method

    from actions

)

select *
from attributed
