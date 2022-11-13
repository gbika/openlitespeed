FROM debian:10-slim

ENV TINI_VERSION=v0.19.0

COPY ./lsws-conf /lsws-conf
COPY ./comodo /comodo
COPY ./entrypoint.sh /entrypoint.sh
COPY ./php.ini.file /php.ini.file

RUN apt-get update && apt-get install -y tini locales wget procps pkg-config && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "id_ID.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash && \
    apt-get update && apt-get install -y openlitespeed lsphp74 lsphp74-apcu lsphp74-apcu-dbgsym lsphp74-common lsphp74-curl lsphp74-dbg lsphp74-dev lsphp74-igbinary lsphp74-igbinary-dbgsym lsphp74-imap lsphp74-intl lsphp74-ldap lsphp74-memcached lsphp74-memcached-dbgsym lsphp74-modules-source lsphp74-msgpack lsphp74-msgpack-dbgsym lsphp74-mysql lsphp74-opcache lsphp74-pear lsphp74-pgsql lsphp74-pspell lsphp74-snmp lsphp74-sqlite3 lsphp74-sybase lsphp74-tidy && \
    apt-get clean
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /bin/sed /usr/bin/sed && \
    ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp74/bin/php /usr/bin/php && \
    ln -sf /usr/local/lsws/lsphp74/bin/pecl /usr/bin/pecl && \
    ln -sf /usr/local/lsws/lsphp74/bin/pear /usr/bin/pear && \
    rm -rf /usr/local/lsws/conf && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /comodo /usr/local/lsws/modsec/comodo && \
    mv /php.ini.file /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/comodo
RUN pecl channel-update pecl.php.net && \
    pecl install redis && \
    chmod a+x /entrypoint.sh

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]