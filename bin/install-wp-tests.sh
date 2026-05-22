#!/usr/bin/env bash
#
# Install WordPress test library for plugin testing.
#
# Usage: bash bin/install-wp-tests.sh <db-name> <db-user> <db-pass> <db-host> [wp-version]
#
# Example: bash bin/install-wp-tests.sh wordpress_test root '' localhost latest

if [ $# -lt 4 ]; then
	echo "Usage: $0 <db-name> <db-user> <db-pass> <db-host> [wp-version]"
	exit 1
fi

DB_NAME=$1
DB_USER=$2
DB_PASS=$3
DB_HOST=$4
WP_VERSION=${5-latest}

TMPDIR=${TMPDIR-/tmp}
TMPDIR=$(echo "$TMPDIR" | sed -e "s/\/$//")
WP_TESTS_DIR=${WP_TESTS_DIR-$TMPDIR/wordpress-tests-lib}
WP_CORE_DIR=${WP_CORE_DIR-$TMPDIR/wordpress}

download() {
	if [ "$(which curl)" ]; then
		curl -fsSL "$1" > "$2"
	elif [ "$(which wget)" ]; then
		wget -nv -O "$2" "$1"
	fi
}

if [ "$WP_VERSION" == "latest" ]; then
	WP_VERSION=$(curl -fsSL "https://api.wordpress.org/core/version-check/1.7/" | grep -o '"version":"[^"]*"' | head -1 | sed 's/"version":"//;s/"//')
	if [ -z "$WP_VERSION" ]; then
		echo "Could not determine latest WP version. Using 6.9."
		WP_VERSION="6.9"
	fi
fi

WP_TESTS_TAG="tags/$WP_VERSION"

set -ex

install_wp() {
	if [ -d "$WP_CORE_DIR" ]; then
		return
	fi

	mkdir -p "$WP_CORE_DIR"

	local ARCHIVE_URL="https://wordpress.org/wordpress-$WP_VERSION.tar.gz"

	download "$ARCHIVE_URL" /tmp/wordpress.tar.gz
	tar --strip-components=1 -zxmf /tmp/wordpress.tar.gz -C "$WP_CORE_DIR"
}

install_test_suite() {
	# Set up testing suite if it doesn't exist.
	if [ -d "$WP_TESTS_DIR" ]; then
		# Check if already configured.
		if [ -f "$WP_TESTS_DIR/wp-tests-config.php" ]; then
			echo "Test suite already installed at $WP_TESTS_DIR"
			return
		fi
	fi

	mkdir -p "$WP_TESTS_DIR"

	# Download the full WordPress develop repo test suite via GitHub tarball.
	# The wordpress-develop repo tags every release with a three-part version
	# (e.g. 7.0.0), while the wordpress.org API reports major releases with
	# two parts (e.g. 7.0). Normalise so the tag URL resolves.
	local ARCHIVE_NAME="${WP_VERSION}"
	if [[ "$ARCHIVE_NAME" =~ ^[0-9]+\.[0-9]+$ ]]; then
		ARCHIVE_NAME="${ARCHIVE_NAME}.0"
	fi
	local ARCHIVE_URL="https://github.com/WordPress/wordpress-develop/archive/refs/tags/${ARCHIVE_NAME}.tar.gz"

	download "$ARCHIVE_URL" /tmp/wp-develop.tar.gz

	# Extract just the tests/phpunit directory into WP_TESTS_DIR.
	tar --strip-components=3 -zxmf /tmp/wp-develop.tar.gz -C "$WP_TESTS_DIR" "wordpress-develop-${ARCHIVE_NAME}/tests/phpunit/"

	rm -f /tmp/wp-develop.tar.gz

	# Generate wp-tests-config.php
	if [ ! -f "$WP_TESTS_DIR/wp-tests-config.php" ]; then
		cat > "$WP_TESTS_DIR/wp-tests-config.php" <<PHP
<?php
define( 'ABSPATH', '${WP_CORE_DIR}/' );
define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASS}' );
define( 'DB_HOST', '${DB_HOST}' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

\$table_prefix = 'wptests_';

define( 'WP_TESTS_DOMAIN', 'example.org' );
define( 'WP_TESTS_EMAIL', 'admin@example.org' );
define( 'WP_TESTS_TITLE', 'Test Blog' );
define( 'WP_PHP_BINARY', 'php' );

define( 'WP_DEBUG', true );
PHP
	fi
}

install_db() {
	# Parse DB_HOST for port or socket.
	local EXTRA=""

	if [ "$(echo "$DB_HOST" | grep -c ':')" -gt 0 ]; then
		local DB_HOSTNAME=${DB_HOST%:*}
		local DB_SOCK_OR_PORT=${DB_HOST#*:}

		if [ -S "$DB_SOCK_OR_PORT" ] || [ -e "/tmp/$DB_SOCK_OR_PORT" ]; then
			EXTRA=" --socket=$DB_SOCK_OR_PORT"
		else
			EXTRA=" --port=$DB_SOCK_OR_PORT --protocol=tcp"
		fi
	elif ! [ -z "$DB_HOST" ]; then
		local DB_HOSTNAME=$DB_HOST
	fi

	if [ "$(echo "$DB_HOST" | grep -c '://')" -gt 0 ]; then
		local DB_HOSTNAME=${DB_HOST%:*}
	fi

	local MYSQL_PASS=""
	if [ -n "$DB_PASS" ]; then
		MYSQL_PASS="-p${DB_PASS}"
	fi

	mysqladmin create "$DB_NAME" --user="$DB_USER" $MYSQL_PASS --host="${DB_HOSTNAME:-localhost}" $EXTRA --force 2>/dev/null || true
}

install_wp
install_test_suite
install_db

echo ""
echo "WordPress test suite installed successfully!"
echo "  WP_TESTS_DIR: $WP_TESTS_DIR"
echo "  WP_CORE_DIR:  $WP_CORE_DIR"
echo "  Database:      $DB_NAME"
echo ""
echo "Run tests with: composer test"
