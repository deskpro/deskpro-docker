FROM php:7.2-apache

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		cron \
		gosu \
		libc-client-dev \
		libfreetype6 \
		libfreetype6-dev \
		libicu-dev \
		libjpeg62-turbo \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libpng16-16 \
		libpng-dev \
		libxml2-dev \
		libzip-dev \
		mariadb-client \
		unzip \
	&& docker-php-ext-install -j$(nproc) \
		iconv \
		intl \
		opcache \
		pdo_mysql \
		soap \
		zip \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-install -j$(nproc) imap \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install -j$(nproc) ldap \
	&& apt-get remove -y \
		libc-client-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libpng-dev \
		libxml2-dev \
		libzip-dev \
	&& rm -rf /var/lib/apt/lists/* \
	# Ensure gosu works
	&& gosu nobody true

RUN a2enmod rewrite

RUN curl -L https://www.deskpro.com/downloads/deskpro.zip -o /usr/src/deskpro.zip

VOLUME /var/www/html

RUN rm -rf /etc/apache2/sites-enabled/000-default.conf

COPY deskpro.conf /etc/apache2/sites-enabled/deskpro.conf

COPY php.ini /usr/local/etc/php/

COPY docker-entrypoint.sh deskpro-docker-cron /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
