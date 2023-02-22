FROM almalinux:8

ENV TINI_VERSION=v0.19.0

COPY ./lsws-conf /lsws-conf
COPY ./comodo /comodo
COPY ./entrypoint.sh /entrypoint.sh
COPY ./20-redis.ini /20-redis.ini
COPY ./mem-limit.ini /mem-limit.ini

RUN dnf update -y && dnf install -y epel-release && \
    dnf install -y tini glibc-all-langpacks procps pkg-config gcc gcc-c++ make autoconf glibc rcs && \
    dnf install -y fontconfig freetype libX11 libXext libXrender libjpeg libpng xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 && \
    rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.3-1.el8.noarch.rpm && \
    sed -i 's/failovermethod=priority/#failovermethod=priority/' /etc/yum.repos.d/litespeed.repo && \
    dnf install -y openlitespeed && \
    dnf install -y lsphp82 lsphp82-common lsphp82-devel lsphp82-curl lsphp82-dbg lsphp82-imap lsphp82-intl lsphp82-ldap lsphp82-opcache lsphp82-mysqlnd lsphp82-pgsql lsphp82-mbstring lsphp82-pspell lsphp82-snmp lsphp82-sqlite3 lsphp82-gd lsphp82-xml lsphp82-process lsphp82-sodium && \
    dnf clean all
RUN curl https://pecl.php.net/get/redis-5.3.7.tgz --output /redis-5.3.7.tgz && \
    cd / && \
    tar -zxvf /redis-5.3.7.tgz && \
    cd /redis-5.3.7 && \
    /usr/local/lsws/lsphp82/bin/phpize && \
    ./configure --enable-redis --with-php-config=/usr/local/lsws/lsphp82/bin/php-config && \
    make install && \
    mv /20-redis.ini /usr/local/lsws/lsphp82/etc/php.d/20-redis.ini && \
    mv /mem-limit.ini /usr/local/lsws/lsphp82/etc/php.d/mem-limit.ini
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /usr/local/lsws/lsphp82/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp82/bin/php /usr/bin/php && \
    mv /usr/local/lsws/conf /usr/local/lsws/conf-disabled && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /comodo /usr/local/lsws/modsec/comodo && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/comodo && \
    chmod a+x /entrypoint.sh && \
    rm -r /redis-5.3.7 && \
    rm -r /redis-5.3.7.tgz

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

