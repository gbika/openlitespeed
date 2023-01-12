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
    dnf install -y lsphp81 lsphp81-common lsphp81-devel lsphp81-curl lsphp81-dbg lsphp81-imap lsphp81-intl lsphp81-ldap lsphp81-opcache lsphp81-mysqlnd lsphp81-pgsql lsphp81-mbstring lsphp81-pspell lsphp81-snmp lsphp81-sqlite3 lsphp81-gd lsphp81-xml lsphp81-process lsphp81-sodium && \
    dnf clean all
RUN curl https://pecl.php.net/get/redis-5.3.7.tgz --output /redis-5.3.7.tgz && \
    cd / && \
    tar -zxvf /redis-5.3.7.tgz && \
    cd /redis-5.3.7 && \
    /usr/local/lsws/lsphp81/bin/phpize && \
    ./configure --enable-redis --with-php-config=/usr/local/lsws/lsphp81/bin/php-config && \
    make install && \
    mv /20-redis.ini /usr/local/lsws/lsphp81/etc/php.d/20-redis.ini
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /usr/local/lsws/lsphp81/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp81/bin/php /usr/bin/php && \
    mv /usr/local/lsws/conf /usr/local/lsws/conf-disabled && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /comodo /usr/local/lsws/modsec/comodo && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/comodo && \
    chmod a+x /entrypoint.sh && \
    rm -r /redis-5.3.7 && \
    rm -r /redis-5.3.7.tgz
RUN dnf remove -y lsphp73*

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

