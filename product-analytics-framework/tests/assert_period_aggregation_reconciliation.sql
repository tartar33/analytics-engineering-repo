-- Verify that multi-period aggregates reconcile
-- with the daily aggregate.
-- A passing test returns zero rows.

with expected as (

    select
        p.reporting_period,

        cast(
            date_trunc(
                p.reporting_period,
                d.metric_date
            ) as date
        ) as period_start,

        d.task_name,

        sum(d.task_attempts) as task_attempts,
        sum(d.completed_tasks) as completed_tasks,
        sum(d.failed_tasks) as failed_tasks,
        sum(d.abandoned_tasks) as abandoned_tasks,
        sum(d.incomplete_tasks) as incomplete_tasks

    from {{ ref('agg_document_tasks_daily') }} d

    cross join (
        values
            ('day'),
            ('week'),
            ('month'),
            ('quarter')
    ) as p(reporting_period)

    group by 1, 2, 3

),

actual as (

    select *
    from {{ ref('agg_document_tasks_by_period') }}

)

select
    coalesce(e.reporting_period, a.reporting_period)
        as reporting_period,

    coalesce(e.period_start, a.period_start)
        as period_start,

    coalesce(e.task_name, a.task_name)
        as task_name

from expected e

full outer join actual a
    on e.reporting_period = a.reporting_period
    and e.period_start = a.period_start
    and e.task_name = a.task_name

where
    e.reporting_period is null
    or a.reporting_period is null

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
