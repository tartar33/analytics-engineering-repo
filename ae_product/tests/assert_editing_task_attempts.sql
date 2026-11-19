-- Verify multiple task attempts within one session.
-- A passing test returns zero rows.

with expected as (

    select *
    from (
        values
            (
                'A01_DOC200_S001_EDIT_001',
                1,
                'completed'
            ),
            (
                'A01_DOC200_S001_EDIT_002',
                1,
                'incomplete'
            )
    ) as e(
        task_id,
        expected_action_count,
        expected_status
    )

),

actual as (

    select
        task_id,
        edit_action_count,
        task_status,
        completion_ts
    from {{ ref('int_editing_task_attempts') }}
    where resolved_document_id = 'DOC200'

)

select
    coalesce(e.task_id, a.task_id) as task_id,
    e.expected_action_count,
    a.edit_action_count,
    e.expected_status,
    a.task_status

from expected e
full outer join actual a
    on e.task_id = a.task_id

where
    e.task_id is null
    or a.task_id is null
    or a.edit_action_count
        is distinct from e.expected_action_count
    or a.task_status
        is distinct from e.expected_status
    or (
        e.expected_status = 'completed'
        and a.completion_ts is null
    )
    or (
        e.expected_status = 'incomplete'
        and a.completion_ts is not null
    )
