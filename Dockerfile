# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM ubuntu:18.04

ENV LOG_STDOUT=**Boolean** \
    LOG_STDERR=**Boolean** \
    LOG_LEVEL=warn \
    ALLOW_OVERRIDE=All \
    DATE_TIMEZONE=UTC \
    TERM=dumb \
    NVM_DIR=/usr/local/nvm \
    NODE_VERSION=10.16.3 \
    NPM_VERSION=6.9.0 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
      && apt-get install -yqq --no-install-recommends software-properties-common \
      && add-apt-repository -y ppa:ondrej/php \
      && apt-get -yqq update \
      && apt-get install -yqq --no-install-recommends \
        php7.3 \
        php7.3-bz2 \
        php7.3-cgi \
        php7.3-cli \
        php7.3-common \
        php7.3-curl \
        php7.3-dev \
        php7.3-enchant \
        php7.3-fpm \
        php7.3-gd \
        php7.3-gmp \
        php7.3-imap \
        php7.3-interbase \
        php7.3-intl \
        php7.3-json \
        php7.3-ldap \
        php7.3-mysql \
        php7.3-opcache \
        php7.3-phpdbg \
        php7.3-pspell \
        php7.3-readline \
        php7.3-recode \
        php7.3-snmp \
        php7.3-sqlite3 \
        php7.3-sybase \
        php7.3-tidy \
        php7.3-xmlrpc \
        php7.3-xsl \
        php7.3-phar \
        php7.3-mbstring \
        php7.3-zip \
        unzip \
        wget \
        curl \
        sudo \
        snmp \
        vim \
        git \
        pv \
        iputils-ping \
        apache2 \
        patch \
        libapache2-mod-php7.3 \
        mariadb-common \
        mariadb-server \
        mariadb-client \
        openssh-client \
      && rm -rf /var/lib/apt/lists/*

# Install Composer.
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
  && composer global require "hirak/prestissimo:^0.3"
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Install Drush.
# RUN wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar \
#     && chmod +x drush.phar \
#    && mv drush.phar /usr/local/bin/drush

# Install node, npm, aquifer, and gulp.
RUN set -eux \
    && mkdir -p /tmp/node \
    && curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
    && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.gz" \
    && npm install -g npm@"$NPM_VERSION"
    # && npm install -g grunt

# Set up apache.
RUN  mkdir -p /root/project/docroot
COPY ./apache-vhost.conf /etc/apache2/sites-available/project.conf
RUN echo "<html><head><title>LOADED!</title></head><body><h1>LOADED!</h1></body></html>" > /root/project/docroot/index.html
RUN chown -R www-data:www-data /root/project/docroot && \
  chmod -R g+rwX /root/project/docroot && \
  chmod +rx /root && \
  a2enmod rewrite && \
  a2dissite 000-default && \
  a2ensite project && \
  rm -rf /root/project

# Set up Mysql.
RUN set -eux \
  && service mysql start \
  && mysql -e "CREATE DATABASE IF NOT EXISTS project" \
  && mysql -e "CREATE USER 'project'@'localhost' IDENTIFIED BY 'project'" \
  && mysql -e "GRANT ALL PRIVILEGES ON project.* TO 'project'@'localhost'"

WORKDIR /root

COPY entrypoint /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint

VOLUME /root
VOLUME /var/log/httpd
VOLUME /var/lib/mysql
VOLUME /var/log/mysql
VOLUME /etc/apache2

EXPOSE 80
EXPOSE 3306

ENTRYPOINT /usr/bin/entrypoint
CMD ['/bin/bash']
