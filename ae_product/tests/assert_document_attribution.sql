-- Regression test for known attribution scenarios.
-- A passing test returns zero rows.

with expected as (

    select *
    from (
        values
            ('evt_002', 'DOC100', 'inferred'),
            ('evt_005', 'DOC100', 'inferred'),
            ('evt_008', 'DOC200', 'inferred'),
            ('evt_010', 'DOC200', 'inferred'),
            ('evt_013', null,     'unresolved')
    ) as e(
        event_id,
        expected_document_id,
        expected_method
    )

),

actual as (

    select
        event_id,
        resolved_document_id,
        attribution_method
    from {{ ref('int_attributed_actions') }}

)

select
    e.event_id,
    e.expected_document_id,
    a.resolved_document_id,
    e.expected_method,
    a.attribution_method

from expected e
left join actual a
    on e.event_id = a.event_id

where
    a.event_id is null
    or a.resolved_document_id
        is distinct from e.expected_document_id
    or a.attribution_method
        is distinct from e.expected_method
