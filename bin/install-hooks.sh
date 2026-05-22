#!/usr/bin/env bash
#
# install-hooks.sh — wire the shared leaStudios git hooks into every suite repo.
#
# Points each repo's core.hooksPath at leastudios-dev-tools/bin/git-hooks so
# the pre-push hook (shared-file drift check) runs before every push.
#
# Run once per fresh clone of the suite, and again after adding a new repo:
#   bash leastudios-dev-tools/bin/install-hooks.sh
#
# This only sets local git config (core.hooksPath) in each repo — nothing is
# committed, and re-running is safe and idempotent. Note that core.hooksPath
# replaces a repo's .git/hooks entirely; the suite repos carry no other hooks.

set -eu

hooks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/git-hooks" && pwd)"
suite_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Shared hooks directory: $hooks_dir"
echo "Suite directory:        $suite_dir"
echo

repos=(
	leastudios-dev-tools
	leastudios-payments
	leastudios-mailer
	leastudios-forms
	leastudios-snippets
	leastudios-siteaudit
	leastudios-email-templates
)

installed=0
skipped=0
for repo in "${repos[@]}"; do
	repo_dir="$suite_dir/$repo"
	if [ ! -d "$repo_dir/.git" ]; then
		echo "  skip  $repo — no git repo at $repo_dir"
		skipped=$((skipped + 1))
		continue
	fi
	git -C "$repo_dir" config core.hooksPath "$hooks_dir"
	echo "  ok    $repo"
	installed=$((installed + 1))
done

echo
echo "Done — hooks installed in $installed repo(s), $skipped skipped."
echo "The pre-push hook now runs check-shared.sh before every push."
