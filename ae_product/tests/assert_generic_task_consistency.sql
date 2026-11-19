-- Compare generic editing results to the original model.
-- A passing test returns zero rows.

with original as (

    select
        session_id,
        attempt_number,
        edit_action_count,
        task_status,
        completion_ts
    from {{ ref('int_editing_task_attempts') }}

),

generic as (

    select
        session_id,
        attempt_number,
        activity_action_count,
        task_status,
        completion_ts
    from {{ ref('fct_document_task_attempts') }}
    where task_name = 'document_editing'

)

select
    coalesce(o.session_id, g.session_id) as session_id,
    coalesce(o.attempt_number, g.attempt_number)
        as attempt_number,
    o.edit_action_count,
    g.activity_action_count,
    o.task_status as original_status,
    g.task_status as generic_status

from original o
full outer join generic g
    on o.session_id = g.session_id
    and o.attempt_number = g.attempt_number

where
    o.session_id is null
    or g.session_id is null
    or o.edit_action_count
        is distinct from g.activity_action_count
    or o.task_status
        is distinct from g.task_status
    or o.completion_ts
        is distinct from g.completion_ts
