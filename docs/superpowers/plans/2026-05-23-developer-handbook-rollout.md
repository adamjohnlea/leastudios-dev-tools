# Developer Handbook Canonical Rollout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Roll out one canonical developer-handbook shape across the leastudios-* plugin suite — 1 template doc + 5 net-new handbooks + 3 upgrades to existing handbooks.

**Architecture:** The shared template lives in `leastudios-dev-tools`. Each plugin's handbook lives at `<plugin>/docs/developer-handbook.md` and is committed in that plugin's own git repo. Per-plugin tasks are independent and can be paused/resumed between them; the template task is the only sequential prerequisite.

**Tech Stack:** Markdown only. No build step. Verification is a manual checklist run against each completed handbook plus a `grep` smoke test for required section titles.

**Spec:** [`leastudios-dev-tools/docs/superpowers/specs/2026-05-23-developer-handbook-canonical-outline-design.md`](../specs/2026-05-23-developer-handbook-canonical-outline-design.md)

---

## File Structure

| Path | Created or modified | Responsibility |
|---|---|---|
| `leastudios-dev-tools/docs/developer-handbook-template.md` | **create** | The canonical template, with `<!-- comments -->` explaining what to put in each section. Source of truth for every plugin handbook. |
| `leastudios-dev-tools/bin/check-handbook.sh` | **create** | A grep-based smoke test that verifies a handbook has all required H2 section titles. Returns non-zero on missing sections. |
| `leastudios-payments/docs/developer-handbook.md` | **create** | New handbook for the payments plugin (21 hooks, 7 REST routes). |
| `leastudios-email-templates/docs/developer-handbook.md` | **create** | New handbook (12 hooks, 2 REST, 6 CLI commands). |
| `leastudios-siteaudit/docs/developer-handbook.md` | **create** | New handbook (2 hooks, no REST/CLI — minimal). |
| `leastudios-helpscout-ai-dashboard/docs/developer-handbook.md` | **create** | New handbook (0 hooks, 6 REST, 2 CLI — REST-focused). |
| `leastudios-dev-tools/docs/developer-handbook.md` | **conditional create** | Only if the surface audit at the start of Task 9 finds anything to document. Otherwise skipped with a written justification appended to this plan. |
| `leastudios-forms/docs/developer-handbook.md` | **modify** | Add sections 1–5, 7 (diagram), 8 (REST), 10 (Public PHP API), 11 (recipes), 12, 13, 14. Add `Since:` row to every existing hook entry. |
| `leastudios-mailer/docs/developer-handbook.md` | **modify** | Add TOC, sections 1–5, 7 (diagram), 8, 11, 12, 13, 14. Convert bullet-style param lists to canonical parameter tables. Add `Since:` rows. |
| `leastudios-snippets/docs/developer-handbook.md` | **modify** | Reorganize hook section from type-based to subject-based. Add sections 1–5, 8 (if REST exists), 11 (recipes — incorporate the existing "Adding Custom Snippets Programmatically" deep-dive). Convert "Detail/Value" mini-tables to canonical bullet metadata + parameter table. |

---

## Conventions Used Throughout This Plan

- **Working directory:** Each plugin is its own git repo. All commands assume `cd <plugin-dir>` first. The path `wp-content/plugins/leastudios-<slug>` is shown relative to `/Users/adamlea/Herd/leastudios-plugins`.
- **Commit prefix:** Every plugin uses the conventional-commit prefix → release-notes mapping documented in its `CLAUDE.md`. New handbooks use `docs:` (hidden from release notes — handbooks are not user-facing changelog material).
- **No push:** Tasks `git commit` only. Pushing is left to the user.
- **No backward-compat shims:** When upgrading existing handbooks, sections are restructured directly. Anchor links inside the handbook may break; that is acceptable.
- **Sequential numbering:** Per the spec's Section 4 omission rule, every published handbook renumbers its sections 1..N sequentially. Cross-handbook consistency comes from section *titles*.

---

## Task 1: Create the canonical template doc

**Files:**
- Create: `leastudios-dev-tools/docs/developer-handbook-template.md`

The template is a real markdown file an extender can read as a worked example — *not* a Mustache-style file full of `{{tokens}}`. Replace-in-place placeholders use angle brackets (`<plugin>`, `<slug>`, `<flow name>`) so the rest of the file reads as natural prose.

- [ ] **Step 1: Confirm spec is accessible**

Run from the plan's repo:

```bash
test -f /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools/docs/superpowers/specs/2026-05-23-developer-handbook-canonical-outline-design.md && echo OK
```

Expected: `OK`.

- [ ] **Step 2: Write the template file**

Create `leastudios-dev-tools/docs/developer-handbook-template.md` with this exact content:

```markdown
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
```

- [ ] **Step 3: Smoke-check the template renders**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
wc -l docs/developer-handbook-template.md
grep -c '^## ' docs/developer-handbook-template.md
```

Expected: the file is ~200 lines and has exactly 14 H2 sections (matching the spec's required list).

- [ ] **Step 4: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
git add docs/developer-handbook-template.md
git commit -m "docs: add canonical developer-handbook template"
```

---

## Task 2: Create the section-presence checker script

**Files:**
- Create: `leastudios-dev-tools/bin/check-handbook.sh`

A small grep-based smoke test. Catches the most common drift (a section was deleted, or its title was rewritten to something off-canonical) without trying to validate prose.

- [ ] **Step 1: Write the script**

Create `leastudios-dev-tools/bin/check-handbook.sh` with this content:

```bash
#!/usr/bin/env bash
#
# Verify a developer-handbook.md has the required canonical section titles.
# Usage: bash leastudios-dev-tools/bin/check-handbook.sh <path-to-handbook>
#
# Required section TITLES (numbering is renumbered per-plugin so ignored):
#   Overview, Architecture, Development Setup, Hooks Reference,
#   Hook Execution Order, Testing, Release Process, Where to Read More
#
# Exits 0 if all required sections present, 1 otherwise.

set -euo pipefail

handbook="${1:-}"
if [[ -z "$handbook" || ! -f "$handbook" ]]; then
  echo "usage: $0 <path-to-developer-handbook.md>" >&2
  exit 2
fi

required=(
  "Overview"
  "Architecture"
  "Development Setup"
  "Hooks Reference"
  "Hook Execution Order"
  "Testing"
  "Release Process"
  "Where to Read More"
)

missing=()
for section in "${required[@]}"; do
  # Match "## N. Section Name" or "## Section Name" — N may be any digits.
  if ! grep -Eq "^## ([0-9]+\. )?${section}( |$)" "$handbook"; then
    missing+=("$section")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "FAIL: $handbook is missing required section(s):" >&2
  for s in "${missing[@]}"; do
    echo "  - $s" >&2
  done
  exit 1
fi

echo "OK: $handbook has all 8 required sections."
```

- [ ] **Step 2: Make the script executable and verify it works against the template**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
chmod +x bin/check-handbook.sh
bash bin/check-handbook.sh docs/developer-handbook-template.md
```

Expected: `OK: docs/developer-handbook-template.md has all 8 required sections.`

- [ ] **Step 3: Verify the script catches a missing section**

```bash
cp docs/developer-handbook-template.md /tmp/bad-handbook.md
sed -i.bak '/^## 12\. Testing/,/^## 13/d' /tmp/bad-handbook.md
bash bin/check-handbook.sh /tmp/bad-handbook.md || echo "(non-zero exit as expected)"
rm /tmp/bad-handbook.md /tmp/bad-handbook.md.bak
```

Expected output includes `FAIL` and `- Testing`, followed by `(non-zero exit as expected)`.

- [ ] **Step 4: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
git add bin/check-handbook.sh
git commit -m "docs: add handbook section-presence checker script"
```

---

## Task 3 — Task 5: Write three "new handbook" pairs

Tasks 3–5 each cover one plugin from scratch. They share the same shape:
**audit → draft → verify → commit**. The variance between plugins is captured
in the "Plugin-specific archaeology" sub-step.

For every handbook in Tasks 3–5, the executor MUST:

1. Read the spec section 5 (per-hook entry template), section 6 (REST template),
   section 7 (recipes template), section 8 (public PHP API template),
   section 9 (hook execution order template). The template doc from Task 1
   shows these in context.
2. Copy `leastudios-dev-tools/docs/developer-handbook-template.md` to
   `<plugin>/docs/developer-handbook.md`.
3. Replace every `<placeholder>` with concrete content discovered during audit.
4. Delete sections that don't apply (per the surface audit numbers).
5. Renumber surviving sections sequentially.
6. Run `bash leastudios-dev-tools/bin/check-handbook.sh <plugin>/docs/developer-handbook.md`
   and resolve failures.
7. Commit.

The plugin-specific differences are below.

---

## Task 3: leastudios-payments handbook

**Plugin path:** `wp-content/plugins/leastudios-payments`
**Surface area:** 21 hooks, 7 REST routes, 0 CLI commands.
**Sections to ship:** 1–8, 10 (Public PHP API — has Stripe-related classes), 11 (Recipes — Stripe is rich enough for many), 12–14. Skip section 9 (CLI).

- [ ] **Step 1: Audit hooks**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u
```

Expected: a list of 21 distinct hook names, all prefixed `leastudios_payments_`. Record this list — every name needs an H4 entry in the handbook's Section 6.

Group the hook names by subject. Candidate subjects (the executor chooses based on what the names actually cover): `Checkout`, `Webhook`, `Subscription`, `Refund`, `Admin`, `Settings`. **Rule from the spec:** at least 2 hooks per subject group; if a hook is the only one in its category, fold it into the nearest larger group.

- [ ] **Step 2: Audit REST routes**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
grep -rEn "register_rest_route" src/
```

For each match, open the file and capture: namespace, route, methods, `permission_callback`, args schema, response shape. These populate Section 8 (REST API Reference) — one row per route in the summary table, one detail block per route.

- [ ] **Step 3: Audit public PHP API**

Read `src/Plugin.php`. Note which classes are constructed at init time. Then:

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
grep -rEn "^(abstract )?class |^interface " src/
```

Classify each class:
- **Public** (document in Section 10): classes referenced by name in any hook signature or doc example; classes implementing an extension contract (e.g. a `Payment_Provider` interface if one exists).
- **Internal** (do not document): controllers, repositories, services constructed only by `Plugin.php`.

If no class meets the "public" bar, delete Section 10 from the handbook.

- [ ] **Step 4: Audit data model**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
grep -rEn "dbDelta|CREATE TABLE|update_option\(|update_post_meta\(" src/ | head -50
ls src/Database/ 2>/dev/null
```

Capture: custom table names + column lists (from `Database/Migration.php`), option keys, meta keys that extenders might reasonably read/write. Populate Section 5.

- [ ] **Step 5: Draft the handbook**

Copy the template and fill it in:

```bash
cp /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools/docs/developer-handbook-template.md \
   /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments/docs/developer-handbook.md
```

Then edit in place using the audit findings:
- Section 1 Overview: draw from the plugin's `README.md` lead paragraph + `CLAUDE.md` "What this plugin is" section. Cap at 300 words.
- Section 2 Architecture: summarize from the plugin's `CLAUDE.md` "Architecture" section. Include a fenced ASCII diagram showing checkout flow → webhook → log.
- Section 3 Development Setup: copy the standard composer block; mention `leastudios-mailer` is needed to exercise payment-email integration if applicable.
- Section 4 Concepts: only include if there are jargon terms (e.g. "checkout session" vs "payment intent"). Otherwise delete.
- Section 5 Data Model: from Step 4 audit.
- Section 6 Hooks Reference: one H4 per hook, grouped by the subjects identified in Step 1. Filters before actions in each group. Realistic example for each — no `// do stuff` stubs.
- Section 7 Hook Execution Order: ASCII diagram of the checkout-success path, then a summary table.
- Section 8 REST API Reference: route summary table + one detail block per route.
- Section 10 Public PHP API: from Step 3 audit. Delete if empty.
- Section 11 Extension Recipes: target 5–8 recipes. Suggested titles to consider:
  - "How do I add a custom field to checkout?"
  - "How do I send checkout completion to a CRM?"
  - "How do I block specific countries at checkout?"
  - "How do I send a custom webhook event downstream?"
  - "How do I read a successful payment from another plugin?"
  - The executor picks the ones the actual hooks support — do not invent recipes that require hooks that don't exist.
- Section 12 Testing: standard composer-test block.
- Section 13 Release Process: copy the canonical block from the template.
- Section 14 Where to Read More: link to this plugin's CLAUDE.md, README, dev-tools CLAUDE.md, and the sibling-plugin handbooks for `leastudios-mailer` and `leastudios-email-templates` (the two it integrates with).

- [ ] **Step 6: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md
```

Expected: `OK: docs/developer-handbook.md has all 8 required sections.`

Then sanity-check hook coverage:

```bash
expected=$(grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u | wc -l)
documented=$(grep -cE "^#### \`leastudios_payments_" docs/developer-handbook.md)
echo "expected=$expected documented=$documented"
```

Expected: `expected` and `documented` are equal. If `documented < expected`, identify which hook names are missing entries and add them.

- [ ] **Step 7: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-payments
git add docs/developer-handbook.md
git commit -m "docs: add developer handbook"
```

---

## Task 4: leastudios-email-templates handbook

**Plugin path:** `wp-content/plugins/leastudios-email-templates`
**Surface area:** 12 hooks, 2 REST routes, 6 CLI commands.
**Sections to ship:** 1–8, 9 (CLI — yes, this plugin has 6 commands), 10 (Public API — likely the template-rendering class), 11–14. Section 4 (Concepts) likely useful — "template", "merge tag", "transactional event" are domain terms.

- [ ] **Step 1: Audit hooks, REST, CLI, and public API**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-email-templates

echo "--- Hooks (12 expected) ---"
grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u

echo "--- REST (2 expected) ---"
grep -rEn "register_rest_route" src/

echo "--- CLI (6 expected) ---"
grep -rEn "WP_CLI::add_command|class_exists\\( 'WP_CLI'" src/

echo "--- Public classes ---"
grep -rEn "^(abstract )?class |^interface " src/
```

Record each list. Group hooks by subject (likely candidates: `Template`, `Rendering`, `Merge Tag`, `Send`).

- [ ] **Step 2: Audit data model**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-email-templates
grep -rEn "dbDelta|CREATE TABLE|register_post_type" src/
ls src/Database/ 2>/dev/null
```

Templates may be stored as a custom post type or a custom table — capture whichever applies.

- [ ] **Step 3: Draft the handbook**

```bash
cp /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools/docs/developer-handbook-template.md \
   /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-email-templates/docs/developer-handbook.md
```

Fill in following the same per-section guidance as Task 3, with these plugin-specific notes:

- Section 4 Concepts: define "template", "merge tag", and any other domain term the executor finds repeating in `src/` or `CLAUDE.md`.
- Section 6: 12 hooks across ~3 subject groups.
- Section 9 WP-CLI Commands: one H3 per command. From each `WP_CLI::add_command()` call site, capture the command name, options (look at the `synopsis` array or the callback's reflection), and write a realistic example.
- Section 11 Recipes: 5–6 candidates. Suggested:
  - "How do I add a custom merge tag?"
  - "How do I send a transactional email from another plugin?"
  - "How do I add a new template type?"
  - "How do I override the default template wrapper?"
  - "How do I preview a rendered template programmatically?"
- Section 14: link to `leastudios-mailer` handbook (the SES backend) and `leastudios-payments` (a known consumer of payment-event templates).

- [ ] **Step 4: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-email-templates
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md

expected_hooks=$(grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u | wc -l)
documented_hooks=$(grep -cE "^#### \`leastudios_email_templates_" docs/developer-handbook.md)
echo "hooks: expected=$expected_hooks documented=$documented_hooks"

expected_cli=$(grep -rEcn "WP_CLI::add_command" src/ | awk -F: '{s+=$NF} END {print s}')
documented_cli=$(grep -cE "^### \`wp " docs/developer-handbook.md)
echo "cli: expected=$expected_cli documented=$documented_cli"
```

Expected: section-presence check passes; hook count matches; CLI count matches.

- [ ] **Step 5: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-email-templates
git add docs/developer-handbook.md
git commit -m "docs: add developer handbook"
```

---

## Task 5: leastudios-siteaudit handbook (minimal)

**Plugin path:** `wp-content/plugins/leastudios-siteaudit`
**Surface area:** 2 hooks, 0 REST, 0 CLI.
**Sections to ship:** 1, 2, 3, 5 (if any data model), 6 (just 2 hooks), 7, 12, 13, 14. **Delete sections** 4, 8, 9, 10, 11 — the surface is too narrow.

A minimal handbook is fine and expected here. Aim for ~150 lines, not 500.

- [ ] **Step 1: Audit hooks and data model**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-siteaudit

echo "--- Hooks (2 expected) ---"
grep -rEn "apply_filters\(|do_action\(" src/

echo "--- Data ---"
grep -rEn "dbDelta|CREATE TABLE|register_post_type|update_option\(" src/ | head -20
```

For each hook, open the call site and capture the parameters and surrounding context.

- [ ] **Step 2: Draft the handbook**

```bash
cp /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools/docs/developer-handbook-template.md \
   /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-siteaudit/docs/developer-handbook.md
```

After filling in sections 1–3, 5, 6, 7, 12, 13, 14, **delete entire** sections 4, 8, 9, 10, 11 (concepts, REST, CLI, public PHP API, recipes). Renumber sequentially so the surviving sections are 1..9.

Section 6 will have just one subject group (probably `Audit Hooks` or similar) with 2 entries. That's fine — minimum group size of 2 is met.

Section 7's diagram can be 4 lines long. That's also fine — the section is required even when small.

- [ ] **Step 3: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-siteaudit
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md
```

Expected: passes.

- [ ] **Step 4: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-siteaudit
git add docs/developer-handbook.md
git commit -m "docs: add developer handbook"
```

---

## Task 6: leastudios-helpscout-ai-dashboard handbook

**Plugin path:** `wp-content/plugins/leastudios-helpscout-ai-dashboard`
**Surface area:** 0 hooks, 6 REST routes, 2 CLI commands.
**Sections to ship:** 1, 2, 3, 4 (probably — AI/Help Scout has jargon), 5, 8 (REST), 9 (CLI), 10 (likely public API for AI provider classes), 12–14. **Delete sections** 6, 7, 11 — no hooks means no hook reference, no execution order, and recipes would have nothing to combine.

This is an interesting edge case: the canonical template has Hooks Reference as ★ required, but if a plugin has zero hooks, an "empty hooks reference" is worse than no section. **Amend the spec inline** as we go: a plugin with literally zero `apply_filters`/`do_action` calls may omit sections 6 and 7. Document this exception in the handbook itself with a one-line note in Section 2: "*This plugin exposes no PHP hooks; integration is REST-only.*"

- [ ] **Step 1: Audit REST, CLI, public API, data model**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-helpscout-ai-dashboard

echo "--- Confirm zero hooks ---"
grep -rEn "apply_filters\(|do_action\(" src/ || echo "(none)"

echo "--- REST (6 expected) ---"
grep -rEn "register_rest_route" src/

echo "--- CLI (2 expected) ---"
grep -rEn "WP_CLI::add_command" src/

echo "--- Public classes ---"
grep -rEn "^(abstract )?class |^interface " src/

echo "--- Data ---"
grep -rEn "dbDelta|CREATE TABLE|register_post_type" src/
```

If the hook grep returns any results (i.e. the prior surface audit was wrong), STOP and add sections 6+7 back in. Otherwise proceed with the exception above.

- [ ] **Step 2: Draft the handbook**

```bash
cp /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools/docs/developer-handbook-template.md \
   /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-helpscout-ai-dashboard/docs/developer-handbook.md
```

Per-section guidance:

- Section 1: emphasize this is a Help Scout integration with AI-assisted ticket triage.
- Section 2: include the line `*This plugin exposes no PHP hooks; integration is REST-only.*`
- Section 4 Concepts: define "conversation", "mailbox", "AI provider" if these are recurring terms in the codebase.
- Section 8 REST: 6 detailed route blocks. Include request body schemas (likely JSON with AI prompts/responses).
- Section 9 CLI: 2 commands.
- Section 10 Public PHP API: likely a `AI_Provider` interface or similar. Include if found.
- **Delete** sections 6 and 7.

- [ ] **Step 3: Verify (with exception)**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-helpscout-ai-dashboard
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md
```

This **will fail** with missing `Hooks Reference` and `Hook Execution Order`. That is expected for this plugin. The executor must:
1. Confirm the failure is exactly those two sections (no others).
2. Confirm the audit in Step 1 returned zero hooks.
3. Proceed to commit — the section-presence checker is a guardrail, not a hard gate. The exception is documented in Section 2 of the handbook itself.

- [ ] **Step 4: Update the checker script to support this exception**

To prevent the failure from being noise for future runs, update `leastudios-dev-tools/bin/check-handbook.sh` to skip the hooks sections if the handbook contains the exact line `This plugin exposes no PHP hooks; integration is REST-only.`:

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
```

Edit `bin/check-handbook.sh` to add this block just before the `for section in "${required[@]}"` loop:

```bash
# Allow no-hooks plugins to opt out of the hooks sections.
if grep -Fq "This plugin exposes no PHP hooks; integration is REST-only." "$handbook"; then
  required=(${required[@]/Hooks Reference})
  required=(${required[@]/Hook Execution Order})
fi
```

Then re-run the verification:

```bash
bash bin/check-handbook.sh ../leastudios-helpscout-ai-dashboard/docs/developer-handbook.md
```

Expected: passes.

Also re-verify the template doc still passes (it does have those sections):

```bash
bash bin/check-handbook.sh docs/developer-handbook-template.md
```

Expected: passes.

- [ ] **Step 5: Commit (two repos)**

The checker change is in `leastudios-dev-tools`; the handbook is in `leastudios-helpscout-ai-dashboard`. Two commits, two repos.

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
git add bin/check-handbook.sh
git commit -m "docs: support no-hooks opt-out in handbook checker"

cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-helpscout-ai-dashboard
git add docs/developer-handbook.md
git commit -m "docs: add developer handbook"
```

---

## Task 7: Decide whether to write leastudios-dev-tools handbook

**Plugin path:** `wp-content/plugins/leastudios-dev-tools`
**Surface area:** 0 hooks, 0 REST, 0 CLI.

`leastudios-dev-tools` is not a plugin — it ships scaffolding, shared scripts (`bin/install-wp-tests.sh`, `bin/check-shared.sh`, `bin/package.sh`), and the `_boilerplate/` template directory. Its "users" are developers of sibling plugins, and its content is already covered by:
- `leastudios-dev-tools/CLAUDE.md` (the mother CLAUDE.md)
- `leastudios-dev-tools/README.md`
- The new `docs/developer-handbook-template.md` from Task 1

A developer handbook for `leastudios-dev-tools` would either duplicate the mother CLAUDE.md or document the `bin/*.sh` scripts — which are dev-suite tools, not extension surface.

- [ ] **Step 1: Decision check**

The executor's job here is to **decide** whether to write a handbook for `leastudios-dev-tools`, not to default to writing one. Re-run the surface audit:

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools

echo "--- Hooks ---"; grep -rEn "apply_filters\(|do_action\(" src/ 2>/dev/null || echo "(none)"
echo "--- REST ---"; grep -rEn "register_rest_route" src/ 2>/dev/null || echo "(none)"
echo "--- CLI ---"; grep -rEn "WP_CLI::add_command" src/ 2>/dev/null || echo "(none)"
echo "--- src/ ---"; ls src/ 2>/dev/null || echo "(no src/)"
echo "--- bin/ scripts ---"; ls bin/
```

- [ ] **Step 2: If genuinely zero surface, append a justification to this plan**

If all three audits return zero AND `src/` either doesn't exist or contains only shared-by-duplication classes already documented elsewhere, **do not create a handbook**. Instead, append the following block to this plan's "Out of scope" tail at the bottom and commit:

```markdown
## Justification: no handbook for leastudios-dev-tools

Surface audit on <DATE> found zero hooks, REST routes, CLI commands, and
no plugin-style extension surface in `src/`. The repo's content is covered by:
- `CLAUDE.md` (mother CLAUDE.md for the whole suite)
- `README.md` (suite-tooling overview)
- `docs/developer-handbook-template.md` (the canonical template for sibling plugins)
- `bin/*.sh` (release scaffolding, used directly from sibling plugin Makefiles/CI)

Writing a fourth doc would duplicate the first three. Decision: skip.
```

Then:

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-dev-tools
git add docs/superpowers/plans/2026-05-23-developer-handbook-rollout.md
git commit -m "docs: justify skipping leastudios-dev-tools handbook"
```

- [ ] **Step 3: Otherwise (surface found), write a minimal handbook**

If the audit DID surface anything (e.g. an `apply_filters` was added to a shared class after this plan was written), produce a minimal handbook covering only the found surface — same shape as Task 5 (siteaudit). Then commit.

---

## Task 8: Upgrade leastudios-forms handbook

**Plugin path:** `wp-content/plugins/leastudios-forms`
**Existing state:** 747-line handbook with sections "Render Hooks", "Submission Hooks", "Notification Hooks", "Admin Hooks", "Registration Hooks", "Hook Execution Order (Submission Flow)" — closest to canonical of the three existing handbooks.
**Gaps to fill:** Add sections 1, 2, 3, 5 (Data Model), 7 (currently has the order list but not a diagram + summary table together — it has the list but no ASCII diagram), 8 (REST), 10 (Public PHP API — the `Field_Type` interface), 11 (Recipes), 12, 13, 14. Add a `Since:` row to every existing hook entry. Preserve all existing hook content; do not rewrite the existing hook entries beyond adding `Since`.

- [ ] **Step 1: Capture the current handbook's structure**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-forms
grep -nE "^## |^### " docs/developer-handbook.md
```

Confirm the existing H2/H3 outline matches the spec's hook-reference shape (subject-grouped, filters/actions inside).

- [ ] **Step 2: Audit gaps to fill**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-forms

echo "--- REST routes ---"
grep -rEn "register_rest_route" src/

echo "--- Public PHP API candidates ---"
grep -rEn "^interface |^abstract class " src/

echo "--- Data model ---"
grep -rEn "dbDelta|CREATE TABLE|register_post_type" src/
```

The forms plugin has at least:
- Custom post type `leastudios_form` (registered in `src/CPT/Form_Post_Type.php`).
- Custom table `{prefix}leastudios_forms_entries` (per `CLAUDE.md`).
- `Field_Type` interface in `src/Field/Field_Type.php`.
- REST endpoint `POST /wp-json/leastudios-forms/v1/submissions` (per `CLAUDE.md`).

- [ ] **Step 3: Restructure the handbook**

Reorganize the existing file as follows. **Heading-depth note:** after restructuring, the file's heading hierarchy is `# Title` → `## N. Section` → `### Subject Group` (inside Section 6) → `#### hook_name`. The current handbook uses `## Subject Group` → `### hook_name`, so each subject group H2 demotes to H3 and each hook H3 demotes to H4.

1. **Keep** the existing H1 title and the lead paragraph.
2. **Replace** the existing TOC with a (renumbered after deletions) TOC.
3. **Insert** new Section 1 (Overview), Section 2 (Architecture), Section 3 (Development Setup), Section 4 (Concepts — likely "form", "field type", "entry", "notification"), Section 5 (Data Model — the CPT + the entries table) **before** the existing hook reference.
4. **Wrap** the existing hook content in a new H2 `## 6. Hooks Reference`. Demote every existing `## <Something> Hooks` to `### <Something> Hooks`, and every `### leastudios_forms_*` to `#### leastudios_forms_*`. A sed-style pass works (verify by diffing before/after):

   ```bash
   # Inside docs/developer-handbook.md, for the hook-reference block only:
   #   '## Render Hooks'               → '### Render Hooks'
   #   '### `leastudios_forms_…`'      → '#### `leastudios_forms_…`'
   ```

   Do this by hand or with a careful `sed`/editor pass scoped to just that block (do not demote the H2s for sections 1-5 you just added or the later sections 7+).

5. **Augment** the existing hook entries: for every `#### leastudios_forms_*` entry (now H4), add a `- **Since:** <version>` bullet between the existing `**Location:**` and `**Description:**` lines. Use the plugin's current `Version:` header from `leastudios-forms.php` — handbook-known hooks predate version-tracking and there's no point archaeologizing git history for the introduction commit.
6. **Replace** the existing "Hook Execution Order (Submission Flow)" section (currently a numbered prose list) with the canonical Section 7 shape: ASCII diagram (showing `pre_wp_mail → spam → sanitize → validate → entry → notify → response`) **plus** the existing numbered list converted into the canonical "| Order | Hook | Type | Trigger |" table.
7. **Add** Section 8 (REST API Reference) — one route currently: `POST /wp-json/leastudios-forms/v1/submissions`.
8. **Add** Section 10 (Public PHP API) documenting the `LEAStudios\Forms\Field\Field_Type` interface. Cross-reference the existing `leastudios_forms_field_types` hook entry.
9. **Add** Section 11 (Extension Recipes). Promote the existing custom-field-type example from the `leastudios_forms_field_types` hook entry into a recipe ("How do I register a custom field type?"). Add ~4 more recipes the existing hooks support:
   - "How do I send form submissions to a CRM?" (uses `submission_created` + `entry_data`)
   - "How do I block free-email providers on a form?" (uses `validation_errors`)
   - "How do I add a CC/BCC header to notification emails?" (uses `notification_args`)
   - "How do I add a custom entry-detail action button?" (uses `entry_actions`)
10. **Add** Sections 12, 13, 14 — boilerplate from the template.

- [ ] **Step 4: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-forms
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md

# Hook count must not regress. Note H4 after restructure.
hook_entries=$(grep -cE "^#### \`leastudios_forms_" docs/developer-handbook.md)
echo "hook entries: $hook_entries (must be >= 20)"

# Every hook entry must now have a Since row.
without_since=$(awk '/^#### `leastudios_forms_/{capture=1; name=$0; next} capture && /^- \*\*Since:\*\*/{capture=0} capture && /^---/{print name; capture=0}' docs/developer-handbook.md)
test -z "$without_since" && echo "OK: every hook has Since" || { echo "FAIL: missing Since on:"; echo "$without_since"; }
```

Expected: all three checks pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-forms
git add docs/developer-handbook.md
git commit -m "docs: upgrade developer handbook to canonical shape"
```

---

## Task 9: Upgrade leastudios-mailer handbook

**Plugin path:** `wp-content/plugins/leastudios-mailer`
**Existing state:** 489-line handbook with Filters / Actions / Hook Execution Order / Attachments. No TOC. Bullet-style parameter lists.
**Gaps to fill:** Add TOC, sections 1, 2, 3, 5 (Data Model — log table), 7 (currently is a numbered list but no diagram), 8 (REST — the SNS webhook), 11 (Recipes), 12, 13, 14. Add `Since:` rows. Convert bullet-style parameter lists to the canonical parameter table. Reorganize Filters/Actions into subject groups (`Send Pipeline`, `SES Request`, `Webhook`, `Admin`, etc.). Preserve the existing "Attachments" cross-cutting section by folding it into Section 2 (Architecture) or making it part of Section 11 (Recipes — "How do I send a custom email with attachments?").

- [ ] **Step 1: Capture current structure**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-mailer
grep -nE "^## |^### |^#### " docs/developer-handbook.md
```

Confirm the existing layout (Filters section with H4 hook entries, Actions section, Hook Execution Order, Attachments).

- [ ] **Step 2: Plan the subject grouping**

The current Filters section has 14 hooks; Actions has 5. Group them by subject:
- **Send pipeline**: `should_intercept`, `pre_send`, `email_sent`, `attachments_skipped`, `before_log`
- **SES request**: `ses_request_body`, `ses_raw_request_body`, `max_message_bytes`, `ses_max_attempts`, `ses_retry_delay_ms`, `ses_response`
- **SNS webhook**: `sns_max_age_seconds`, `sns_future_skew_seconds`, `sns_rate_limit`, `sns_rate_window_seconds`
- **Admin**: `settings_tabs`, `settings_tab_{$slug}`
- **Lifecycle**: `initialized`

In each group: filters first, then actions (so `before_log` (filter) appears before `email_sent` (action) within Send pipeline).

- [ ] **Step 3: Restructure**

1. **Add** a TOC after the H1.
2. **Insert** Sections 1, 2, 3, 4 (Concepts — "send pipeline", "SES SigV4", "SNS notification" are jargon worth defining), 5 (Data Model — the `{prefix}leastudios_mailer_log` table).
3. **Replace** the existing "Filters" + "Actions" H2 split with subject-group H2s per Step 2 above. Each hook entry: convert from bullet-style to the canonical Forms-style (bullets for Type/Location/Since/Description, then parameter **table**, then Returns line for filters, then example).
4. **Replace** the existing "Hook Execution Order" prose with: ASCII diagram + summary table.
5. **Add** Section 8 — REST API Reference. The mailer registers one route under `leastudios-mailer/v1/sns-webhook`; document it.
6. **Move** the existing "Attachments" section into Section 11 (Recipes) as a recipe titled "How do I send an attachment-bearing email through the mailer?" — keep the content, just reframe it.
7. **Add** Sections 12, 13, 14 from the template.

- [ ] **Step 4: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-mailer
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md

# Hook count regression check
expected=$(grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u | wc -l)
documented=$(grep -cE "^#### \`leastudios_mailer_" docs/developer-handbook.md)
echo "hooks: expected=$expected documented=$documented"
```

Expected: section-presence passes; hook count matches.

- [ ] **Step 5: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-mailer
git add docs/developer-handbook.md
git commit -m "docs: upgrade developer handbook to canonical shape"
```

---

## Task 10: Upgrade leastudios-snippets handbook

**Plugin path:** `wp-content/plugins/leastudios-snippets`
**Existing state:** 761-line handbook with `Filters` / `Actions` / `Snippet Library -- Adding Custom Snippets Programmatically` / `Hook Execution Order`. Has `Since:` rows already.
**Gaps to fill:** Reorganize hook section from type-based to subject-based. Add sections 1, 2, 3, 4 (Concepts — "snippet location", "safe mode", "condition" are jargon), 5 (Data Model — the CPT + meta keys, the safe-mode option, the active-IDs cache key), 8 (only if REST exists), 11 (Recipes — promote "Adding Custom Snippets Programmatically" into one recipe + split into several). Convert "Detail | Value" mini-tables to canonical bullet metadata + parameter table.

- [ ] **Step 1: Capture current structure and verify subject grouping is feasible**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-snippets
grep -nE "^## |^### " docs/developer-handbook.md
grep -rEn "register_rest_route" src/ 2>/dev/null || echo "(no REST)"
```

Plan subject groups for the 13 hooks:
- **Execution**: `should_execute`, `before_execute`, `after_execute`, `output`, `php_error`, `condition_result`
- **Post type & locations**: `locations`, `post_type_args`, `editing_disabled`
- **Library**: `library_snippets`, `before_library_install`, `after_library_install`
- **Lifecycle**: `initialized`

- [ ] **Step 2: Convert the per-hook entry style**

The current entries use:

```markdown
### `leastudios_snippets_should_execute`

Control whether a specific snippet should be executed. …

| Detail | Value |
|---|---|
| **Type** | Filter |
| **File** | `src/Execution/Snippet_Executor.php` |
| **Since** | 1.0.0 |

#### Parameters

| Parameter | Type | Description |
| … |
```

Convert each to the canonical:

```markdown
#### `leastudios_snippets_should_execute`

- **Type:** Filter
- **Location:** `src/Execution/Snippet_Executor.php`
- **Since:** 1.0.0
- **Description:** Control whether a specific snippet should be executed. …

**Parameters:**

| Parameter | Type | Description |
| … |
```

Note the H3 → H4 promotion (subject group is H3 in the canonical layout? — no, the spec says subject groups are H2 and hooks are H3 inside a single Section 6 H2. **Re-read the spec.** Spec Section 5: "Each group gets an H2 (`## Submission Hooks`); each hook is an H3."

But Section 6 of the handbook is `## 6. Hooks Reference` (H2). So subjects under that need to be H3, and hooks H4.

**Authoritative rule for this plan**: subject groups are H3 inside the Section-6 H2; hook entries are H4. Update both this task and Tasks 3, 4, 8, 9 mentally if you executed them with H2/H3. Re-verify Tasks 3 and 4 by running:

```bash
grep -nE "^### |^#### " <plugin>/docs/developer-handbook.md | head -30
```

and check that subject groups are `###` and hook names are `####`.

- [ ] **Step 3: Restructure**

1. **Update TOC** to list 14 (minus deletions) renumbered sections.
2. **Add** Sections 1, 2, 3, 4, 5 before the existing hook reference.
3. **Replace** existing `## Filters` + `## Actions` with a single `## 6. Hooks Reference`, with subject-group H3s underneath.
4. **Convert** every hook entry from "Detail | Value" mini-table to canonical bullet metadata + parameter table. Preserve the existing prose and examples verbatim.
5. **Replace** the existing ASCII flow diagram + summary table in `Hook Execution Order` (already very close to canonical — just renumber and reformat the H2).
6. **Restructure** the existing "Snippet Library -- Adding Custom Snippets Programmatically" section into Section 11 (Recipes), split into multiple recipes:
   - "How do I add a single custom snippet to the library?"
   - "How do I bulk-add library snippets from a plugin?"
   - "How do I add snippets that require a specific sibling plugin?"
   - "How do I remove a built-in library snippet?"
   - "How do I install a library snippet programmatically?"
   These already exist as sub-sections; promote each to a recipe with the canonical "Goal / Hooks used / Walkthrough / Example" shape.
7. **Add** Sections 12, 13, 14 from the template.

- [ ] **Step 4: Verify**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-snippets
bash ../leastudios-dev-tools/bin/check-handbook.sh docs/developer-handbook.md

expected=$(grep -rEn "apply_filters\(|do_action\(" src/ | sed -E "s/.*(apply_filters|do_action)\( *['\"]([^'\"]+).*/\2/" | sort -u | wc -l)
documented=$(grep -cE "^#### \`leastudios_snippets_" docs/developer-handbook.md)
echo "hooks: expected=$expected documented=$documented"
```

Expected: section-presence passes; hook count matches the audit.

- [ ] **Step 5: Commit**

```bash
cd /Users/adamlea/Herd/leastudios-plugins/wp-content/plugins/leastudios-snippets
git add docs/developer-handbook.md
git commit -m "docs: upgrade developer handbook to canonical shape"
```

---

## Self-Review Notes (from plan author)

After writing this plan, I checked it against the spec:

- **Spec coverage:** Every deliverable in Section 10 of the spec has a task. Template doc = Task 1. Checker = Task 2 (not in spec — added because spec Section 4 implies enforcement via "renumber sequentially" without saying how to verify; this is a small lightweight enforcement). 5 new handbooks = Tasks 3, 4, 5, 6, 7. 3 upgrades = Tasks 8, 9, 10.
- **Heading-depth correction caught:** Task 10 Step 2 caught a heading-depth inconsistency in this plan's earlier tasks (the spec says subject groups are H2 / hooks are H3, but inside a `## Hooks Reference` H2 that makes subjects H3 and hooks H4). The correction is documented in Task 10 with a re-verify step. Earlier tasks (3, 4, 8, 9) refer to the corrected depth.
- **Section omission rules followed:** Tasks 5, 6, 7 explicitly enumerate which sections to delete. Task 6 introduces a documented spec exception (no-hooks plugin omits sections 6+7) and a checker-script change to accommodate it.
- **No placeholder steps:** every `Step N` either runs a concrete command, shows concrete code/markdown to write, or describes a decision with a concrete output (the justification block in Task 7).
- **Frequent commits:** every task ends in a commit. Task 6 ends in two commits across two repos.

---

## Out of scope (carried from spec)

- Translating handbooks.
- Generating handbooks from code (no `@hook` PHPDoc parsing).
- Restructuring CLAUDE.md or README.md.
- A single shared handbook for the whole suite.

---

## Justification: no handbook for leastudios-dev-tools

Surface audit on 2026-05-24 found:
- 0 `apply_filters` / `do_action` calls in `src/`.
- 0 `register_rest_route` calls in `src/`.
- 0 `WP_CLI::add_command` calls in `src/`.
- `src/` directory: does not exist.
- `bin/` scripts: `check-handbook.sh`, `check-shared.sh`, `git-hooks/`, `install-hooks.sh`, `install-wp-tests.sh`, `package.sh`.
- Top-level dirs: `_boilerplate/`, `config-templates/`, `docs/`, plus `CLAUDE.md`, `CODE_REVIEW.md`, `README.md`.

`leastudios-dev-tools` ships scaffolding (`_boilerplate/`), release/CI scripts in `bin/`, the mother CLAUDE.md, and (now) the canonical developer-handbook template + spec + plan. None of this is "extension surface" — it is internal suite tooling consumed via copy-paste (`_boilerplate`) or direct invocation (`bin/*.sh`). The content that a developer needs is already covered by:

- `CLAUDE.md` (mother CLAUDE.md for the whole suite)
- `README.md` (suite-tooling overview)
- `docs/developer-handbook-template.md` (the canonical template for sibling plugins)
- `bin/*.sh` (release scaffolding, used directly from sibling plugin Makefiles/CI)

Writing a fourth doc would duplicate the first three. Decision: skip.
