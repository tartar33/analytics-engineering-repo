{{ config(materialized='table') }}

{% set periods = [
    'day',
    'week',
    'month',
    'quarter'
] %}

{% for period in periods %}

    {{ aggregate_task_metrics(period) }}

    {% if not loop.last %}
        union all
    {% endif %}

{% endfor %}
