with classified_events as (

    select
        event_id,
        event_ts,
        account_id,
        resolved_document_id,
        session_id,

        case
            when {{ task_action_condition(
                'action_name',
                'document_editing',
                'activity'
            ) }} then 'activity'

            when {{ task_action_condition(
                'action_name',
                'document_editing',
                'completion'
            ) }} then 'completion'

            else 'other'
        end as task_event_type

    from {{ ref('int_document_sessions') }}

),

task_events as (

    select *
    from classified_events
    where task_event_type != 'other'

),

numbered_attempts as (

    select
        *,

        1 + coalesce(
            sum(
                case
                    when task_event_type = 'completion'
                    then 1
                    else 0
                end
            ) over (
                partition by
                    account_id,
                    resolved_document_id,
                    session_id
                order by event_ts, event_id
                rows between unbounded preceding
                    and 1 preceding
            ),
            0
        ) as attempt_number

    from task_events

),

task_summary as (

    select
        account_id,
        resolved_document_id,
        session_id,
        attempt_number,

        min(event_ts) filter (
            where task_event_type = 'activity'
        ) as first_edit_ts,

        max(event_ts) filter (
            where task_event_type = 'activity'
        ) as last_edit_ts,

        min(event_ts) filter (
            where task_event_type = 'completion'
        ) as completion_ts,

        count(*) filter (
            where task_event_type = 'activity'
        ) as edit_action_count

    from numbered_attempts

    group by
        account_id,
        resolved_document_id,
        session_id,
        attempt_number

)

select
    session_id || '_EDIT_' ||
        lpad(cast(attempt_number as varchar), 3, '0')
        as task_id,

    account_id,
    resolved_document_id,
    session_id,
    attempt_number,

    first_edit_ts,
    last_edit_ts,
    completion_ts,

    first_edit_ts - interval '1 millisecond'
        as inferred_start_ts,

    last_edit_ts + interval '1 millisecond'
        as inferred_activity_end_ts,

    edit_action_count,

    case
        when completion_ts is not null
        then 'completed'
        else 'incomplete'
    end as task_status,

    case
        when edit_action_count > 1
        then date_diff(
            'millisecond',
            first_edit_ts,
            last_edit_ts
        )
        else null
    end as observed_activity_span_ms,

    case
        when completion_ts is not null
        then date_diff(
            'millisecond',
            first_edit_ts,
            completion_ts
        )
        else null
    end as elapsed_to_completion_ms

from task_summary

where edit_action_count > 0
