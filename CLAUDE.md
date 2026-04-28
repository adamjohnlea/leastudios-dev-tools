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
   - `plugin-name` → `new-plugin-name` (text domain, slugs)
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

# Run all linting
composer lint

# Generate translation template
wp i18n make-pot <plugin-dir> <plugin-dir>/languages/<plugin-name>.pot
```

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
