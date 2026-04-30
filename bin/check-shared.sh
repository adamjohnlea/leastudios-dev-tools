#!/usr/bin/env bash
#
# check-shared.sh
#
# Verifies that classes intentionally duplicated across leastudios-* plugins
# remain in sync (modulo docblocks, namespace, and plugin-name prefix).
#
# The leaStudios suite ships per-plugin self-contained zips, so a handful of
# helper classes (Nonce, Options_Encryptor, Datetime_Util, ...) are duplicated
# by design rather than extracted to a shared Composer package. This checker
# protects that model from silent drift.
#
# Usage:
#   bin/check-shared.sh             # check all configured shared files
#   PLUGINS_DIR=/path bin/check-shared.sh
#
# Exits 0 if every shared file is in sync across all plugins that ship it,
# 1 if any file has drifted, 2 on script error.

set -u

PLUGINS_DIR="${PLUGINS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Files duplicated across plugins. Each entry is a path under <plugin>/src/.
SHARED_FILES=(
	"Security/Nonce.php"
	"Encryption/Options_Encryptor.php"
	"Shared/Datetime_Util.php"
)

# Plugins to inspect, in canonical order. The first plugin that ships a given
# file becomes the reference for that file in the report.
PLUGINS=(
	payments
	mailer
	forms
	snippets
	siteaudit
	email-templates
)

# Plugin-specific tokens used inside class bodies. Each parallel list maps
# 1:1 across the 6 plugins. Kept as separate variables because slugs, namespace
# segments, and human-readable display names don't share a 1:1 mapping.
SLUG_ALTERNATION="payments|mailer|forms|snippets|siteaudit|email_templates"
DASH_ALTERNATION="payments|mailer|forms|snippets|siteaudit|email-templates"
NS_ALTERNATION="Payments|Mailer|Forms|Snippets|SiteAudit|EmailTemplates"
DISPLAY_ALTERNATION="Payments|Mailer|Forms|Snippets|Site ?Audit|Email Templates"

# Normalize a PHP source file for comparison:
#   - strip /* ... */ block comments (including docblocks)
#   - strip // line comments
#   - drop the namespace declaration line
#   - drop blank lines and trailing whitespace
#   - normalize plugin-name tokens inside the body
#       leastudios_<slug>_           -> leastudios_PLUGIN_
#       leastudios-<dash-slug>       -> leastudios-PLUGIN
#       LEAStudios\<Namespace>\      -> LEAStudios\PLUGIN\
#       leaStudios <DisplayName>     -> leaStudios PLUGIN  (also matches the
#                                       'leastudios' typo variant seen in
#                                       a couple of plugins' wp_die messages)
normalize() {
	awk \
		-v slugs="$SLUG_ALTERNATION" \
		-v dash_slugs="$DASH_ALTERNATION" \
		-v ns="$NS_ALTERNATION" \
		-v display="$DISPLAY_ALTERNATION" '
		BEGIN {
			slug_re    = "leastudios_(" slugs ")_"
			dash_re    = "leastudios-(" dash_slugs ")"
			ns_re      = "LEAStudios\\\\(" ns ")\\\\"
			display_re = "[Ll]ea[Ss]tudios (" display ")"
		}
		in_block { if (/\*\//) in_block = 0; next }
		/^[[:space:]]*\/\*/ { if (/\*\//) next; in_block = 1; next }
		/^[[:space:]]*\/\// { next }
		/^[[:space:]]*$/    { next }
		/^[[:space:]]*namespace[[:space:]]/ { next }
		{
			gsub(slug_re, "leastudios_PLUGIN_")
			gsub(dash_re, "leastudios-PLUGIN")
			gsub(ns_re, "LEAStudios\\PLUGIN\\")
			gsub(display_re, "leaStudios PLUGIN")
			sub(/[[:space:]]+$/, "")
			print
		}
	' "$1"
}

drift_count=0
checked_count=0

for shared in "${SHARED_FILES[@]}"; do
	echo "── $shared"
	reference_hash=""
	reference_plugin=""
	for plugin in "${PLUGINS[@]}"; do
		path="$PLUGINS_DIR/leastudios-$plugin/src/$shared"
		if [ ! -f "$path" ]; then
			continue
		fi
		hash=$(normalize "$path" | shasum -a 256 | cut -d' ' -f1)
		if [ -z "$reference_hash" ]; then
			reference_hash="$hash"
			reference_plugin="$plugin"
			printf "   [ref ] leastudios-%s\n" "$plugin"
		elif [ "$hash" = "$reference_hash" ]; then
			printf "   [ ok ] leastudios-%s\n" "$plugin"
		else
			printf "   [DIFF] leastudios-%s (vs leastudios-%s)\n" "$plugin" "$reference_plugin"
			diff -u \
				--label "leastudios-$reference_plugin/src/$shared (normalized)" \
				--label "leastudios-$plugin/src/$shared (normalized)" \
				<(normalize "$PLUGINS_DIR/leastudios-$reference_plugin/src/$shared") \
				<(normalize "$path") \
				| sed 's/^/         /'
			drift_count=$((drift_count + 1))
		fi
		checked_count=$((checked_count + 1))
	done
	echo
done

if [ "$drift_count" -gt 0 ]; then
	echo "FAIL: $drift_count file(s) drifted across plugins (checked $checked_count file(s))"
	exit 1
fi

echo "OK: $checked_count file(s) in sync across plugins"
exit 0
