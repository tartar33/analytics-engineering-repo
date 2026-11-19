{% macro build_task_attempts(task_names) %}

with task_events as (

    {% for task in task_names %}

    select
        event_id,
        event_ts,
        account_id,
        resolved_document_id,
        session_id,
        '{{ task }}' as task_name,

        case
            when {{ task_action_condition(
                'action_name', task, 'activity'
            ) }} then 'activity'

            when {{ task_action_condition(
                'action_name', task, 'completion'
            ) }} then 'completion'

            when {{ task_action_condition(
                'action_name', task, 'failure'
            ) }} then 'failure'

        end as task_event_type

    from {{ ref('int_document_sessions') }}

    where
        {{ task_action_condition(
            'action_name', task, 'activity'
        ) }}
        or
        {{ task_action_condition(
            'action_name', task, 'completion'
        ) }}
        or
        {{ task_action_condition(
            'action_name', task, 'failure'
        ) }}

    {% if not loop.last %}
        union all
    {% endif %}

    {% endfor %}

),

numbered_attempts as (

    select
        *,

        1 + coalesce(
            sum(
                case
                    when task_event_type in (
                        'completion', 'failure'
                    ) then 1
                    else 0
                end
            ) over (
                partition by
                    account_id,
                    resolved_document_id,
                    session_id,
                    task_name
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
        task_name,
        attempt_number,

        min(event_ts) filter (
            where task_event_type = 'activity'
        ) as first_activity_ts,

        max(event_ts) filter (
            where task_event_type = 'activity'
        ) as last_activity_ts,

        min(event_ts) filter (
            where task_event_type = 'completion'
        ) as completion_ts,

        min(event_ts) filter (
            where task_event_type = 'failure'
        ) as failure_ts,

        count(*) filter (
            where task_event_type = 'activity'
        ) as activity_action_count

    from numbered_attempts

    group by
        account_id,
        resolved_document_id,
        session_id,
        task_name,
        attempt_number

)

select
    session_id || '_' ||
        upper(task_name) || '_' ||
        lpad(cast(attempt_number as varchar), 3, '0')
        as task_id,

    account_id,
    resolved_document_id,
    session_id,
    task_name,
    attempt_number,

    first_activity_ts,
    last_activity_ts,
    completion_ts,
    failure_ts,
    activity_action_count,

    case
        when failure_ts is not null
            then 'failed'
        when completion_ts is not null
            then 'completed'
        else 'incomplete'
    end as task_status,

    case
        when activity_action_count > 1
        then date_diff(
            'millisecond',
            first_activity_ts,
            last_activity_ts
        )
        else null
    end as observed_activity_span_ms,

    case
        when completion_ts is not null
        then date_diff(
            'millisecond',
            first_activity_ts,
            completion_ts
        )
        else null
    end as elapsed_to_completion_ms

from task_summary

where activity_action_count > 0

{% endmacro %}
