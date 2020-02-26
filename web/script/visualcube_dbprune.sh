#!/bin/sh

# Script to prune virtualcube image cache, to be run weekly
DB_NAME=visualcube

# Prune database by removing all entries which have been accessed less than 1 times
mysql -u $MYSQL_USER --safe-updates=0 --password="MYSQL_PASSWORD" $DB_NAME -e "DELETE FROM vcache WHERE rcount < 1"

# Reset all existing entrys to 0
mysql -u $MYSQL_USER --safe-updates=0 --password="MYSQL_PASSWORD" $DB_NAME -e "UPDATE vcache SET rcount=0"

# Query to display db contents
mysql -u $MYSQL_USER --password="MYSQL_PASSWORD" $DB_NAME -e "SELECT hash, fmt, req, rfr, rcount, OCTET_LENGTH(img) FROM vcache"

# This crontab line will run it at 4 am every Monday
#00 4 * * Mon /path/to/visualcube_dbprune.sh "Prune visualcube image cache"
# To install crontab on multi-user system place the line in a file and then run:
# crontab <filename>
