FROM almalinux:8

ENV TINI_VERSION=v0.19.0

COPY ./lsws-conf /lsws-conf
COPY ./comodo /comodo
COPY ./entrypoint.sh /entrypoint.sh
COPY ./20-redis.ini /20-redis.ini

RUN dnf update -y && dnf install -y epel-release && \
    dnf install -y tini glibc-all-langpacks procps pkg-config gcc gcc-c++ make autoconf glibc rcs && \
    dnf install -y fontconfig freetype libX11 libXext libXrender libjpeg libpng xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 && \
    rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.3-1.el8.noarch.rpm && \
    sed -i 's/failovermethod=priority/#failovermethod=priority/' /etc/yum.repos.d/litespeed.repo && \
    dnf install -y openlitespeed && \
    dnf install -y lsphp80 lsphp80-common lsphp80-devel lsphp80-curl lsphp80-dbg lsphp80-imap lsphp80-intl lsphp80-ldap lsphp80-opcache lsphp80-mysqlnd lsphp80-pgsql lsphp80-mbstring lsphp80-pspell lsphp80-snmp lsphp80-sqlite3 lsphp80-gd lsphp80-xml lsphp80-process && \
    dnf clean all
RUN curl https://pecl.php.net/get/redis-5.3.7.tgz --output /redis-5.3.7.tgz && \
    cd / && \
    tar -zxvf /redis-5.3.7.tgz && \
    cd /redis-5.3.7 && \
    /usr/local/lsws/lsphp80/bin/phpize && \
    ./configure --enable-redis --with-php-config=/usr/local/lsws/lsphp80/bin/php-config && \
    make install && \
    mv /20-redis.ini /usr/local/lsws/lsphp80/etc/php.d/20-redis.ini
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /usr/local/lsws/lsphp80/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp80/bin/php /usr/bin/php && \
    mv /usr/local/lsws/conf /usr/local/lsws/conf-disabled && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /comodo /usr/local/lsws/modsec/comodo && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/comodo && \
    chmod a+x /entrypoint.sh && \
    rm -r /redis-5.3.7 && \
    rm -r /redis-5.3.7.tgz
RUN dnf remove -y lsphp73* && \
    rm -rf /usr/local/lsws/lsphp73

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

