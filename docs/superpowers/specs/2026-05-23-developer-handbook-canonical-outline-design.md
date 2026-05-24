# Developer Handbook — Canonical Outline (Design Spec)

**Date:** 2026-05-23
**Status:** Approved — ready for implementation planning
**Scope:** Every `leastudios-*` plugin in the suite

---

## 1. Purpose

Today, three plugins in the suite ship a `docs/developer-handbook.md` — `forms`, `mailer`, and `snippets` — and the three handbooks diverge significantly in scope, structure, and per-hook formatting. Five plugins (`payments`, `email-templates`, `siteaudit`, `helpscout-ai-dashboard`, `dev-tools`) have no handbook at all.

This spec defines **one** canonical handbook structure so that every plugin in the suite presents extension authors with the same surface: same section order, same per-hook entry template, same REST format, same recipe shape. New plugins start from a checked-in template; existing plugins are levelled up to match.

The audience for the handbook is the **extension author** — a developer integrating with the plugin from a theme or sibling plugin, not a contributor to the plugin itself. Contribution / development setup is still covered, but as a path to writing tests for an extension, not as a path to upstream PRs (which `CLAUDE.md` already covers).

## 2. Background — what we have today

| Plugin | Handbook | Style |
|---|---|---|
| forms | ✅ 747 lines | Subject-grouped (Render / Submission / Notification / Admin / Registration). Forms-style entries (bullet metadata + parameter table + Returns + example). No `Since`. No TOC anchor for sub-sections. |
| snippets | ✅ 761 lines | Type-grouped (Filters / Actions). "Detail / Value" mini-table per hook + `Since` field. Bonus deep-dive on "Snippet Library — Adding Programmatically". ASCII flow diagram. Summary table. |
| mailer | ✅ 489 lines | Type-grouped (Filters / Actions). Bullet-style metadata, no parameter table. No TOC. Cross-cutting "Attachments" section at end. |
| payments | ❌ | — |
| email-templates | ❌ | — |
| siteaudit | ❌ | — |
| helpscout-ai-dashboard | ❌ | — |
| dev-tools | ❌ | — |

The three existing handbooks share a core shape (TOC → hook entries → execution order) but diverge on: (a) hook categorization, (b) per-hook template, (c) presence of `Since`, (d) presence of TOC, (e) whether non-hook surface (REST, CLI, public PHP API) is documented.

## 3. Design decisions

These seven decisions were settled in the brainstorming round and are the load-bearing requirements for the template:

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 1 | Scope | **Full developer guide** | One-stop reference for extenders. Accepts some duplication with `CLAUDE.md` / `README.md` in exchange for not making extenders chase 3 docs to integrate. |
| 2 | Hook layout | **By subject / phase** (per-plugin taxonomy) | Maps to the extender's mental model ("I want to change render behaviour"). Forms already proves this scales. |
| 3 | Per-hook entry | **Forms-style table + `Since` row** | Cleanest of the three existing styles; adding `Since` brings it in line with Snippets. |
| 4 | Section list | **14 sections; required (★) and optional (◯) marked** | Maximum consistency for required sections; thin plugins skip optional sections rather than write "N/A" boilerplate. |
| 5 | Outline location | `leastudios-dev-tools/docs/developer-handbook-template.md` | Lives next to the mother CLAUDE.md; new plugins copy this when scaffolding. |
| 6 | REST format | **Route summary table + per-endpoint detail block** | Mirrors the Forms hook table style. Gives both at-a-glance and depth. |
| 7 | Recipes format | **Task-oriented worked examples** ("How do I X?") | Fills the gap between hook reference and architecture; highest reader value. |

## 4. Canonical section list

The handbook for every plugin has these sections, in this order:

| # | Section | Required? | Purpose |
|---|---|---|---|
| 1 | Overview | ★ | What the plugin does; key concepts; audience; ≤ 300 words |
| 2 | Architecture | ★ | Components diagram; data flow; key modules; references back to `CLAUDE.md` for internals |
| 3 | Development Setup | ★ | composer install, test lib, sibling plugins needed to exercise integrations |
| 4 | Concepts / Glossary | ◯ | Recurring domain terms (e.g. "snippet location", "ability category"). Skip if every term is obvious from context. |
| 5 | Data Model | ◯ | Custom tables, post types/meta, options, transients exposed to extenders. Skip if there is no persistent state worth exposing. |
| 6 | Hooks Reference | ★ | Grouped by subject; each group sorted with filters before actions. Type tagged per entry. |
| 7 | Hook Execution Order | ★ | Flow diagram (ASCII or mermaid) + a summary table sorted by firing order. Required even if the plugin only has 2 hooks (it's a 5-line summary). |
| 8 | REST API Reference | ◯ | Route summary table + per-endpoint detail. Skip if the plugin exposes no REST routes. |
| 9 | WP-CLI Commands | ◯ | Commands the plugin registers via `WP_CLI::add_command()`. Skip if none. |
| 10 | Public PHP API | ◯ | Classes / interfaces / methods explicitly intended for use by other plugins (e.g. `Suite_Detector`, `Field_Type`). Skip if the plugin offers nothing public beyond hooks. |
| 11 | Extension Recipes | ◯ | 5–8 task-oriented worked examples. Skip only if the plugin's surface is so narrow that recipes would be 1-line restatements of single hooks. |
| 12 | Testing | ★ | Running the suite; writing extension tests that load the plugin. |
| 13 | Release Process | ★ | Recap of the tag-triggered workflow (the canonical block in `CLAUDE.md`). |
| 14 | Where to read more | ★ | Links to mother `CLAUDE.md`, plugin `README.md`, related plugin handbooks. |

### Section omission rules

When an optional section does not apply, **omit the section entirely** — do not write "N/A" or "This plugin has no REST endpoints". In the published handbook, **renumber sequentially from 1** so there are no gaps in the TOC (a plugin without REST/CLI/Public API/Recipes ships with 10 sequentially-numbered sections, not 14 with holes). The "section numbers" in this spec (Section 8 = REST, Section 11 = Recipes, etc.) are template-internal references only — they do not need to match the final handbook's numbering.

Cross-handbook consistency comes from the **section titles** (every handbook that ships REST docs titles the section "REST API Reference"), not from a shared section number.

## 5. Per-hook entry template

Every hook entry follows this exact shape:

````markdown
### `leastudios_<plugin>_<hook_name>`

- **Type:** Action | Filter
- **Location:** `src/Path/To/File.php`
- **Since:** 1.0.0
- **Description:** One-paragraph explanation of when this fires and what it lets you do. Two paragraphs maximum.

**Parameters:**

| Parameter | Type | Description |
|---|---|---|
| `$arg_1` | `int` | Short description. |
| `$arg_2` | `array<string, mixed>` | Short description. |

**Returns:** `array` — *(filters only; describe what to return)*

**Example:**

```php
add_filter( 'leastudios_<plugin>_<hook_name>', function ( int $arg_1, array $arg_2 ): array {
    // realistic, copy-pasteable example
    return $arg_2;
}, 10, 2 );
```

---
````

**Rules:**

- The four metadata bullets (`Type`, `Location`, `Since`, `Description`) appear in that order, even when one is one word.
- `Location` is the source file relative to the plugin root, not absolute.
- `Since` is the plugin version in which the hook was introduced. For hooks that already exist when the canonical template is rolled out, use the current plugin version.
- `Returns:` line is **omitted entirely** for actions and **required** for filters.
- The example is realistic, not a stub. It calls out a concrete use case (e.g. "block free-email providers on the business enquiry form") rather than `// do stuff`.
- The closing `---` separator is mandatory; it gives visual breathing room when scrolling a hook-heavy reference.

### Hook grouping inside Section 6

Subjects are defined per plugin (the taxonomy is not universal). Within each subject group, entries are sorted **filters first, actions second**, then alphabetically inside each type. Each group gets an H2 (`## Submission Hooks`); each hook is an H3 (`### `leastudios_forms_submission_created``).

The TOC at the top of the handbook lists every hook by name, nested under its subject group.

## 6. REST API section template

````markdown
## REST API Reference

Namespace: `leastudios-<plugin>/v1`

| Method | Route | Description | Capability |
|---|---|---|---|
| GET | `/things` | List things | `manage_options` |
| POST | `/things` | Create a thing | `manage_options` |

### `GET /things`

- **Endpoint:** `/wp-json/leastudios-<plugin>/v1/things`
- **Controller:** `src/REST/Things_Controller.php`
- **Capability:** `manage_options` (set by `permission_callback`)
- **Query parameters:**

  | Name | Type | Required | Description |
  |---|---|---|---|
  | `page` | `int` | no | Page number (default `1`). |

- **Response (200):**

  ```json
  {
    "items": [ { "id": 1, "name": "Example" } ],
    "total": 1
  }
  ```

- **Example:**

  ```bash
  curl -u admin:pw https://example.com/wp-json/leastudios-foo/v1/things
  ```

---
````

**Rules:**

- The summary table at the top lists **every** route in the plugin, regardless of whether each gets a detail block. (Detail blocks are required for every public route, but the table is the fast index.)
- `Capability` describes what `permission_callback` actually enforces, not a description of who *should* be able to call it.
- Request/response examples use realistic field values, not `"string"`.

## 7. Extension Recipes section template

````markdown
## Extension Recipes

### How do I send form submissions to a CRM?

**Goal:** Push every new submission to an external CRM as soon as it is stored.

**Hooks used:** `leastudios_forms_submission_created`, `leastudios_forms_entry_data`.

**Walkthrough:** Two-to-four paragraphs explaining the choice of hooks, the order they fire, and any gotchas (race conditions, blocking calls, retry behaviour).

**Complete example:**

```php
add_action( 'leastudios_forms_submission_created', function ( int $entry_id, int $form_id, array $data ): void {
    // copy-pasteable, no placeholders left
}, 10, 3 );
```

---
````

**Rules:**

- A recipe is task-oriented, not hook-oriented. The H3 starts with "How do I…" and ends with `?`.
- A recipe combines **at least two** hooks / REST routes / public APIs — single-hook examples belong in the hook entry, not in recipes.
- Plugins target **5–8 recipes**. Fewer than 5 means the plugin's surface is too narrow for the section; omit it. More than 8 means recipes have started recapitulating the hook reference.
- "Complete example" is fully runnable; no `// ...` ellipses inside the code block.

## 8. Public PHP API section template

When a plugin exposes classes that extension authors are expected to instantiate, implement, or extend (e.g. `Field_Type` interface, `Suite_Detector` helper):

````markdown
## Public PHP API

### `LEAStudios\Forms\Field\Field_Type` *(interface)*

- **File:** `src/Field/Field_Type.php`
- **Since:** 1.0.0
- **Purpose:** Implemented by every field type. Register your implementation via the `leastudios_forms_field_types` action.

**Methods:**

| Method | Signature | Description |
|---|---|---|
| `get_type` | `(): string` | Unique slug for this field type. |
| `sanitize` | `( mixed $value ): mixed` | Sanitise a raw submitted value. |

**Example implementation:** see `leastudios_forms_field_types` recipe in Hooks Reference.

---
````

Classes that are only public because PHP's visibility rules force them to be (no `internal` keyword) but that are not part of the contract — e.g. `Plugin`, controllers, repositories — are **not** documented here. The rule of thumb: if a hook or recipe doesn't reference a class, it doesn't belong in this section.

## 9. Hook Execution Order template

````markdown
## Hook Execution Order

For a typical successful <flow name>, hooks fire in this order:

```
(plugins_loaded)
    |
    +-- [filter] leastudios_<plugin>_first_filter
    +-- [action] leastudios_<plugin>_first_action
    |
(init)
    |
    +-- [filter] leastudios_<plugin>_late_filter
```

| Order | Hook | Type | Trigger |
|---|---|---|---|
| 1 | `leastudios_<plugin>_first_filter` | Filter | Right after the request is parsed |
| 2 | `leastudios_<plugin>_first_action` | Action | Immediately after #1 |
| 3 | `leastudios_<plugin>_late_filter` | Filter | During `init` |

Hooks that fire outside the main request flow (cron, webhook endpoints, admin-only paths) are listed in separate sub-sections below.
````

The ASCII diagram is required even if there are only 2 hooks. The summary table is required because text-only diagrams are hard to scan when you already know the hook's name.

## 10. Rollout — what gets produced from this spec

The implementation plan (built in the next phase via `writing-plans`) covers, in order:

1. **The template doc itself** — `leastudios-dev-tools/docs/developer-handbook-template.md`. Annotated with `<!-- comments -->` explaining each section. New plugins copy this and fill in.

2. **One handbook per plugin without one** — for `payments`, `email-templates`, `siteaudit`, `helpscout-ai-dashboard`, `dev-tools`. Each is created from the template via:
   - Reading the plugin's `CLAUDE.md`, `README.md`, `src/Plugin.php`, and any obvious extension points.
   - Cataloguing hooks via `grep -rn 'apply_filters\|do_action' src/`.
   - Cataloguing REST routes via `grep -rn 'register_rest_route' src/`.
   - Cataloguing WP-CLI commands via `grep -rn 'WP_CLI::add_command' src/`.

3. **Upgrades to the three existing handbooks**:
   - **forms** — already closest to canonical. Add Sections 1, 2, 3, 5 (Data Model), 7 (it has a flow list but not a diagram + table), 8 (REST), 10 (Public PHP API — `Field_Type` interface), 11 (Recipes), 12, 13, 14. Add a `Since` row to every hook entry.
   - **mailer** — add TOC, Sections 1, 2, 3, 5, 7 (it has order but no diagram), 8, 11, 12, 13, 14. Convert bullet-style param lists into the canonical parameter table. Add `Since` rows.
   - **snippets** — reorganize Section 6 from type-based (Filters / Actions) into subject-based. Add Sections 1, 2, 3, 5, 8 (if any REST exists), 11 (recipes — promote "Adding Custom Snippets Programmatically" into one recipe + split into several). Convert "Detail | Value" mini-tables into the canonical bullet metadata + parameter table.

Each handbook lives at `<plugin>/docs/developer-handbook.md` and is committed in the plugin's own git repo. Each commit message follows the per-plugin convention (`docs: add developer handbook` or similar — within the conventional-commits format the release workflows expect).

## 11. Out of scope

- **Translating handbooks.** Handbooks are English-only.
- **Generating handbooks from code.** No annotation-driven generation (no `@hook` PHPDoc parsing). The handbook is hand-maintained; CI does not enforce that every `apply_filters` call has a matching handbook entry. A linter for that could be added later, separately.
- **Restructuring `CLAUDE.md` or `README.md`.** Those files retain their current shapes. The handbook may reference them; it does not replace them.
- **A single shared handbook for the whole suite.** Each plugin owns its handbook. Cross-plugin extension patterns (e.g. how `forms` calls into `mailer`) are documented in *both* plugins' Recipes sections from the respective sides.

## 12. Open questions

None at spec-approval time. Any ambiguity encountered during the rollout is resolved by:

1. Looking at how `forms` (the closest-to-canonical existing handbook) handles it; if it doesn't, then
2. Looking at how `snippets` handles it; if neither does, then
3. Inventing the answer and writing it back into this spec as an amendment.
