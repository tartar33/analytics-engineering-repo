-- Reconcile daily metrics with underlying task records.
-- A passing test returns zero rows.

with expected as (

    select
        cast(first_activity_ts as date) as metric_date,
        task_name,

        count(*) as task_attempts,

        count(*) filter (
            where reporting_status = 'completed'
        ) as completed_tasks,

        count(*) filter (
            where reporting_status = 'failed'
        ) as failed_tasks,

        count(*) filter (
            where reporting_status = 'presumed_abandoned'
        ) as abandoned_tasks,

        count(*) filter (
            where reporting_status = 'incomplete'
        ) as incomplete_tasks

    from {{ ref('fct_document_task_outcomes') }}

    group by 1, 2

),

actual as (

    select *
    from {{ ref('agg_document_tasks_daily') }}

)

select
    coalesce(e.metric_date, a.metric_date) as metric_date,
    coalesce(e.task_name, a.task_name) as task_name,

    e.task_attempts as expected_attempts,
    a.task_attempts as actual_attempts

from expected e

full outer join actual a
    on e.metric_date = a.metric_date
    and e.task_name = a.task_name

where
    e.metric_date is null
    or a.metric_date is null

    or e.task_attempts
        is distinct from a.task_attempts

    or e.completed_tasks
        is distinct from a.completed_tasks

    or e.failed_tasks
        is distinct from a.failed_tasks

    or e.abandoned_tasks
        is distinct from a.abandoned_tasks

    or e.incomplete_tasks
        is distinct from a.incomplete_tasks

    or a.task_attempts is distinct from (
        a.completed_tasks
        + a.failed_tasks
        + a.abandoned_tasks
        + a.incomplete_tasks
    )
