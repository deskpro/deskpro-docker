FROM php:7-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
		cron \
		libc-client-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmcrypt-dev \
		libpng12-dev \
		libxml2-dev \
		libzip-dev \
		mariadb-client \
		unzip \
	&& docker-php-ext-install -j$(nproc) \
		iconv \
		intl \
		mcrypt \
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
	&& a2enmod \
		rewrite \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -L https://www.deskpro.com/downloads/deskpro.zip -o deskpro.zip \
	&& mkdir /usr/src/deskpro \
	&& unzip -d /usr/src/deskpro deskpro.zip \
	&& rm -rf deskpro.zip

VOLUME /var/www/html

RUN rm -rf /etc/apache2/sites-enabled/000-default.conf

COPY deskpro.conf /etc/apache2/sites-enabled/deskpro.conf

COPY php.ini /usr/local/etc/php/

COPY deskpro-docker-* /usr/local/bin/

CMD ["deskpro-docker-cmd"]
