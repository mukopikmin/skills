---
name: audit-test-suite
description: Audit an entire codebase's tests and produce an evidence-based, exhaustive list of tests to delete or consolidate. Use when asked to review test value, reduce a bloated or slow test suite, identify redundant, implementation-coupled, mock-validating, library-validating, type-validating, copied-implementation, or over-partitioned tests, or propose test-suite pruning without treating test count or coverage preservation as goals.
---

# Audit Test Suite

Inspect the complete test suite, compare each test's unique protection against its maintenance and execution cost, and report deletion and consolidation candidates. Do not edit tests unless the user explicitly asks for changes.

## Preserve The User's Work

- Read all applicable repository instructions before inspecting files.
- Inspect the working tree first. Do not overwrite, revert, format, or otherwise disturb existing changes.
- Use the user's language for progress updates and the final report.

## 1. Inventory The Entire Suite

1. Identify languages, packages, workspaces, test runners, and repository-specific test conventions from manifests, CI configuration, task runners, and contributor documentation.
2. Enumerate every test source, including colocated tests, dedicated test directories, fixtures that generate cases, snapshots, parameterized cases, doctests, integration and end-to-end suites, and test-only helper packages.
3. Search for runner configuration, naming exceptions, generated suites, ignored or skipped tests, and CI-only commands. Do not assume a conventional filename glob is complete.
4. Create a working inventory at test-case or parameterized-case-group granularity. Record file, test name, suite, behavior claimed, dependencies or fixtures, and whether it can actually run in the current environment.
5. Compare the inventory against collected/discovered tests when the runner supports a safe collection mode. Reconcile omissions before evaluating candidates.

Use targeted searches and bounded file listings; avoid commands that are known to perform poorly on large repositories.

## 2. Recover The Real Contract

For each test or tightly related group:

1. Read the complete test, the production path it exercises, and nearby tests of the same behavior.
2. Determine the externally meaningful contract: user-visible result, persisted state, public API, protocol interaction, security property, or regression tied to a plausible failure.
3. Identify the assertion that would fail for that regression. Setup and execution alone are not protection.
4. Inspect history, issue references, comments, and blame only when the reason for an otherwise odd test is unclear. Do not equate age with low value.
5. Distinguish identical setup from identical protection. Tests using the same fixture may guard different failures; tests with different setup may guard the same failure.

Do not judge from test names, snapshots, or line coverage alone.

## 3. Evaluate Deletion Candidates

Ask the controlling question: **If this test disappears, what realistic defect could reach users or downstream code without another test detecting it?**

Recommend deletion when no concrete, credible defect remains uniquely detectable, especially for:

- **Copied implementation:** the test computes its expected value with the same algorithm, branches, constants, or data transformations as production and therefore reproduces the same mistake.
- **Mock self-verification:** assertions primarily prove that a stub returns its configured value or that a mock was called according to test setup, without verifying a meaningful boundary contract.
- **Type guarantee:** the test rechecks behavior enforced by the active type system or compiler and contains no relevant runtime boundary.
- **Library guarantee:** the test merely confirms stable behavior owned by a language or dependency, rather than the codebase's configuration or use of it.
- **Duplicate protection:** another test would fail for the same realistic defect through an equal or stronger observable contract.
- **Implementation coupling:** the test pins private methods, call order, internal structure, incidental serialization, or exact mock choreography while externally correct refactors would fail it.
- **Excessive partitioning:** multiple cases exercise the same control-flow path and risk class; representative values or a smaller boundary set provide equivalent protection.
- **No effective assertion:** the test cannot fail for the behavior suggested by its name, makes only tautological assertions, or asserts unrelated output.
- **Obsolete or unreachable scenario:** the behavior no longer exists, cannot occur through supported interfaces, or belongs to a removed compatibility contract.

Do not automatically delete tests just because they are small, fast, unit-level, snapshot-based, mocked, or overlapping. Retain a test when it is the clearest protection for a distinct boundary, failure mode, compatibility promise, security property, or prior realistic regression.

## 4. Evaluate Consolidation Candidates

Recommend consolidation when one coherent test or parameterized table can preserve all valuable failure signals with less repetition. For every proposed group:

1. Name the test to retain or describe the replacement test.
2. State which assertions, boundary values, and diagnostic labels must survive.
3. Remove redundant setup and cases, not distinct behaviors.
4. Avoid giant tests whose failure location becomes ambiguous or whose unrelated setup increases flakiness.
5. Prefer the highest useful contract level, but do not replace fast, precise edge-case tests with a slow end-to-end test when diagnosis or determinism would materially worsen.

Treat parameter values as distinct only when they cross a branch, boundary, representation, permission, platform, failure mode, or historically fragile integration seam.

## 5. Weigh Value Against Cost

Compare protection with:

- runtime and resource use;
- nondeterminism, timing sensitivity, external services, and platform sensitivity;
- fixture and mock complexity;
- frequency of updates caused by valid implementation changes;
- diagnostic quality when the test fails;
- overlap with stronger tests.

Do not preserve tests to maintain test counts, line or branch coverage percentages, snapshot volume, or a vague sense of safety. Coverage may help locate unexamined code, but it is neither a retention criterion nor a required post-pruning target.

Assign confidence conservatively:

- **High:** direct evidence shows no unique realistic defect protection.
- **Medium:** likely redundant or over-partitioned, but contract or history has some ambiguity.
- **Low:** plausible candidate that requires owner or domain confirmation; keep it out of an unconditional deletion batch.

## 6. Validate Findings

1. Run safe test discovery and repository-standard tests when feasible; record exact commands and outcomes.
2. Use runner timing, retry, or flake data when readily available, but do not delay the audit waiting for unavailable historical metrics.
3. When practical, validate a representative high-confidence finding by temporarily removing or narrowing the candidate, running the strongest overlapping tests, and restoring the file exactly. Never do this over uncommitted user edits or leave audit mutations behind.
4. Recheck every proposed consolidation group for an assertion or boundary that would be lost.
5. Confirm that all inventoried areas were reviewed. Explicitly name any excluded, generated, inaccessible, or non-runnable areas.

Passing tests do not prove redundancy. Mutation testing may strengthen evidence when already supported by the repository, but do not introduce it as a prerequisite.

## Final Report

Lead with an audit summary: scope, test frameworks, number of files and cases reviewed, commands run, exclusions, and candidate totals by action and confidence.

List **every** candidate in a sortable table or repeated structured entries containing:

- exact file and test or case name;
- action: `Delete` or `Consolidate`;
- category from the criteria above;
- confidence;
- the realistic defect uniquely missed after the change, written explicitly as `None identified` when that is the conclusion;
- evidence, including the overlapping test or production contract;
- cost or harm of retention;
- concrete replacement or survivor for consolidation.

Group related parameterized cases in one entry only when the proposed action applies to the whole named group. Separate exceptions.

Then include:

1. **Do not delete:** superficially suspicious tests whose distinct value deserves explanation.
2. **Needs confirmation:** low-confidence candidates and the exact domain question blocking a firm recommendation.
3. **Prioritized batches:** start with high-confidence deletions, then high-confidence consolidations, followed by review-required work.
4. **Coverage statement:** explain that candidate selection optimizes meaningful defect detection, runtime, stability, and maintenance—not count or coverage preservation.
5. **Audit limitations:** unavailable services, tests that could not run, dynamic cases that could not be enumerated, or portions not inspected.

Do not claim the audit is exhaustive unless the inventory was reconciled and every area was inspected. Never use “just in case” as a retention rationale; name the concrete defect or recommend removal.
