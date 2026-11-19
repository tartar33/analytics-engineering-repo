with editing_actions as (

    select
        account_id,
        resolved_document_id,
        session_id,
        event_ts

    from {{ ref('int_document_sessions') }}

    where action_name = 'field_added'

),

task_boundaries as (

    select
        account_id,
        resolved_document_id,
        session_id,

        min(event_ts) as first_action_ts,
        max(event_ts) as last_action_ts,
        count(*) as action_count

    from editing_actions

    group by
        account_id,
        resolved_document_id,
        session_id

)

select
    session_id || '_EDIT' as task_id,
    account_id,
    resolved_document_id,
    session_id,
    'document_editing' as task_name,

    first_action_ts - interval '1 millisecond'
        as inferred_start_ts,

    last_action_ts + interval '1 millisecond'
        as inferred_end_ts,

    action_count,

    case
        when action_count > 1
        then date_diff(
            'millisecond',
            first_action_ts,
            last_action_ts
        )
        else null
    end as observed_activity_span_ms

from task_boundaries
