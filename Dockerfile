FROM php:7.3-apache

RUN apt-get update

# 0. Paquetes necesarios

RUN apt-get install -y \
    git nano \
    zip \
    curl \
    sudo \
    unzip \
    libzip-dev \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ \
    libedit-dev \
    libreadline-dev \
    libxml2-dev libonig-dev \
    libpq-dev \
    tdsodbc freetds-common unixodbc-dev \
    software-properties-common libcurl4-gnutls-dev

RUN (curl -sL https://deb.nodesource.com/setup_14.x | bash -)

RUN apt-get install -y \
    nodejs libc-client-dev libkrb5-dev

# 2. apache configs + document root
#ENV APACHE_DOCUMENT_ROOT=/var/www/html/
#RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
#RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
#RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    curl\
    bz2 mbstring \
    intl \
    bcmath \
    opcache \
    calendar \
    zip \
    gd xml \
    pgsql pdo_pgsql \
    tokenizer ctype json 

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && docker-php-ext-install imap

# 1. Limpieza de Cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 5. composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY virtualhost.conf /etc/apache2/sites-available/

#COPY /codeigniter-appname/ /var/www/html/codeigniter-appname/
COPY . /var/www/html/

##Descomentar si es primera vez que se ejecuta la imagen
#RUN (cd /var/www/html/ ; composer install -vvv)
#RUN (cd /var/www/html/ ; php artisan key:generate)

RUN (cd /etc/apache2/sites-available ; a2ensite virtualhost.conf)

# 6. we need a user with the same UID/GID with host user
# so when we execute CLI commands, all the host file's ownership remains intact
# otherwise command from inside container will create root-owned files and directories
ARG uid=1000
RUN useradd -G www-data,root -u $uid -d /home/tecnologia tecnologia
RUN mkdir -p /home/tecnologia/.composer && \
    chown -R tecnologia:tecnologia /home/tecnologia

RUN chmod 777 -R /var/www \
    && chown -R www-data:www-data /var/www \
    && chsh -s /bin/bash www-data

RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

