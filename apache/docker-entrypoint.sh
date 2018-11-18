#!/bin/bash
set -eo nounset

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- deskpro-docker-cmd "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'deskpro-docker-cron' -a "$(id -u)" = '0' ]; then
	exec gosu www-data "$0" "$@"
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ ! -e /var/www/html/config/config.database.php ]; then
		MYSQL_HOST=${MYSQL_HOST:-mysql}
		MYSQL_USER=${MYSQL_USER}
		MYSQL_PASSWORD=${MYSQL_PASSWORD}
		MYSQL_DATABASE=${MYSQL_DATABASE}

		while ! mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --execute "use $MYSQL_DATABASE" ; do
			echo "Database is not ready yet, waiting..."
			sleep 3
		done

		mysql_command="SELECT COUNT(DISTINCT \`table_name\`) FROM \`information_schema\`.\`columns\` WHERE \`table_schema\` = '$MYSQL_DATABASE'"
		tables=$(mysql --batch --skip-column-names -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --execute "$mysql_command")

		if [ "$tables" -ne "0" ]; then
			echo -e "Your database is not empty\n\nPlease try again using an empty one"
			exit 1
		fi


		profile=$(mktemp)

		cat <<-EOF > "$profile"
		{
			"no-interactive": true,
			"skip": [
				"checks"
			],
			"install-source": "automated_installer",
			"dbinfo": {
				"host": "MYSQL_HOST",
				"user": "MYSQL_USER",
				"password": "MYSQL_PASSWORD",
				"dbname": "MYSQL_DATABASE"
			},
			"path_php": "/usr/local/bin/php",
			"path_mysql": "/usr/bin/mysql",
			"path_mysqldump": "/usr/bin/mysqldump",
			"filestorage_method": "fs"
		}
		EOF

		sed -i "s/MYSQL_HOST/${MYSQL_HOST}/" "$profile"
		sed -i "s/MYSQL_USER/${MYSQL_USER}/" "$profile"
		sed -i "s/MYSQL_DATABASE/${MYSQL_DATABASE}/" "$profile"

		# password might have slashes, escape them
		MYSQL_PASSWORD=$(sed 's:/:\\/:' <<< "$MYSQL_PASSWORD")

		sed -i "s/MYSQL_PASSWORD/${MYSQL_PASSWORD}/" "$profile"

		unzip -f -d /var/www/html /usr/src/deskpro.zip
		chown -R www-data:www-data /var/www/html/

		cd /var/www/html/ && bin/install --profile "$profile" --no-interaction
	fi
fi

exec "$@"
