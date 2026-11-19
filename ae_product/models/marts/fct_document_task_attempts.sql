{{ config(materialized='table') }}

{{ build_task_attempts([
    'document_editing',
    'document_review'
]) }}
