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

PLUGINS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PLUGINS_DIR/dist"

# All packagable plugins.
ALL_PLUGINS=(
	leastudios-snippets
	leastudios-payments
	leastudios-forms
	leastudios-mailer
	leastudios-email-templates
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
	rsync -a --exclude-from="$plugin_dir/.distignore" "$plugin_dir/" "$tmp_dir/$plugin/"

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
