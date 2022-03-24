# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
# Updated for drupal 9 requirements.
FROM ubuntu:18.04

ENV LOG_STDOUT=**Boolean** \
    LOG_STDERR=**Boolean** \
    LOG_LEVEL=warn \
    ALLOW_OVERRIDE=All \
    DATE_TIMEZONE=UTC \
    TERM=dumb \
    NVM_DIR=/usr/local/nvm \
    NODE_VERSION=15.14.0 \
    NPM_VERSION=7.7.6 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
      && apt-get install -yqq --no-install-recommends software-properties-common \
      && add-apt-repository -y ppa:ondrej/php \
      && apt-get -yqq update \
      && apt-get install -yqq --no-install-recommends \
        php7.4 \
        php7.4-bz2 \
        php7.4-cgi \
        php7.4-cli \
        php7.4-common \
        php7.4-curl \
        php7.4-dev \
        php7.4-enchant \
        php7.4-fpm \
        php7.4-gd \
        php7.4-gmp \
        php7.4-imap \
        php7.4-interbase \
        php7.4-intl \
        php7.4-json \
        php7.4-ldap \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-opcache \
        php7.4-phpdbg \
        php7.4-pspell \
        php7.4-readline \
        php7.4-snmp \
        php7.4-sqlite3 \
        php7.4-sybase \
        php7.4-tidy \
        php7.4-xmlrpc \
        php7.4-xsl \
        php7.4-phar \
        php7.4-mbstring \
        php7.4-zip \
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
        libapache2-mod-php7.4 \
        mysql-common \
        mysql-server \
        mysql-client \
        openssh-client \
        rsync \
      && rm -rf /var/lib/apt/lists/*

# Install Composer.
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --version=2.0.11 --filename=composer
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
  