-- Verify expected session assignments.
-- A passing test returns zero rows.

with expected as (

    select *
    from (
        values
            ('evt_001', 'A01_DOC100_S001', 1),
            ('evt_002', 'A01_DOC100_S001', 0),
            ('evt_006', 'A01_DOC100_S001', 0),
            ('evt_015', 'A01_DOC100_S002', 1),
            ('evt_016', 'A01_DOC100_S002', 0),
            ('evt_017', 'A01_DOC100_S002', 0)
    ) as e(
        event_id,
        expected_session_id,
        expected_new_session
    )

),

actual as (

    select
        event_id,
        session_id,
        is_new_session
    from {{ ref('int_document_sessions') }}

)

select
    e.event_id,
    e.expected_session_id,
    a.session_id,
    e.expected_new_session,
    a.is_new_session
from expected e
left join actual a
    on e.event_id = a.event_id
where
    a.event_id is null
    or a.session_id is distinct from e.expected_session_id
    or a.is_new_session is distinct from e.expected_new_session

union all

-- Events with unresolved document IDs
-- should not appear in document sessions.

select
    event_id,
    null,
    session_id,
    null,
    is_new_session
from actual
where event_id = 'evt_013'
