# ADR 001: Cross-Source Sessionization

## Problem

Product activity spans multiple event sources.
Sessions must represent activity around a business entity,
not individual source-system sessions.

## Design

- Partition events by account and resolved document ID.
- Order all events chronologically across sources.
- Use a 10-minute inactivity threshold.
- Identify session boundaries with LAG().
- Generate session numbers using cumulative SUM().
- Assign a session ID using account, document, and session number.

## Why This Approach?

This provides a simple, reproducible way to reconstruct
continuous entity-level activity across event sources.

It also separates session boundaries from source-specific
tracking implementations.

## Identified Limitation: Late-Arriving Events

An isolated SQL experiment demonstrated that inserting
a historical event at 09:14 created a new session between
previously identified sessions.

Consequently, an existing event at 09:25 changed from
session S002 to S003.

Sequential session IDs are therefore not guaranteed
to remain stable when historical data changes.

## Production Considerations

Potential improvements include:

- Evaluating session identifiers anchored to starting events.
- Reprocessing an appropriate historical lookback window.
- Reconciling downstream task IDs and aggregates after changes.
- Testing late-arriving and out-of-order events.
- Monitoring changes to historical session assignments.

Start-event-based IDs are not completely stable when
late events change session boundaries or starting events.

## Decision

Retain sequential session IDs for this synthetic demonstration.

Document the limitations rather than implementing additional
production infrastructure outside the project's scope.
