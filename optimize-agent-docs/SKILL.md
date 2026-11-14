---
name: optimize-agent-docs
description: Optimize repository documentation read by agents, including AGENTS.md, CLAUDE.md, SKILL.md, READMEs, and development guides. Use when asked to reduce redundant or overly detailed instructions, remove stale documentation, replace code-derived explanations with useful references, or audit agent documentation for reading cost and practical value.
---

# Optimize Agent Docs

Reduce the effort required to find and understand instructions while preserving the information agents need to make correct decisions. Optimize or clean-up requests authorize documentation edits; audit, review, or proposal requests are read-only. Commit, push, or open a pull request only when requested.

## 1. Establish Scope And Reading Paths

- Read applicable repository instructions and inspect the working tree. Preserve existing user changes and the documentation's language.
- Identify agent entrypoints, nested instructions, skills, READMEs, development guides, and their linked references within the requested scope. Exclude dependency caches, vendored trees, and generated output; update a generator's source when appropriate.
- Distinguish instructions loaded automatically from material consulted on demand. Determine each document's audience, authority, and directory or task scope before moving content.
- Prioritize frequently loaded documents and obvious duplication. Follow references and inspect related code as needed; do not require an exhaustive codebase audit for a focused cleanup.

## 2. Evaluate Information Value

For each candidate passage, ask: **If this disappears, what concrete mistake becomes more likely, and where else could an agent obtain the information at what cost?**

Compare suspect descriptions with the relevant code, configuration, commands, and other documents. Consult history only when intent is unclear. Classify by evidence, not length alone:

| Action | When appropriate |
| --- | --- |
| Keep | Design intent, constraints, exceptions, non-obvious hazards, or validation guidance that prevents a concrete mistake. |
| Condense | Repetition, long introductions, generic explanations, or examples that teach the same decision. |
| Reference | Details reliably available from an identifiable implementation, configuration, or canonical document. Keep a short orientation and a stable path or symbol when discovery would otherwise be difficult. |
| Move | Details needed only for a particular task, with a clear entrypoint explaining when to consult them. |
| Delete | Obsolete procedures, superseded duplication, or text that helps neither decisions nor discovery. |

Code describes current behavior; documentation may define intended behavior, unimplemented requirements, compatibility promises, or architectural constraints. A mismatch is evidence to investigate, not permission to erase the documented contract. Keep unresolved passages and state the specific uncertainty.

## 3. Make Focused Changes

- Preserve unique obligations, prohibitions, exceptions, and verification steps. Shorten their expression without weakening their meaning.
- Consolidate repeated guidance at the appropriate common scope and link to it where needed. Preserve intentional local overrides and do not broaden directory-specific rules.
- Replace implementation walkthroughs, file inventories, and copied configuration with concise navigation when reading the source is cheaper and equally informative.
- Keep useful examples when they clarify an ambiguous rule or a likely error. Remove examples that add no distinct guidance.
- Move task-specific detail out of frequently loaded instructions only when agents can reliably discover and load it. Account for loader behavior; a link does not guarantee a file will be read. Do not move mandatory instructions to optional references.
- Avoid fragmenting a coherent procedure across many files or replacing one useful explanation with a chain of lookups. Update inbound references before deleting or relocating a document.
- Keep edits within documentation and any necessary documentation metadata or generation source. Report unrelated code problems separately.

Do not target a word count or reduction percentage. Do not add exhaustive inventories, boilerplate warnings, or a permanent audit report that recreates the reading cost being removed.

## 4. Validate And Report

1. Review the diff for changed meaning, lost exceptions, accidental scope changes, and unrelated edits.
2. Verify affected local links, anchors, referenced paths or symbols, and entrypoints. Check that moved guidance remains reachable under the actual loading rules.
3. Trace representative affected tasks: can an agent still find the applicable constraints, implementation entrypoint, and validation command without excessive lookups?
4. Run applicable existing documentation, link, or metadata checks when available. Avoid application tests for prose-only changes; validate executable examples or generation changes when affected.

Report the scope reviewed, main edits or proposals with their evidence, validation performed, and unresolved questions or exclusions. For an audit, identify concrete paths and passages plus the proposed action. Mention size reduction only as supporting information; success means less reading and maintenance with the necessary guidance preserved.
