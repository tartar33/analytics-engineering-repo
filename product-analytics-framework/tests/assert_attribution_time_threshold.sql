-- Verify that matching document IDs do not override
-- the maximum allowable attribution time gap.
-- A passing test returns zero rows.

with test_case as (

    select *
    from {{ ref('int_attributed_actions') }}
    where event_id = 'evt_031'

)

select
    'evt_031' as event_id,
    'Incorrect time-threshold attribution' as failure_reason

where not exists (

    select 1
    from test_case

    where previous_document_id = 'DOC100'
      and next_document_id = 'DOC100'

      and date_diff(
          'second',
          previous_document_ts,
          event_ts
      ) = 113

      and date_diff(
          'second',
          event_ts,
          next_document_ts
      ) = 60

      and resolved_document_id is null
      and attribution_method = 'unresolved'

)
