-- Verify reporting metrics are internally consistent.
-- A passing test returns zero rows.

with metrics as (

    select
        'daily' as model_name,
        cast(metric_date as varchar) as period_label,
        task_name,
        task_attempts,
        completed_tasks,
        failed_tasks,
        abandoned_tasks,
        incomplete_tasks,
        completion_rate_pct,
        failure_rate_pct,
        abandonment_rate_pct,
        avg_completion_seconds
    from {{ ref('agg_document_tasks_daily') }}

    union all

    select
        'by_period' as model_name,
        reporting_period || ':' ||
            cast(period_start as varchar) as period_label,
        task_name,
        task_attempts,
        completed_tasks,
        failed_tasks,
        abandoned_tasks,
        incomplete_tasks,
        completion_rate_pct,
        failure_rate_pct,
        abandonment_rate_pct,
        avg_completion_seconds
    from {{ ref('agg_document_tasks_by_period') }}

)

select *
from metrics

where task_attempts <= 0

   or (
       completed_tasks
       + failed_tasks
       + abandoned_tasks
       + incomplete_tasks
   ) is distinct from task_attempts

   or completion_rate_pct is distinct from round(
       100.0 * completed_tasks
       / nullif(task_attempts, 0), 2
   )

   or failure_rate_pct is distinct from round(
       100.0 * failed_tasks
       / nullif(task_attempts, 0), 2
   )

   or abandonment_rate_pct is distinct from round(
       100.0 * abandoned_tasks
       / nullif(task_attempts, 0), 2
   )

   or (
       completed_tasks = 0
       and avg_completion_seconds is not null
   )

   or (
       completed_tasks > 0
       and (
           avg_completion_seconds is null
           or avg_completion_seconds < 0
       )
   )
