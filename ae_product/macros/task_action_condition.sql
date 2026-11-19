{% macro task_action_condition(
    column_name,
    task_name,
    action_group
) %}

    {% set task_definitions = {
        'document_editing': {
            'activity': ['field_added'],
            'completion': [
                'document_saved',
                'document_submitted'
            ]
        }
    } %}

    {% if task_name not in task_definitions %}
        {{ exceptions.raise_compiler_error(
            'Unknown task: ' ~ task_name
        ) }}
    {% endif %}

    {% set groups = task_definitions[task_name] %}

    {% if action_group not in groups %}
        {{ exceptions.raise_compiler_error(
            'Unknown action group: ' ~ action_group
        ) }}
    {% endif %}

    (
        {{ column_name }} in (
            {% for action in groups[action_group] %}
                '{{ action }}'
                {% if not loop.last %},{% endif %}
            {% endfor %}
        )
    )

{% endmacro %}
