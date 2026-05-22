# Suite-wide CI rollout — design

**Date:** 2026-05-22
**Scope:** Add GitHub Actions CI to the 5 `leastudios-*` plugins that lack it, and seed CI into the new-plugin boilerplate.

## Problem

`leastudios-forms` gained a CI workflow in PR #4. Its first CI run exposed four latent bugs that local development had masked — most notably a `composer.lock` that was not installable on the plugin's declared PHP floor, and a `Requires PHP` declaration that understated the real minimum (8.1 declared, 8.2 actually required).

Five sibling plugins carry the same latent risks: none has CI, and none pins `config.platform.php`, so each has an unverified PHP floor and a `composer.lock` that may not install on it.

Affected plugins:

- `leastudios-email-templates`
- `leastudios-mailer`
- `leastudios-payments`
- `leastudios-siteaudit`
- `leastudios-snippets`

All five are structurally identical to `leastudios-forms`: the same `composer.json` scripts (`phpcs`, `phpcbf`, `phpstan`, `lint`, `test`), a `tests/` suite with `bootstrap.php` and `phpunit.xml.dist`, `require.php` of `>=8.1`, no `config.platform.php`, and a `Requires PHP: 8.1` header.

## Goals

- Every affected plugin runs Lint (PHPCS + PHPStan) and Tests (PHPUnit) on every push to `main` and every pull request.
- Each plugin's `composer.lock` is installable on its declared PHP floor.
- Each plugin's declared PHP floor matches the real minimum its source requires.
- New plugins scaffolded from the boilerplate inherit CI automatically.

## Non-goals

- Changing test coverage in any plugin (CI runs the suites as they exist).
- Reusable / shared GitHub Actions workflows. Each plugin's `ci.yml` is standalone, preserving the suite principle that a plugin can be cloned, linted, and tested without sibling repos present.
- Migrating `leastudios-forms` CI off its pinned WP test-library version.

## Approach

Replicate the proven `leastudios-forms` CI setup into each plugin (approach "B"): plain per-plugin replication **plus** seeding a tokenized `ci.yml` into the dev-tools boilerplate so future plugins inherit CI for free.

A reusable cross-repo workflow was rejected: it would make a plugin's CI undefined without the `leastudios-dev-tools` repo present, conflicting with the suite's self-contained-plugin principle.

## Per-plugin recipe

Applied to each plugin, in its own git repository:

### 1. PHP-floor audit

Grep `src/` for PHP version-specific idioms to determine the true minimum:

- **8.2:** standalone `true` / `false` / `null` return types; `readonly class`; DNF types; constants in traits.
- **8.3:** typed class constants; `#[\Override]`; `json_validate()`; dynamic class-constant fetch.
- **8.4:** property hooks; asymmetric visibility; `new X()->method()` without parentheses; `#[\Deprecated]`.

The audited floor is the highest version whose features appear. Same author and style as `leastudios-forms`, so most plugins are expected to land on 8.2; a plugin whose source is genuinely 8.1-clean keeps 8.1.

### 2. Pin the floor in five places

Mirrors exactly what `leastudios-forms` PR #4 did. For an audited floor of `8.2`:

| Location | Change |
| --- | --- |
| `composer.json` → `require.php` | `">=8.2"` |
| `composer.json` → `config.platform.php` | `"8.2"` |
| `<slug>.php` plugin header | `Requires PHP: 8.2` |
| `readme.txt` | `Requires PHP: 8.2` |
| `phpcs.xml.dist` | `<config name="testVersion" value="8.2-"/>` |

Then regenerate `composer.lock` with `composer update`. With `config.platform.php` set, Composer resolves every dependency to a version installable on the floor — this is the fix for the "lock not installable on the floor" bug.

### 3. Add `.github/workflows/ci.yml`

Copy the `leastudios-forms` workflow and adapt:

- The checkout `path` and the two `working-directory` values: swap `leastudios-forms` for the plugin name.
- The lint job's `php-version` and the test matrix's lower bound: set to the audited floor. The matrix ceiling stays `8.4`.
- The WP test-library version stays pinned to `6.8.2`, matching `leastudios-forms`. (The `install-wp-tests.sh` `latest` bug is fixed, but pinning keeps CI deterministic and the suite consistent.)

The `test` job checks out `adamjohnlea/leastudios-dev-tools` to obtain `bin/install-wp-tests.sh` — this stays a literal reference, as in the forms workflow.

### 4. Branch, PR, verify

In the plugin's own repo: branch `add-ci-workflow`, commit the changes, push, open a PR. Confirm every CI job goes green (Lint, Tests on the floor, Tests on 8.4). Fix anything red before the PR is considered done.

## Rollout structure

**Pilot:** `leastudios-mailer` — the largest test suite (10 test files, encryption, an SNS controller), so a green run is the strongest signal the recipe holds. Run the full 4-step recipe end-to-end and get its CI green before touching the others. If the recipe needs adjustment, the plan is corrected once, here.

**Batch:** the remaining four — `email-templates`, `payments`, `siteaudit`, `snippets` — each an independent repo with no shared state, so they can be executed in parallel (one implementer per plugin, mirroring the subagent-driven approach used for PR #4).

**Total output:** 5 plugin pull requests (1 pilot + 4 batch).

## Boilerplate seeding

A change to `leastudios-dev-tools`, so new plugins inherit CI on creation:

- Add `_boilerplate/.github/workflows/ci.yml` — a tokenized copy of the workflow, using the existing `plugin-name` scaffold token in place of the repo name.
- Update `_boilerplate/composer.json` — add `config.platform.php` and bump `require.php` so scaffolded plugins start with the floor pinned correctly. Align the boilerplate's `plugin-name.php` `Requires PHP` header with the same floor.

## Spec & plan location

This is a suite-wide effort, so the design doc and implementation plan live in `leastudios-dev-tools` (the shared-tooling repo). It currently has no `docs/` directory; `docs/superpowers/specs/` and `docs/superpowers/plans/` are created for this work.

The `leastudios-dev-tools` changes (spec, plan, boilerplate) commit directly to its `main`, consistent with how the `install-wp-tests.sh` fix was handled in the prior session. Only the 5 plugin repos receive pull requests.

## Success criteria

- All 5 plugin PRs show every CI job green: Lint, plus Tests on the audited floor and on 8.4.
- Each plugin's `composer.lock` is installable on its audited PHP floor.
- Each plugin's declared `Requires PHP` (in all five locations) matches its audited floor.
- `leastudios-dev-tools/_boilerplate/` carries a working tokenized `ci.yml`, and its `composer.json` pins `config.platform.php`.
