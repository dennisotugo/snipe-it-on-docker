# Configuring Cron
# crontab -e
0 0 * * *  docker exec <container_name1> /usr/bin/php /var/www/html/artisan snipeit:backup
0 0 * * *  docker exec <container_name2> /usr/bin/php /var/www/html/artisan snipeit:backup

# In this example, docker runs the snipeit:backup command to two different containers at 12AM.
# While this quickly accomplishes the task of automating Snipe-IT backups, this does not handle the removal of old backups.
# As such, I wrote a script to handle both the backup as well as the cleanup of old backups.

#!/bin/bash

#
# Script for running automated backups for Snipe-IT Docker containers and removing old backups
#
# Mean to be used as part of a crontab
#
# Limits its search for backups to clean up to those in the 'BACKUP_DIR' folder, so
# you can create folders in this location to keep any manual backups for historical purposes
#

# Docker container name to backup
CONTAINER="${1}"
# Snipe-IT Docker container backup location
BACKUP_DIR="/var/www/html/storage/app/backups/"
# Number of backups to keep
MAX_BACKUPS="14"

# Verify a container name is supplied
if [ "$CONTAINER" = "" ]; then
	/bin/echo "No value supplied for 'CONTAINER'. Please run the script followed by the container name. ex. sh script.sh <container_name>"
	exit 1
fi

# First, complete a backup
/bin/echo "Creating database backup for ${CONTAINER} …"
docker exec "$CONTAINER" /usr/bin/php /var/www/html/artisan snipeit:backup

# Process existing backups for cleanup
BACKUPS=$(docker exec "$CONTAINER" /usr/bin/find "$BACKUP_DIR" -maxdepth 1 -type f | /usr/bin/sort -r)
BACKUP_NUM=$((${MAX_BACKUPS} + 1))
OLD_BACKUPS=$(echo $BACKUPS | tail -n +${BACKUP_NUM})

# If old backups found, remove them
if [ "$OLD_BACKUPS" != "" ]; then
	echo "Cleaning up old backups …"
	for f in $OLD_BACKUPS; do
		echo "Removing old backup: ${f} …"
		docker exec "$CONTAINER" rm $f
	done
else
	echo "No backups to clean. Done."
fi

exit
