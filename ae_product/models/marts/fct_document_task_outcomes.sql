with tasks as (

    select *
    from {{ ref('fct_document_task_attempts') }}

),

data_as_of as (

    select
        max(event_ts) as as_of_ts

    from {{ ref('stg_product_actions') }}

),

classified as (

    select
        tasks.*,
        data_as_of.as_of_ts,

        case
            when task_status = 'incomplete'
                and last_activity_ts
                    + interval '10 minutes'
                    < as_of_ts
                then 'presumed_abandoned'

            else task_status

        end as reporting_status

    from tasks
    cross join data_as_of

)

select *
from classified
