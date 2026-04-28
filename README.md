# leaStudios Dev Tools

Shared scaffolding and tooling for the leaStudios family of WordPress plugins.

This repo is **not a plugin**. It's the development home for:

- **`_boilerplate/`** — the starting scaffold for any new leaStudios plugin (PSR-4, modern PHP 8.1+, REST controller stub, security helpers, sample test).
- **`bin/install-wp-tests.sh`** — installs the WordPress test library (`wordpress-tests-lib`) into a temp dir so each plugin can run `phpunit` against a real WordPress.
- **`bin/package.sh`** — packages a plugin into a distributable `.zip` (respecting each plugin's `.distignore`).
- **`config-templates/`** — canonical `phpcs.xml.dist`, `phpstan.neon`, `phpunit.xml.dist`, and `tests/bootstrap.php` templates that every plugin repo copies in.
- **`CLAUDE.md`** — project-wide development conventions (coding standards, security rules, WordPress patterns) that apply across all leaStudios plugins.
- **`CODE_REVIEW.md`** — historical code-review notes for the plugin family.

## How it relates to the plugins

Each leaStudios plugin lives in its own git repository alongside this one in `wp-content/plugins/`:

```
wp-content/plugins/
├── leastudios-dev-tools/         (this repo)
├── leastudios-payments/          (own repo)
├── leastudios-email-templates/   (own repo)
├── leastudios-forms/             (own repo)
├── leastudios-mailer/            (own repo)
└── leastudios-snippets/          (own repo)
```

Each plugin is **self-contained** — it has its own `composer.json` with dev dependencies, its own `phpcs.xml.dist`, `phpstan.neon`, `phpunit.xml.dist`, and `tests/bootstrap.php`. A plugin can be cloned, linted, tested, and packaged on its own without this repo being present.

This repo is the **canonical source** of those configs. When you change a config template here, propagate the change to each plugin repo manually (or via a small sync script).

## Common workflows

### Bootstrap a new plugin

```bash
cp -R leastudios-dev-tools/_boilerplate leastudios-newthing
cd leastudios-newthing
# Find/replace plugin-name → newthing, PluginName → Newthing, etc.
# (See _boilerplate/README — todo)
composer install
git init
```

### Install the WordPress test library (one-time, shared across all plugins)

```bash
bash leastudios-dev-tools/bin/install-wp-tests.sh wordpress_test root '' localhost latest
```

This drops the test library into `/tmp/wordpress-tests-lib/`. Every plugin's `tests/bootstrap.php` looks for it there (or via the `WP_TESTS_DIR` env var).

### Run a plugin's tests / lint

From inside any plugin directory:

```bash
composer install      # one-time
composer lint         # phpcs + phpstan
composer test         # phpunit
composer phpcbf       # auto-fix WPCS issues
```

### Package a plugin for distribution

```bash
bash leastudios-dev-tools/bin/package.sh leastudios-payments
# → produces leastudios-payments-X.Y.Z.zip
```

Or `bash leastudios-dev-tools/bin/package.sh all` to package every plugin.

## Versioning

This repo isn't published as a Composer package — its contents are copy-in templates. Each plugin pins its own versions of `phpstan/phpstan`, `wp-coding-standards/wpcs`, etc. in its own `composer.json`.

## License

GPL-2.0-or-later, matching the plugins.
