# Suite-wide CI Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add GitHub Actions CI to the five `leastudios-*` plugins that lack it, standardize each on a PHP 8.2 floor, and seed CI into the new-plugin boilerplate.

**Architecture:** Replicate the proven `leastudios-forms` CI workflow into each plugin's own git repository, pinning `config.platform.php` so `composer.lock` is installable on the floor. Each plugin gets a standalone `ci.yml` (no shared/reusable workflow). One pilot plugin (`leastudios-mailer`) is taken end-to-end first; the remaining four follow as independent parallel tasks. A tokenized `ci.yml` is added to the dev-tools boilerplate so future plugins inherit CI.

**Tech Stack:** GitHub Actions, Composer 2.x, PHP 8.2/8.4, PHPUnit 9.6, PHPCS (WordPress Coding Standards), PHPStan 2.x, WordPress test library.

---

## Plan Constants

These are referenced by every task. They are defined once here and are always in view regardless of task read order. Each plugin task is self-contained by combining these constants with its own parameter table.

### Constant A — `ci.yml` workflow content

Create the file `.github/workflows/ci.yml` with the content below, replacing every occurrence of the token `PLUGIN_SLUG` with the plugin's directory/repo name (e.g. `leastudios-mailer`). The token appears **4 times**: the `Check out PLUGIN_SLUG` step name, one `path:`, and two `working-directory:`.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    name: Lint (PHPCS + PHPStan)
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          coverage: none

      - name: Install Composer dependencies
        uses: ramsey/composer-install@v3

      - name: Run PHPCS
        run: composer phpcs

      - name: Run PHPStan
        run: composer phpstan

  test:
    name: Tests (PHP ${{ matrix.php }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php: ['8.2', '8.4']
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping --silent"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=10
    steps:
      - name: Check out PLUGIN_SLUG
        uses: actions/checkout@v4
        with:
          path: PLUGIN_SLUG

      - name: Check out leastudios-dev-tools
        uses: actions/checkout@v4
        with:
          repository: adamjohnlea/leastudios-dev-tools
          path: leastudios-dev-tools

      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: mysqli
          coverage: none

      - name: Install Composer dependencies
        uses: ramsey/composer-install@v3
        with:
          working-directory: PLUGIN_SLUG

      - name: Install WordPress test library
        run: bash leastudios-dev-tools/bin/install-wp-tests.sh wordpress_test root root 127.0.0.1 6.8.2

      - name: Run PHPUnit
        run: composer test
        working-directory: PLUGIN_SLUG
```

The literal `leastudios-dev-tools` references stay as-is — every plugin's CI checks out the dev-tools repo to obtain `install-wp-tests.sh`.

### Constant B — the seven `8.1` → `8.2` metadata edits

Each plugin has exactly seven `8.1` references to change. All are exact-string edits. `<slug>` is the plugin name (e.g. `leastudios-mailer`); the notice string contains the plugin's human-readable name already present in the file.

| # | File | Old string | New string |
| - | ---- | ---------- | ---------- |
| 1 | `composer.json` | `"php": ">=8.1"` | `"php": ">=8.2"` |
| 2 | `composer.json` | `"sort-packages": true` | `"sort-packages": true,`<br>`        "platform": {`<br>`            "php": "8.2"`<br>`        }` |
| 3 | `<slug>.php` | `Requires PHP:      8.1` | `Requires PHP:      8.2` |
| 4 | `<slug>.php` | `version_compare( PHP_VERSION, '8.1', '<' )` | `version_compare( PHP_VERSION, '8.2', '<' )` |
| 5 | `<slug>.php` | `requires PHP 8.1 or higher.` | `requires PHP 8.2 or higher.` |
| 6 | `readme.txt` | `Requires PHP: 8.1` | `Requires PHP: 8.2` |
| 7 | `phpcs.xml.dist` | `<config name="testVersion" value="8.1-"/>` | `<config name="testVersion" value="8.2-"/>` |

**Edit #2 note:** in every target plugin, `"sort-packages": true` is the last key in the `config` object (no trailing comma). The replacement adds the comma and the new `platform` key. After editing, the `config` block must be valid JSON — the `composer update` step (Constant C) fails fast on malformed JSON. If a plugin's `config` block differs (a key follows `sort-packages`), instead insert the `platform` key with correct comma placement so the JSON stays valid.

### Constant C — local verification commands

Run from inside the plugin directory, in order. Each must succeed before committing.

```bash
composer update              # regenerates composer.lock against the 8.2 platform pin
composer lint                # PHPCS + PHPStan — expect "No errors"
composer test                # PHPUnit — expect "OK (N tests, M assertions)"
```

`composer update` is expected to change many lines in `composer.lock` (dependency versions re-resolved for the 8.2 platform). That is the intended fix for the "lock not installable on the floor" bug. The local PHP is 8.4, so `lint`/`test` still execute on 8.4 — the platform pin only constrains dependency *resolution*. If `lint` or `test` fails, stop and diagnose — do not commit a red state.

The WordPress test library is already installed at `/tmp/wordpress-tests-lib/` (shared across all plugins); `composer test` uses it via the plugin's `tests/bootstrap.php`. If `composer test` reports the library is missing, install it once with:
`bash ../leastudios-dev-tools/bin/install-wp-tests.sh wordpress_test root '' localhost latest`

### Constant D — commit, push, and open the PR

Run from inside the plugin directory. Replace `<slug>` with the plugin name (e.g. `leastudios-mailer`); everything else is byte-identical across all five plugin tasks.

```bash
git add composer.json composer.lock <slug>.php readme.txt phpcs.xml.dist .github/workflows/ci.yml
git commit -m "$(cat <<'EOF'
Add CI workflow and pin PHP 8.2 floor

Adds a GitHub Actions workflow running PHPCS, PHPStan, and PHPUnit on
PHP 8.2 and 8.4. Pins config.platform.php to 8.2 and regenerates the
lock so dependencies resolve installable on the declared floor, and
raises the declared floor from the end-of-life 8.1 to 8.2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push -u origin add-ci-workflow
gh pr create --title "Add CI workflow and pin PHP 8.2 floor" --body "$(cat <<'EOF'
## Summary
- Adds a GitHub Actions CI workflow: Lint (PHPCS + PHPStan) and Tests (PHPUnit) on PHP 8.2 and 8.4.
- Pins `config.platform.php` to `8.2` and regenerates `composer.lock` so dependencies resolve to versions installable on the declared floor.
- Raises the declared PHP floor from the end-of-life 8.1 to 8.2 across `composer.json`, the plugin header, the runtime version check, the admin notice, `readme.txt`, and `phpcs.xml.dist`.

## Test plan
- [ ] CI: Lint job green
- [ ] CI: Tests (PHP 8.2) green
- [ ] CI: Tests (PHP 8.4) green

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Constant E — verify CI is green

```bash
gh pr checks add-ci-workflow --watch
```

Expected: all three checks (`Lint (PHPCS + PHPStan)`, `Tests (PHP 8.2)`, `Tests (PHP 8.4)`) report `pass`. If any fail, diagnose and fix on the branch — a plugin task is not done until CI is green.

---

## Task 1: Pilot — leastudios-mailer

**Repository:** `leastudios-mailer` (own git repo). All commands run from `wp-content/plugins/leastudios-mailer/`.

**Parameters:** `<slug>` = `leastudios-mailer`; notice string (Constant B #5) is inside `'leaStudios Mailer requires PHP 8.1 or higher.'`; `version_compare` at `leastudios-mailer.php:53`, notice at `:71`, header at `:8`.

**Files:** Modify `composer.json`, `leastudios-mailer.php`, `readme.txt`, `phpcs.xml.dist`; create `.github/workflows/ci.yml`; `composer.lock` regenerated.

- [ ] **Step 1: Create the branch**

```bash
cd ../leastudios-mailer
git checkout main && git pull --ff-only
git checkout -b add-ci-workflow
```

Expected: `Switched to a new branch 'add-ci-workflow'`.

- [ ] **Step 2: Apply the seven metadata edits** — apply all seven edits from **Constant B** with the parameters above. After editing, `composer.json`'s `config` block reads:

```json
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true,
            "phpstan/extension-installer": true
        },
        "sort-packages": true,
        "platform": {
            "php": "8.2"
        }
    },
```

- [ ] **Step 3: Create `.github/workflows/ci.yml`** from **Constant A**, replacing `PLUGIN_SLUG` with `leastudios-mailer` (4 occurrences).

- [ ] **Step 4: Regenerate the lock and verify locally** — run the three **Constant C** commands. Do not commit a red state.

- [ ] **Step 5: Commit, push, open PR** — run **Constant D** with `<slug>` = `leastudios-mailer`.

- [ ] **Step 6: Verify CI is green** — run **Constant E**. The pilot is not done until all three checks pass. **If any recipe correction was needed to get green, update Constants A–E (and Tasks 2–5's parameters if affected) before those tasks run.**

---

## Task 2: leastudios-email-templates

**Repository:** `leastudios-email-templates` (own git repo). All commands run from `wp-content/plugins/leastudios-email-templates/`.

**Parameters:** `<slug>` = `leastudios-email-templates`; notice string (Constant B #5) is inside `'leaStudios Email Templates requires PHP 8.1 or higher.'`; `version_compare` at `leastudios-email-templates.php:93`, notice at `:111`, header at `:8`.

**Files:** Modify `composer.json`, `leastudios-email-templates.php`, `readme.txt`, `phpcs.xml.dist`; create `.github/workflows/ci.yml`; `composer.lock` regenerated.

- [ ] **Step 1: Create the branch**

```bash
cd ../leastudios-email-templates
git checkout main && git pull --ff-only
git checkout -b add-ci-workflow
```

- [ ] **Step 2: Apply the seven metadata edits** — apply all seven edits from **Constant B** with the parameters above.

- [ ] **Step 3: Create `.github/workflows/ci.yml`** from **Constant A**, replacing `PLUGIN_SLUG` with `leastudios-email-templates` (4 occurrences).

- [ ] **Step 4: Regenerate the lock and verify locally** — run the three **Constant C** commands. Do not commit a red state.

- [ ] **Step 5: Commit, push, open PR** — run **Constant D** with `<slug>` = `leastudios-email-templates`.

- [ ] **Step 6: Verify CI is green** — run **Constant E**.

---

## Task 3: leastudios-payments

**Repository:** `leastudios-payments` (own git repo). All commands run from `wp-content/plugins/leastudios-payments/`.

**Parameters:** `<slug>` = `leastudios-payments`; notice string (Constant B #5) is inside `'leaStudios Payments requires PHP 8.1 or higher.'`; `version_compare` at `leastudios-payments.php:50`, notice at `:68`, header at `:8`.

**Files:** Modify `composer.json`, `leastudios-payments.php`, `readme.txt`, `phpcs.xml.dist`; create `.github/workflows/ci.yml`; `composer.lock` regenerated.

- [ ] **Step 1: Create the branch**

```bash
cd ../leastudios-payments
git checkout main && git pull --ff-only
git checkout -b add-ci-workflow
```

- [ ] **Step 2: Apply the seven metadata edits** — apply all seven edits from **Constant B** with the parameters above.

- [ ] **Step 3: Create `.github/workflows/ci.yml`** from **Constant A**, replacing `PLUGIN_SLUG` with `leastudios-payments` (4 occurrences).

- [ ] **Step 4: Regenerate the lock and verify locally** — run the three **Constant C** commands. Do not commit a red state.

- [ ] **Step 5: Commit, push, open PR** — run **Constant D** with `<slug>` = `leastudios-payments`.

- [ ] **Step 6: Verify CI is green** — run **Constant E**.

---

## Task 4: leastudios-siteaudit

**Repository:** `leastudios-siteaudit` (own git repo). All commands run from `wp-content/plugins/leastudios-siteaudit/`.

**Parameters:** `<slug>` = `leastudios-siteaudit`; notice string (Constant B #5) is inside `'LEA Studios Site Audit requires PHP 8.1 or higher.'`; `version_compare` at `leastudios-siteaudit.php:57`, notice at `:75`, header at `:8`.

**Files:** Modify `composer.json`, `leastudios-siteaudit.php`, `readme.txt`, `phpcs.xml.dist`; create `.github/workflows/ci.yml`; `composer.lock` regenerated.

- [ ] **Step 1: Create the branch**

```bash
cd ../leastudios-siteaudit
git checkout main && git pull --ff-only
git checkout -b add-ci-workflow
```

- [ ] **Step 2: Apply the seven metadata edits** — apply all seven edits from **Constant B** with the parameters above.

- [ ] **Step 3: Create `.github/workflows/ci.yml`** from **Constant A**, replacing `PLUGIN_SLUG` with `leastudios-siteaudit` (4 occurrences).

- [ ] **Step 4: Regenerate the lock and verify locally** — run the three **Constant C** commands. `leastudios-siteaudit` has `tests/Unit` and `tests/Integration` subdirectories; `composer test` runs both. Do not commit a red state.

- [ ] **Step 5: Commit, push, open PR** — run **Constant D** with `<slug>` = `leastudios-siteaudit`.

- [ ] **Step 6: Verify CI is green** — run **Constant E**.

---

## Task 5: leastudios-snippets

**Repository:** `leastudios-snippets` (own git repo). All commands run from `wp-content/plugins/leastudios-snippets/`.

**Parameters:** `<slug>` = `leastudios-snippets`; notice string (Constant B #5) is inside `'leaStudios Snippets requires PHP 8.1 or higher.'`; `version_compare` at `leastudios-snippets.php:79`, notice at `:97`, header at `:8`.

**Files:** Modify `composer.json`, `leastudios-snippets.php`, `readme.txt`, `phpcs.xml.dist`; create `.github/workflows/ci.yml`; `composer.lock` regenerated.

- [ ] **Step 1: Create the branch**

```bash
cd ../leastudios-snippets
git checkout main && git pull --ff-only
git checkout -b add-ci-workflow
```

- [ ] **Step 2: Apply the seven metadata edits** — apply all seven edits from **Constant B** with the parameters above.

- [ ] **Step 3: Create `.github/workflows/ci.yml`** from **Constant A**, replacing `PLUGIN_SLUG` with `leastudios-snippets` (4 occurrences).

- [ ] **Step 4: Regenerate the lock and verify locally** — run the three **Constant C** commands. Do not commit a red state.

- [ ] **Step 5: Commit, push, open PR** — run **Constant D** with `<slug>` = `leastudios-snippets`.

- [ ] **Step 6: Verify CI is green** — run **Constant E**.

---

## Task 6: Seed CI into the dev-tools boilerplate

**Repository:** `leastudios-dev-tools` (own git repo). All commands run from `wp-content/plugins/leastudios-dev-tools/`. This task commits directly to `main` — no branch, no PR — consistent with how prior dev-tools tooling fixes were handled.

**Files:**
- Create: `_boilerplate/.github/workflows/ci.yml`
- Modify: `_boilerplate/composer.json`
- Modify: `_boilerplate/plugin-name.php`

- [ ] **Step 1: Confirm on main and up to date**

```bash
cd ../leastudios-dev-tools
git checkout main && git status --porcelain
```

Expected: branch `main`; the only tracked/untracked entries relate to this rollout's `docs/` (the spec and this plan). No unrelated changes.

- [ ] **Step 2: Create `_boilerplate/.github/workflows/ci.yml`**

Create the file with **Constant A**, replacing the `PLUGIN_SLUG` token with the boilerplate slug token `plugin-name` (4 occurrences). The result must contain `path: plugin-name`, `working-directory: plugin-name` (×2), and the step name `Check out plugin-name`. This token is find-replaced when a new plugin is scaffolded, exactly like the rest of `_boilerplate/`.

- [ ] **Step 3: Update `_boilerplate/composer.json`**

The boilerplate `require` block currently contains only `"php": ">=8.1"`; change it to `"php": ">=8.2"`. The boilerplate `config` block currently contains only `"sort-packages": true`; change it to:

```json
    "config": {
        "sort-packages": true,
        "platform": {
            "php": "8.2"
        }
    }
```

- [ ] **Step 4: Update `_boilerplate/plugin-name.php`**

First enumerate the references: `grep -n "8\.1" _boilerplate/plugin-name.php`. Change every `8.1` to `8.2` — expect the `Requires PHP:` header (line 8), a `version_compare( PHP_VERSION, '8.1', '<' )` guard if present, and the `'Plugin Name requires PHP 8.1 or higher.'` notice string (line 61). After editing, `grep -n "8\.1" _boilerplate/plugin-name.php` must return nothing.

- [ ] **Step 5: Commit to main**

```bash
git add _boilerplate/.github/workflows/ci.yml _boilerplate/composer.json _boilerplate/plugin-name.php
git commit -m "$(cat <<'EOF'
Seed CI workflow and PHP 8.2 floor into the plugin boilerplate

New plugins scaffolded from _boilerplate/ now inherit a GitHub Actions
CI workflow and a pinned PHP 8.2 floor (config.platform.php plus the
require constraint and version declarations).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 6: Verify the boilerplate is consistent**

```bash
grep -rn "8\.1" _boilerplate/ ; echo "exit: $?"
```

Expected: no output (`exit: 1` from grep means no matches). Any remaining `8.1` in `_boilerplate/` is a miss to fix before the task is done.

---

## Self-Review

- **Spec coverage:** Goals 1–3 (CI workflow, 8.2 floor verified, lock installable) are delivered by Tasks 1–5; goal 4 (boilerplate inherits CI) by Task 6. Pilot/batch structure, boilerplate seeding, and plan location all match the spec. Success criteria are the explicit "expected" outcomes of Constants C and E and Task 6 Step 6.
- **Spec discrepancy corrected:** the spec's recipe table listed five edit locations; writing this plan found seven (the spec omitted the `version_compare` runtime guard and the admin-notice string). Constant B carries all seven. Constant B supersedes the spec table on this point.
- **Placeholder scan:** no TBD/TODO. `PLUGIN_SLUG`, `<slug>`, and `plugin-name` are documented substitution tokens, not placeholders. All edit strings are exact.
- **Self-contained tasks:** every task references only Plan Constants (always-present preamble) plus its own parameter table — no task depends on having read another. Verified after promoting commit/PR/verify content to Constants D and E.
- **Consistency:** branch name `add-ci-workflow`, commit message, PR body, and `ci.yml` content are single Constants reused by all plugin tasks; the floor value `8.2` is uniform throughout.
