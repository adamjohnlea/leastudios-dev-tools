<!--
  CANONICAL DEVELOPER-HANDBOOK TEMPLATE
  See: docs/superpowers/specs/2026-05-23-developer-handbook-canonical-outline-design.md

  How to use this template:
  1. Copy this file to `<your-plugin>/docs/developer-handbook.md`.
  2. Replace every `<placeholder>` (angle-bracketed) with concrete content.
  3. Delete sections that don't apply per the optional/required column in the spec.
  4. Renumber the surviving sections sequentially (1, 2, 3, ...).
  5. Run `bash leastudios-dev-tools/bin/check-handbook.sh <your-plugin>/docs/developer-handbook.md`
     and resolve any missing-section errors before committing.

  Section legend:  ★ = required (do NOT delete)  /  ◯ = optional (delete if N/A)
-->

# <Plugin Display Name> — Developer Handbook

<One-paragraph elevator pitch for extension authors: what this plugin does
and what an integration could hook into.>

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Development Setup](#3-development-setup)
4. [Concepts](#4-concepts)
5. [Data Model](#5-data-model)
6. [Hooks Reference](#6-hooks-reference)
7. [Hook Execution Order](#7-hook-execution-order)
8. [REST API Reference](#8-rest-api-reference)
9. [WP-CLI Commands](#9-wp-cli-commands)
10. [Public PHP API](#10-public-php-api)
11. [Extension Recipes](#11-extension-recipes)
12. [Testing](#12-testing)
13. [Release Process](#13-release-process)
14. [Where to Read More](#14-where-to-read-more)

---

## 1. Overview  <!-- ★ required -->

<≤ 300 words. Explain: who this plugin serves, what problem it solves, what
its key concepts are. Audience: an extension author who has never opened the
codebase.>

## 2. Architecture  <!-- ★ required -->

<Components, data flow, key modules. If you have a diagram, include it here
as a fenced ASCII block. Reference back to CLAUDE.md for internals; this
section gives extenders a mental model, not a full tour.>

## 3. Development Setup  <!-- ★ required -->

```bash
cd wp-content/plugins/<plugin-slug>
composer install
composer lint              # phpcs + phpstan
composer test              # PHPUnit
```

<List any sibling plugins required to exercise integrations, and how to
install the shared WP test library if not yet installed.>

## 4. Concepts  <!-- ◯ optional — delete if every term is obvious in context -->

<Definitions of recurring domain terms (e.g. "snippet location", "ability
category"). One H3 per term. Skip if the plugin has no jargon.>

## 5. Data Model  <!-- ◯ optional — delete if no persistent state worth exposing -->

<Custom tables, post types, post meta keys, options, transients that an
extension author may want to read or write. For each: schema + access pattern.>

## 6. Hooks Reference  <!-- ★ required -->

<Group by SUBJECT/PHASE, not by type. Example subject groups: "Render Hooks",
"Submission Hooks", "Webhook Hooks". Within each group: filters first, then
actions, then alphabetical inside each type.>

### <Subject Group Name>

#### `leastudios_<plugin>_<hook_name>`

- **Type:** Action | Filter
- **Location:** `src/Path/To/File.php`
- **Since:** 1.0.0
- **Description:** <One paragraph. When does it fire? What does calling it
  let you change?>

**Parameters:**

| Parameter | Type | Description |
|---|---|---|
| `$arg_1` | `int` | <Short description.> |
| `$arg_2` | `array<string, mixed>` | <Short description.> |

**Returns:** `<type>` — <description>  <!-- filters only; delete row for actions -->

**Example:**

```php
add_filter( 'leastudios_<plugin>_<hook_name>', function ( int $arg_1, array $arg_2 ): array {
    // Realistic, copy-pasteable example. NO `// do stuff` stubs.
    return $arg_2;
}, 10, 2 );
```

---

## 7. Hook Execution Order  <!-- ★ required -->

For a typical <flow name>, hooks fire in this order:

```
(WordPress hook)
    |
    +-- [filter] leastudios_<plugin>_first_filter
    +-- [action] leastudios_<plugin>_first_action
    |
(next WordPress hook)
    |
    +-- [filter] leastudios_<plugin>_late_filter
```

| Order | Hook | Type | Trigger |
|---|---|---|---|
| 1 | `leastudios_<plugin>_first_filter` | Filter | <when> |
| 2 | `leastudios_<plugin>_first_action` | Action | <when> |
| 3 | `leastudios_<plugin>_late_filter` | Filter | <when> |

<Hooks that fire outside the main flow — cron, webhooks, admin-only — go in
separate sub-sections after the main table.>

## 8. REST API Reference  <!-- ◯ optional — delete if no REST routes -->

Namespace: `leastudios-<plugin>/v1`

| Method | Route | Description | Capability |
|---|---|---|---|
| GET | `/<resource>` | <Short description> | `<cap>` |

### `<METHOD> /<route>`

- **Endpoint:** `/wp-json/leastudios-<plugin>/v1/<route>`
- **Controller:** `src/REST/<Controller>.php`
- **Capability:** `<cap>` (enforced by `permission_callback`)
- **Query parameters:** <table or "none">
- **Request body:** <schema or "none">
- **Response (200):**

  ```json
  { "example": "use real values" }
  ```

- **Example:**

  ```bash
  curl -u admin:pw https://example.com/wp-json/leastudios-<plugin>/v1/<route>
  ```

---

## 9. WP-CLI Commands  <!-- ◯ optional — delete if no CLI commands -->

### `wp <plugin> <subcommand>`

- **File:** `src/CLI/<Command>.php`
- **Synopsis:** `wp <plugin> <subcommand> [--<option>=<value>]`
- **Options:** <table>
- **Description:** <one paragraph>
- **Example:**

  ```bash
  wp <plugin> <subcommand> --verbose
  ```

---

## 10. Public PHP API  <!-- ◯ optional — delete if nothing public beyond hooks -->

### `LEAStudios\<Plugin>\<Namespace>\<ClassName>` *(interface | class | trait)*

- **File:** `src/<Namespace>/<ClassName>.php`
- **Since:** 1.0.0
- **Purpose:** <One sentence. Why is this part of the public surface?>

**Methods:**

| Method | Signature | Description |
|---|---|---|
| `method_name` | `( int $arg ): bool` | <description> |

<Cross-reference the recipe or hook that uses this class.>

---

## 11. Extension Recipes  <!-- ◯ optional — delete if surface is too narrow for 5+ recipes -->

### How do I <task>?

**Goal:** <one-sentence goal>

**Hooks used:** `leastudios_<plugin>_<hook_a>`, `leastudios_<plugin>_<hook_b>`.

**Walkthrough:** <2-4 paragraphs. Explain the choice of hooks, firing order,
and gotchas (race conditions, blocking calls, retry behaviour).>

**Complete example:**

```php
// Fully runnable. No `// ...` ellipses inside the code block.
```

---

## 12. Testing  <!-- ★ required -->

```bash
composer test                                # run the full suite
vendor/bin/phpunit --filter <TestClass>      # one class
vendor/bin/phpunit tests/<file>.php          # one file
```

<Brief notes on test-writing for an extension that loads this plugin —
typically, how to bootstrap the plugin in the test environment.>

## 13. Release Process  <!-- ★ required -->

This plugin uses a tag-triggered release workflow (`.github/workflows/release.yml`)
that auto-generates release notes from the commit log between the previous and
current tag.

**To cut a release:** bump the `Version:` header in the main plugin file, commit, then:

```bash
git tag v<X.Y.Z> && git push origin v<X.Y.Z>
```

**Commit-prefix → release-notes section:**

- `feat:` → `## Added`
- `fix:` → `## Fixed`
- `refactor:` → `## Changed`
- `perf:` → `## Performance`

**Hidden from release notes:** `ci:`, `chore:`, `docs:`, `test:`, `style:`, `build:`, `release:`.

## 14. Where to Read More  <!-- ★ required -->

- [`CLAUDE.md`](../CLAUDE.md) — this plugin's repo conventions and gotchas.
- [`README.md`](../README.md) — user-facing overview.
- [`leastudios-dev-tools/CLAUDE.md`](../../leastudios-dev-tools/CLAUDE.md) — suite-wide coding standards and security rules inherited by every plugin.
- <Sibling plugin handbooks this one integrates with.>
