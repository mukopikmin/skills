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

For each test or related group, read the full test, production path, and nearby tests. Identify the observable contract (user outcome, persisted state, API, protocol, security property, or regression) and the assertion that catches a realistic failure. Setup and execution alone prove nothing. Compare failures detected across tests, even when fixtures coincide or differ. Consult history, issues, comments, or blame only to clarify intent. Age, names, snapshots, and coverage alone cannot establish value.

## 3. Evaluate Deletion Candidates

Recommend deletion only if the test catches no realistic defect that could otherwise reach users or downstream code undetected. Check these categories:

- **Copied implementation:** the test computes its expected value with the same algorithm, branches, constants, or data transformations as production and therefore reproduces the same mistake.
- **Mock self-verification:** assertions primarily prove that a stub returns its configured value or that a mock was called according to test setup, without verifying a meaningful boundary contract.
- **Type guarantee:** the test rechecks behavior enforced by the active type system or compiler and contains no relevant runtime boundary.
- **Library guarantee:** the test merely confirms stable behavior owned by a language or dependency, rather than the codebase's configuration or use of it.
- **Duplicate protection:** another test would fail for the same realistic defect through an equal or stronger observable contract.
- **Implementation coupling:** the test pins private methods, call order, internal structure, incidental serialization, or exact mock choreography while externally correct refactors would fail it.
- **Excessive partitioning:** multiple cases exercise the same control-flow path and risk class; representative values or a smaller boundary set provide equivalent protection.
- **No effective assertion:** the test cannot fail for the behavior suggested by its name, makes only tautological assertions, or asserts unrelated output.
- **Obsolete or unreachable scenario:** the behavior no longer exists, cannot occur through supported interfaces, or belongs to a removed compatibility contract.

Retain the clearest protection for a distinct boundary, failure mode, compatibility promise, security property, or realistic regression. Size, speed, unit scope, snapshots, mocks, and overlap alone never justify deletion.

## 4. Evaluate Consolidation Candidates

Consolidate repeated setup or cases only when one test or parameterized table preserves every distinct failure signal. Name the survivor or replacement and the assertions, boundary values, and diagnostic labels it must keep. Prefer the highest useful contract level that keeps failures easy to locate and tests deterministic. Avoid giant tests with unrelated setup and slow end-to-end replacements that worsen diagnosis or determinism.

Treat parameter values as distinct only when they cross a branch, boundary, representation, permission, platform, failure mode, or historically fragile integration seam.

## 5. Weigh Value Against Cost

Weigh unique protection against runtime, resource use, flakiness, timing and platform sensitivity, external dependencies, fixture/mock complexity, refactor churn, diagnostic quality, and overlap. Use coverage to locate unexamined code. Test counts, line/branch coverage, snapshot volume, and vague assurances are never retention targets.

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

Lead with scope, frameworks, counts of files and cases reviewed, commands, exclusions, and candidate counts by action and confidence.

List every candidate in a sortable table or structured entries. Include exact file and test/case name, action (`Delete` or `Consolidate`), category, confidence, realistic defect uniquely missed (`None identified` if none), evidence from overlapping tests or the production contract, cost of retention, and survivor/replacement for consolidations.

Group related parameterized cases in one entry only when the proposed action applies to the whole named group. Separate exceptions.

Then include:

1. **Do not delete:** superficially suspicious tests whose distinct value deserves explanation.
2. **Needs confirmation:** low-confidence candidates and the exact domain question blocking a firm recommendation.
3. **Prioritized batches:** start with high-confidence deletions, then high-confidence consolidations, followed by review-required work.
4. **Coverage statement:** explain that candidate selection optimizes meaningful defect detection, runtime, stability, and maintenance—not count or coverage preservation.
5. **Audit limitations:** unavailable services, tests that could not run, dynamic cases that could not be enumerated, or portions not inspected.

Claim exhaustiveness only after reconciling the inventory and inspecting every area. Justify retention with a concrete defect.
