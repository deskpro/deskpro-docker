#!/bin/bash
set -eo pipefail

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

travisEnv=
for variant in apache fpm; do
	# Create the variant directory with a Dockerfile.
	mkdir -p "$variant"

	template="Dockerfile.template"
	cp "$template" "$variant/Dockerfile"

	echo "updating $variant"

	# Replace the variables.
	sed -ri -e '
		s/%%VARIANT%%/'"$variant"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/g;
	' "$variant/Dockerfile"

	# Remove Apache commands if we're not an Apache variant.
	if [ "$variant" != "apache" ]; then
		sed -ri -e '/a2enmod/d' "$variant/Dockerfile"
	fi

	# Copy executables
	cp docker-entrypoint.sh deskpro-docker-cron "$variant/"

	# Copy php config
	cp php.ini "$variant/php.ini"

	# Copy apache config (gets copied into fpm image, although it is not used
	# by the container)
	cp deskpro.conf "$variant/deskpro.conf"

	travisEnv='\n  - VARIANT='"$variant$travisEnv"
done

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis"  > .travis.yml

# remove duplicate entries
echo "$(awk '!NF || !seen[$0]++' .travis.yml)" > .travis.yml
