# leaStudios WordPress Plugins

## Environment

- **WordPress**: 6.9+ (running on Laravel Herd)
- **PHP**: 8.1+ (currently 8.4)
- **Node**: 22+ / NPM 11+
- **Tools**: Composer, WP-CLI, PHPCS, PHPStan
- **Local URL**: leastudios-plugins.test (Herd)

## Project Structure

```
plugins/
├── _boilerplate/          # Plugin scaffold — copy to start a new plugin
├── composer.json           # Shared dev dependencies (PHPCS, PHPStan)
├── phpcs.xml.dist          # WordPress coding standards config
├── phpstan.neon            # Static analysis config
├── CLAUDE.md               # This file
└── <plugin-name>/          # Each plugin is its own directory
    ├── plugin-name.php     # Main plugin file (WP header + bootstrap)
    ├── composer.json       # Plugin-specific dependencies + PSR-4 autoload
    ├── uninstall.php       # Cleanup on delete
    ├── src/                # PHP source (PSR-4 namespace: LEAStudios\PluginName)
    │   ├── Plugin.php      # Main bootstrap class
    │   ├── Admin/          # Admin pages, settings, metaboxes
    │   ├── REST/           # REST API controllers (extend WP_REST_Controller)
    │   ├── Database/       # Migrations, custom tables
    │   └── Security/       # Nonce helpers, capability checks
    ├── assets/             # CSS, JS, images (compiled)
    ├── templates/          # PHP template files
    ├── languages/          # Translation files
    └── tests/              # PHPUnit tests
```

## Creating a New Plugin

1. Copy `_boilerplate/` to `<new-plugin-name>/`
2. Find-and-replace across all files:
   - `plugin-name` → `new-plugin-name` (text domain, slugs, and the CI workflow's checkout path / `working-directory` keys in `.github/workflows/ci.yml`)
   - `Plugin Name` → `New Plugin Name` (display name)
   - `PluginName` → `NewPluginName` (namespace)
   - `PLUGIN_NAME` → `NEW_PLUGIN_NAME` (constants)
   - `plugin_name` → `new_plugin_name` (function prefixes, option keys)
3. Update `composer.json` with the correct package name and namespace
4. Run `composer install` in the plugin directory
5. Activate via WP-CLI: `wp plugin activate new-plugin-name`

## Coding Standards

### PHP
- **Follow WordPress Coding Standards** (enforced via PHPCS)
- Use `declare(strict_types=1)` in all PHP files
- PSR-4 autoloading under `LEAStudios\<PluginName>\` namespace
- PHP 8.1+ features are allowed (enums, fibers, readonly properties, named args, match, etc.)
- Run `composer phpcs` from the plugins root to check code
- Run `composer phpcbf` to auto-fix issues

### Security (CRITICAL)
- **Always escape output**: `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`
- **Always sanitize input**: `sanitize_text_field()`, `absint()`, `wp_kses()`
- **Always verify nonces** on form submissions and AJAX requests
- **Always check capabilities** before performing privileged actions
- **Never trust `$_GET`, `$_POST`, `$_REQUEST`** — sanitize every value
- **Use `$wpdb->prepare()`** for ALL database queries with user input — no exceptions
- **Use `wp_safe_redirect()`** instead of `wp_redirect()` when possible
- **Prefix everything**: functions, hooks, option names, database tables, REST routes

### Database
- Custom tables use `$wpdb->prefix` + plugin-specific prefix
- Use `dbDelta()` for table creation/migration
- Track schema versions via options for incremental migrations
- Always use `$wpdb->prepare()` for parameterized queries
- **Never interpolate table or column names directly into SQL** — even when the value is `$wpdb->prefix . 'fixed_literal'`. Use the `%i` identifier placeholder inside `$wpdb->prepare()` (WP 6.2+, available across the whole suite since `minimum_supported_wp_version` is 6.4+).

  Correct:
  ```php
  $table = $wpdb->prefix . 'plugin_name_items';
  $rows  = $wpdb->get_results(
      $wpdb->prepare( 'SELECT * FROM %i WHERE status = %s', $table, $status )
  );

  // DDL works too — %i is valid inside prepare() for any context.
  $wpdb->query( $wpdb->prepare( 'DROP TABLE IF EXISTS %i', $table ) );
  ```

  Wrong (do not use, even with `phpcs:ignore`):
  ```php
  $rows = $wpdb->get_results( $wpdb->prepare( "SELECT * FROM {$table} WHERE status = %s", $status ) );
  ```

  Exception: `dbDelta()` does not call `prepare()`, so `CREATE TABLE` strings legitimately interpolate the table name. That is the only place this rule does not apply.

  Rationale: `WordPress.org`'s Plugin Check sniff `PluginCheck.Security.DirectDB.UnescapedDBParameter` flags interpolated identifiers regardless of source, and silencing it with `phpcs:ignore` is a smell. `%i` is the modern, sniff-clean, and identifier-escape-safe alternative — use it everywhere.

  **Antipattern — never do this:** adding `// phpcs:ignore WordPress.DB.PreparedSQL.InterpolatedNotPrepared` (or the matching `phpcs:disable` block) to silence the sniff instead of converting to `%i`. If you see that ignore appear in a diff for a DB query, the fix is to remove the interpolation, not to suppress the warning.

  **Enforcement — `composer lint:db`** (wired into every plugin's `composer lint`): a grep tripwire at `bin/check-db-interpolation.sh` fails the build if it finds either (a) brace-style `{$...}` interpolation inside a `$wpdb->prepare()` / `get_*()` / `query()` call, or (b) a `phpcs:ignore` / `phpcs:disable` for `WordPress.DB.PreparedSQL.InterpolatedNotPrepared`. Per-plugin exemptions live in `.dblint-allow` at the plugin root (one path per line, each paired with an inline rationale comment at the call site). Use exemptions for genuinely safe whitelisted-vocabulary cases (dynamic `IN (%s, %s, ...)` placeholder lists, filter-keyed `WHERE` clauses); do **not** use them to silence newly-written interpolation. The script is shared-by-duplication and verified byte-identical by `bin/check-shared.sh`.

### REST API
- Extend `WP_REST_Controller` for structured endpoints
- Always define `permission_callback` (never leave it null/empty)
- Use JSON Schema for argument validation
- Namespace routes: `plugin-name/v1/`

### Assets
- Enqueue via `wp_enqueue_script()` / `wp_enqueue_style()` — never hardcode `<script>` or `<link>`
- Use `wp_localize_script()` or `wp_add_inline_script()` to pass data to JS
- Declare dependencies properly (e.g., `['jquery']`, `['wp-element']`)

### Hooks & Filters
- Use `add_action()` / `add_filter()` — never modify core files
- Prefix all custom hook names: `plugin_name_before_save`
- Always specify priority and accepted args when they matter

### i18n
- Wrap all user-facing strings in `__()`, `_e()`, `esc_html__()`, etc.
- Text domain must match the plugin slug exactly
- Generate POT files: `wp i18n make-pot . languages/plugin-name.pot`

## Quality Commands

```bash
# Lint PHP (coding standards)
composer phpcs

# Auto-fix coding standard issues
composer phpcbf

# Static analysis
composer phpstan

# DB-interpolation tripwire (grep gate — see Database section)
composer lint:db

# Run every lint (phpcs + phpstan + lint:db)
composer lint

# Generate translation template
wp i18n make-pot <plugin-dir> <plugin-dir>/languages/<plugin-name>.pot
```

## Continuous-integration gates

Each plugin's `.github/workflows/ci.yml` runs three checks on every push and PR:

1. **`lint`** — `composer phpcs`, `composer phpstan`, and `composer lint:db` against the dev tree. Catches coding-standard violations, type errors, and the DB-interpolation antipattern documented in the Database section.
2. **`test`** — `composer test` against a real WordPress test library on PHP 8.2 + 8.4 with MySQL 8.0.
3. **`plugin-check`** — WordPress.org's official **Plugin Check** suite, run against the **release build** (the actual zip that would be distributed). The job:
   1. Builds the dist by calling `bin/package.sh <plugin>` from `leastudios-dev-tools` — same script that produces release zips, so `composer install --no-dev` + `.distignore` exclusions + vendor docs/test scrubbing all apply.
   2. Unzips the dist into `./build/<plugin>/`.
   3. Runs `WordPress/plugin-check-action@v1` against that directory.

   Errors fail the job; warnings are reported as annotations. Running against the dist (not the dev tree) means `tests/`, `bin/`, fixtures, dev `vendor/` packages, and configuration files are excluded from the check — only the code WordPress.org reviewers and end users would actually see is evaluated. If Plugin Check fires a new warning that you believe is a false positive, file an issue against `WordPress/plugin-check` rather than silencing it locally.

## Key WordPress APIs to Use

- **Settings API** for admin settings pages (not raw option updates)
- **REST API** for AJAX-like functionality (prefer over admin-ajax.php)
- **Transients API** for caching (`set_transient()`, `get_transient()`)
- **Options API** for persistent settings (`get_option()`, `update_option()`)
- **WP_Query** for post queries (never raw SQL for post data)
- **WP Cron** for scheduled tasks (`wp_schedule_event()`)
- **Custom Post Types & Taxonomies** when modeling content
- **Block Editor (Gutenberg)** for content editing UIs when appropriate

## Testing with WP-CLI

```bash
# Activate a plugin
wp plugin activate <plugin-name>

# Deactivate
wp plugin deactivate <plugin-name>

# Check plugin status
wp plugin list

# Evaluate PHP in WP context
wp eval 'echo get_option("plugin_name_options");'

# Flush rewrite rules
wp rewrite flush
```
