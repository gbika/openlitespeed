FROM almalinux:8

ENV TINI_VERSION=v0.19.0

COPY ./lsws-conf /lsws-conf
COPY ./comodo /comodo
COPY ./entrypoint.sh /entrypoint.sh
COPY ./20-redis.ini /20-redis.ini
COPY ./20-oci8.ini /20-oci8.ini
COPY ./mem-limit.ini /mem-limit.ini

RUN dnf update -y && dnf install -y epel-release && \
    dnf install -y tini glibc-all-langpacks procps pkg-config gcc gcc-c++ make autoconf glibc rcs unzip libaio.i686 libaio.x86_64 && \
    dnf install -y fontconfig freetype libX11 libXext libXrender libjpeg libpng xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 && \
    rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.3-1.el8.noarch.rpm && \
    sed -i 's/failovermethod=priority/#failovermethod=priority/' /etc/yum.repos.d/litespeed.repo && \
    dnf install -y ols-pagespeed && \
    dnf install -y lsphp81 lsphp81-common lsphp81-devel lsphp81-curl lsphp81-dbg lsphp81-imap lsphp81-intl lsphp81-ldap lsphp81-opcache lsphp81-mysqlnd lsphp81-pgsql lsphp81-mbstring lsphp81-pspell lsphp81-snmp lsphp81-sqlite3 lsphp81-gd lsphp81-xml lsphp81-process lsphp81-sodium && \
    dnf clean all
    # REDIS MAKE
RUN curl https://pecl.php.net/get/redis-5.3.7.tgz --output /redis-5.3.7.tgz && \
    cd / && \
    tar -zxvf /redis-5.3.7.tgz && \
    cd /redis-5.3.7 && \
    /usr/local/lsws/lsphp81/bin/phpize && \
    ./configure --enable-redis --with-php-config=/usr/local/lsws/lsphp81/bin/php-config && \
    make install && \
    mv /20-redis.ini /usr/local/lsws/lsphp81/etc/php.d/20-redis.ini && \
    mv /mem-limit.ini /usr/local/lsws/lsphp81/etc/php.d/mem-limit.ini
    # LSWS PREP
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /usr/local/lsws/lsphp81/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp81/bin/php /usr/bin/php && \
    mv /usr/local/lsws/conf /usr/local/lsws/conf-disabled && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /comodo /usr/local/lsws/modsec/comodo && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/comodo && \
    chmod a+x /entrypoint.sh
    # ORCLE INSTANT CLIENT
    # MKDIR and download Oracle Instant Client
RUN mkdir -p /usr/oracle && \
    curl https://download.oracle.com/otn_software/linux/instantclient/217000/instantclient-basic-linux.x64-21.7.0.0.0dbru.zip --output /usr/oracle/oic.zip && \
    curl https://download.oracle.com/otn_software/linux/instantclient/217000/instantclient-sdk-linux.x64-21.7.0.0.0dbru.zip --output /usr/oracle/sdk.zip && \
    # Unzip Oracle Instant Client
    cd /usr/oracle && \
    unzip oic.zip && \
    unzip sdk.zip && \
    # Clean downloaded ZIP
    rm -f oic.zip && \
    rm -f sdk.zip && \
    # Add shared lib config
    echo /usr/oracle > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig
    # OCI8 MAKE
RUN curl https://pecl.php.net/get/oci8-3.2.1.tgz --output /oci8-3.2.1.tgz && \
    cd / && \
    tar -zxvf /oci8-3.2.1.tgz && \
    cd /oci8-3.2.1 && \
    /usr/local/lsws/lsphp81/bin/phpize && \
    ./configure -with-oci8=instantclient,/usr/oracle/instantclient_21_7 --with-php-config=/usr/local/lsws/lsphp81/bin/php-config && \
    make install && \
    mv /20-oci8.ini /usr/local/lsws/lsphp81/etc/php.d/20-oci8.ini && \
    rm -r /oci8-3.2.1 && \
    rm -r /oci8-3.2.1.tgz

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

