with actions as (

    select *
    from {{ ref('int_attributed_actions') }}
    where resolved_document_id is not null

),

ordered_actions as (

    select
        *,

        lag(event_ts) over (
            partition by account_id, resolved_document_id
            order by event_ts, event_id
        ) as previous_event_ts

    from actions

),

session_boundaries as (

    select
        *,

        case
            when previous_event_ts is null then 1
            when event_ts > previous_event_ts
                + interval '10 minutes' then 1
            else 0
        end as is_new_session

    from ordered_actions

),

session_numbers as (

    select
        *,

        sum(is_new_session) over (
            partition by account_id, resolved_document_id
            order by event_ts, event_id
            rows between unbounded preceding and current row
        ) as session_number

    from session_boundaries

)

select
    *,
    account_id || '_' ||
    resolved_document_id || '_S' ||
    lpad(cast(session_number as varchar), 3, '0')
        as session_id

from session_numbers
