FROM php:8.0-apache

# Composer
ARG composer_ver=2.1.6
ARG composer_hash=756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3

# Arguments defined in docker-compose.yml
ARG user
ARG uid

RUN apt-get update \
    && apt-get install -y git unzip zip git npm exiftool \
    && apt-get install -y vim \
    && a2enmod ssl

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd pdo_mysql bcmath zip intl opcache exif mbstring

# Enable apache rewrite
RUN rm /etc/apache2/sites-available/000-default.conf
COPY /docker/sites-available/000-default.conf /etc/apache2/sites-available/

# RUN composer install

# RUN mkdir $APP_HOME/storage
# RUN mkdir $APP_HOME/storage/logs

COPY /docker/php.ini /etc/php/8.0/cli/conf.d/99-sail.ini

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

RUN a2enmod rewrite

# set our application folder as an environment variable
ENV APP_HOME /var/www/html/quiz

# copy source files
COPY . $APP_HOME

# WORKDIR $APP_HOME

RUN cd $APP_HOME && composer install --no-interaction && npm i && npm run prod

RUN chown -R www-data $APP_HOME/storage

RUN cd $APP_HOME && php artisan view:clear

USER $user
