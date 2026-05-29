#!/usr/bin/env bash
#
# Package a leaStudios plugin into an installable zip.
#
# Usage:
#   bash bin/package.sh <plugin-name>          # Package a specific plugin
#   bash bin/package.sh all                    # Package all plugins
#
# Examples:
#   bash bin/package.sh leastudios-payments
#   bash bin/package.sh all
#
# Output goes to dist/ in the plugins root.

set -e

PLUGINS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DIST_DIR="$PLUGINS_DIR/dist"

# All packagable plugins.
ALL_PLUGINS=(
	leastudios-snippets
	leastudios-payments
	leastudios-forms
	leastudios-mailer
	leastudios-siteaudit
	leastudios-email-templates
	leastudios-helpscout-ai-dashboard
)

package_plugin() {
	local plugin="$1"
	local plugin_dir="$PLUGINS_DIR/$plugin"

	if [ ! -d "$plugin_dir" ]; then
		echo "Error: Plugin directory not found: $plugin_dir"
		return 1
	fi

	if [ ! -f "$plugin_dir/.distignore" ]; then
		echo "Error: No .distignore found for $plugin"
		return 1
	fi

	# Read the plugin version from the main plugin file header.
	local version
	version=$(grep -m1 'Version:' "$plugin_dir/$plugin.php" | sed 's/.*Version:[[:space:]]*//' | tr -d '[:space:]')

	if [ -z "$version" ]; then
		version="dev"
	fi

	local zip_name="${plugin}-${version}.zip"
	local tmp_dir
	tmp_dir=$(mktemp -d)

	echo "Packaging $plugin v$version..."

	# Copy plugin to temp directory.
	# --exclude='.*' is a catch-all for hidden files (.git, .DS_Store, .vscode,
	# .phpunit.result.cache, etc.) so they can never leak into the zip even if
	# a plugin's .distignore forgets to list them. WordPress plugins don't need
	# to ship dotfiles.
	#
	# The root-anchored excludes below are a suite-wide guard for AI/developer
	# guidance and readme files: they must never ship in a distributable,
	# regardless of whether a given plugin's .distignore lists them. Note this
	# excludes README.md (the GitHub/dev readme) but NOT readme.txt — the
	# WordPress.org plugin readme, which is required in the zip.
	rsync -a \
		--exclude='.*' \
		--exclude='/AGENTS.md' \
		--exclude='/CLAUDE.md' \
		--exclude='/GEMINI.md' \
		--exclude='/README.md' \
		--exclude-from="$plugin_dir/.distignore" \
		"$plugin_dir/" "$tmp_dir/$plugin/"

	# If the plugin uses Composer, install production-only deps into the temp copy
	# so dev tools (phpunit, phpstan, phpcs, etc.) don't ship to end users.
	if [ -f "$plugin_dir/composer.json" ]; then
		# composer.json is in .distignore so the rsync skipped it — copy it back
		# temporarily for the install, plus the lock file for reproducibility.
		cp "$plugin_dir/composer.json" "$tmp_dir/$plugin/composer.json"
		[ -f "$plugin_dir/composer.lock" ] && cp "$plugin_dir/composer.lock" "$tmp_dir/$plugin/composer.lock"

		# Replace any rsynced vendor/ with a clean prod-only one.
		rm -rf "$tmp_dir/$plugin/vendor"

		(
			cd "$tmp_dir/$plugin"
			composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --quiet
		)

		# Remove composer.lock from the dist (dev-only, not needed at runtime).
		# Keep composer.json so Plugin Check doesn't warn about an orphan vendor/.
		rm -f "$tmp_dir/$plugin/composer.lock"

		# Strip hidden files that third-party packages bring in (e.g. .gitignore,
		# .github, .editorconfig). The earlier rsync only covered the dev tree.
		find "$tmp_dir/$plugin/vendor" -name '.*' -print0 2>/dev/null | xargs -0 rm -rf

		# Strip docs and dev files third-party packages ship (CHANGELOG, README,
		# tests, examples). LICENSE-style files are kept — legally required.
		find "$tmp_dir/$plugin/vendor" \
			\( -iname 'CHANGELOG*' -o -iname 'README*' -o -iname 'CONTRIBUTING*' \
			   -o -iname 'UPGRADING*' -o -iname 'UPGRADE*' -o -iname '*.dist' \
			   -o -name 'justfile' -o -name 'Makefile' -o -name 'phpunit.xml*' \
			\) -type f -delete 2>/dev/null
		find "$tmp_dir/$plugin/vendor" \
			\( -name 'tests' -o -name 'Tests' -o -name 'test' -o -name 'Test' \
			   -o -name 'examples' -o -name 'example' -o -name 'docs' -o -name 'doc' \
			\) -type d -prune -exec rm -rf {} + 2>/dev/null
	fi

	# Remove any empty directories left behind.
	find "$tmp_dir/$plugin" -type d -empty -delete 2>/dev/null || true

	# Create the dist output directory.
	mkdir -p "$DIST_DIR"

	# Remove old zip if it exists.
	rm -f "$DIST_DIR/$zip_name"

	# Create the zip from the temp directory.
	cd "$tmp_dir"
	zip -rq "$DIST_DIR/$zip_name" "$plugin"
	cd "$PLUGINS_DIR"

	# Clean up.
	rm -rf "$tmp_dir"

	local size
	size=$(du -h "$DIST_DIR/$zip_name" | cut -f1 | tr -d '[:space:]')

	echo "  ✓ $DIST_DIR/$zip_name ($size)"
}

# Main.
if [ $# -lt 1 ]; then
	echo "Usage: $0 <plugin-name|all>"
	echo ""
	echo "Available plugins:"
	for p in "${ALL_PLUGINS[@]}"; do
		echo "  $p"
	done
	exit 1
fi

target="$1"

if [ "$target" = "all" ]; then
	echo "Packaging all plugins..."
	echo ""
	for plugin in "${ALL_PLUGINS[@]}"; do
		package_plugin "$plugin"
	done
	echo ""
	echo "All plugins packaged to: $DIST_DIR/"
else
	package_plugin "$target"
fi
