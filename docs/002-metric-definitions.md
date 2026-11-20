# Metric Definitions and Reporting Assumptions

## Reporting Grain

Metrics are calculated by task type and reporting period.

Each task attempt belongs to the period containing
its first qualifying activity event.

Supported reporting periods:
- Day
- Week
- Month
- Quarter

## Task Outcomes

**Completed:** An observed qualifying completion event.

**Failed:** An observed qualifying failure event.
In this fictional application, document rejection is
defined as a failed review task.

**Incomplete:** Qualifying activity without an observed
completion or failure event, where the abandonment
threshold has not been exceeded.

**Presumed abandoned:** An incomplete attempt whose last
qualifying activity occurred more than 10 minutes before
the latest source event timestamp in the dataset.

Presumed abandonment is inferred, not directly observed.

## Metric Definitions

**Task attempts:** Number of modeled task attempts.

**Completed tasks:** Attempts classified as completed.

**Failed tasks:** Attempts classified as failed.

**Abandoned tasks:** Attempts classified as presumed abandoned.

**Incomplete tasks:** Attempts still classified as incomplete.

**Completion rate (%):**
100 * completed tasks / all task attempts.

**Failure rate (%):**
100 * failed tasks / all task attempts.

**Abandonment rate (%):**
100 * presumed abandoned tasks / all task attempts.

**Average completion seconds:**
Average elapsed time from first qualifying activity
to completion, among completed attempts only.

The average is NULL when no attempts were completed.

## Reporting Considerations

- Incomplete attempts remain in rate denominators.
- Recent periods may contain attempts still in progress.
- All metrics are grouped by task start, not completion.
- Rates are recalculated from task-level counts rather
  than averaged from lower-level percentages.
- The abandonment reference time is the maximum source
  event timestamp, not the current wall-clock time.
- Historical classifications may change as more events
  arrive or workflow data is corrected.
- The demonstration does not implement incremental
  processing, watermarking, or historical reconciliation.

## Validation

Automated dbt tests check attribution, sessionization,
task consistency, aggregate reconciliation, and
reporting metric integrity.

A dbt unit test also validates duplicate-completion
handling within the reusable task model.
