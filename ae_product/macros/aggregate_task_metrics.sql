{% macro aggregate_task_metrics(period) %}

{% set valid_periods = [
    'day', 'week', 'month', 'quarter'
] %}

{% if period not in valid_periods %}
    {{ exceptions.raise_compiler_error(
        'Invalid reporting period: ' ~ period
    ) }}
{% endif %}

select
    '{{ period }}' as reporting_period,

    cast(
        date_trunc('{{ period }}', first_activity_ts)
        as date
    ) as period_start,

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
    ) as incomplete_tasks,

    round(
        100.0 * count(*) filter (
            where reporting_status = 'completed'
        ) / nullif(count(*), 0),
        2
    ) as completion_rate_pct,

    round(
        100.0 * count(*) filter (
            where reporting_status = 'failed'
        ) / nullif(count(*), 0),
        2
    ) as failure_rate_pct,

    round(
        100.0 * count(*) filter (
            where reporting_status = 'presumed_abandoned'
        ) / nullif(count(*), 0),
        2
    ) as abandonment_rate_pct,

    round(
        avg(elapsed_to_completion_ms) filter (
            where reporting_status = 'completed'
        ) / 1000.0,
        2
    ) as avg_completion_seconds

from {{ ref('fct_document_task_outcomes') }}

group by 1, 2, 3

{% endmacro %}
