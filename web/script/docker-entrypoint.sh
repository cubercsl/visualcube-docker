#!/bin/bash
set -e

# Note: we don't just use "apache2ctl" here because it itself is just a shell-script wrapper around apache2 which provides extra functionality like "apache2ctl start" for launching apache2 in the background.
# (also, when run as "apache2ctl <apache args>", it does not use "exec", which leaves an undesirable resident shell process)

: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
    . "$APACHE_ENVVARS"
fi

# Apache gets grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"

# create missing directories
# (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
for e in "${!APACHE_@}"; do
    if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
        # handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
        #   mkdir: cannot create directory '/var/lock': File exists
        dir="${!e}"
        while [ "$dir" != "$(dirname "$dir")" ]; do
            dir="$(dirname "$dir")"
            if [ -d "$dir" ]; then
                break
            fi
            absDir="$(readlink -f "$dir" 2>/dev/null || :)"
            if [ -n "$absDir" ]; then
                mkdir -p "$absDir"
            fi
        done

        mkdir -p "${!e}"
    fi
done

CONFIG="/var/www/html/cache_config.php"

create_database() {
    (
    echo "CREATE DATABASE IF NOT EXISTS visualcube;"
    echo "GRANT SELECT, INSERT, UPDATE, DELETE ON visualcube.* TO '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
    echo "FLUSH PRIVILEGES;"
    ) | mysql -uroot -p${MYSQL_ROOT_PASSWORD}

    (
    cat << EOF
use visualcube;
/** Caches generated visual cubes.
Stores the parameters used to generate the image,
the latest referrer to request the image,
and the request frequencey */
CREATE TABLE IF NOT EXISTS vcache(
        hash CHAR(32) NOT NULL,
        fmt CHAR(4) NOT NULL,
        req VARCHAR(255) NOT NULL,
        rfr VARCHAR(255) NOT NULL,
        rcount INT UNSIGNED NOT NULL,
        img MEDIUMBLOB,
        PRIMARY KEY (hash));

/** View contents with: */
SELECT hash, fmt, req, rfr, rcount, OCTET_LENGTH(img) FROM vcache;
EOF
    ) | mysql -uroot -p${MYSQL_ROOT_PASSWORD}

    echo "Database and user(s) added."
}

write_config() {
    
    echo '<?php' > $CONFIG
    if [ $ENABLE_CACHE -ne 0 ]; then
        echo '$ENABLE_CACHE=false;' >> $CONFIG
    else
        echo "Enable cache."
        #create_database
        echo '$ENABLE_CACHE=true;' >> $CONFIG
    fi
    (
    cat << EOF
// Database Configuration (for image caching)
\$DB_HOST="$MYSQL_HOST";
\$DB_NAME="visualcube";
\$DB_USERNAME="$MYSQL_USER";
\$DB_PASSWORD="$MYSQL_PASSWORD";
// Maximum size of image to be cached
\$CACHE_IMG_SIZE_LIMIT=$CACHE_IMG_SIZE_LIMIT;
EOF
    ) >> $CONFIG
}

write_config

exec apache2 -DFOREGROUND "$@"
