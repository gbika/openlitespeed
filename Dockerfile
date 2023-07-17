FROM almalinux:8

COPY ./lsws-conf /lsws-conf
COPY ./rules /rules
COPY ./entrypoint.sh /entrypoint.sh
COPY ./20-redis.ini /20-redis.ini
COPY ./20-oci8.ini /20-oci8.ini
COPY ./mem-limit.ini /mem-limit.ini
COPY ./max-file-upload.ini /max-file-upload.ini

RUN dnf update -y && dnf install -y epel-release && \
    dnf install -y glibc-all-langpacks procps pkg-config gcc gcc-c++ make autoconf glibc rcs unzip libaio.i686 libaio.x86_64 && \
    dnf install -y fontconfig freetype libX11 libXext libXrender libjpeg libpng xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 && \
    rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.3-1.el8.noarch.rpm && \
    sed -i 's/failovermethod=priority/#failovermethod=priority/' /etc/yum.repos.d/litespeed.repo && \
    dnf install -y openlitespeed && \
    dnf install -y lsphp82 lsphp82-common lsphp82-devel lsphp82-curl lsphp82-dbg lsphp82-imap lsphp82-intl lsphp82-ldap lsphp82-opcache lsphp82-mysqlnd lsphp82-pgsql lsphp82-mbstring lsphp82-pspell lsphp82-snmp lsphp82-sqlite3 lsphp82-gd lsphp82-xml lsphp82-process lsphp82-sodium && \
    dnf clean all
    # REDIS MAKE
RUN curl https://pecl.php.net/get/redis-5.3.7.tgz --output /redis-5.3.7.tgz && \
    cd / && \
    tar -zxvf /redis-5.3.7.tgz && \
    cd /redis-5.3.7 && \
    /usr/local/lsws/lsphp82/bin/phpize && \
    ./configure --enable-redis --with-php-config=/usr/local/lsws/lsphp82/bin/php-config && \
    make install && \
    mv /20-redis.ini /usr/local/lsws/lsphp82/etc/php.d/20-redis.ini && \
    rm -r /redis-5.3.7 && \
    rm -r /redis-5.3.7.tgz
    # LSWS PREP
RUN ln -sf /usr/bin/tini /sbin/tini && \
    ln -sf /usr/local/lsws/lsphp82/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp82/bin/php /usr/bin/php && \
    mv /usr/local/lsws/conf /usr/local/lsws/conf-disabled && \
    mv /lsws-conf /usr/local/lsws/conf && \
    mkdir -p /usr/local/lsws/modsec && \
    mv /rules /usr/local/lsws/modsec/rules && \
    chown lsadm:lsadm -R /usr/local/lsws/conf && \
    chown lsadm:lsadm -R /usr/local/lsws/modsec/rules && \
    mv /mem-limit.ini /usr/local/lsws/lsphp82/etc/php.d/mem-limit.ini && \
    mv /max-file-upload.ini /usr/local/lsws/lsphp82/etc/php.d/max-file-upload.ini && \
    chmod a+x /entrypoint.sh
    # ORCLE INSTANT CLIENT
    # MKDIR and download Oracle Instant Client
RUN mkdir -p /usr/oracle && \
    curl https://download.oracle.com/otn_software/linux/instantclient/2110000/instantclient-basic-linux.x64-21.10.0.0.0dbru.zip --output /usr/oracle/oic.zip && \
    curl https://download.oracle.com/otn_software/linux/instantclient/2110000/instantclient-sdk-linux.x64-21.10.0.0.0dbru.zip --output /usr/oracle/sdk.zip && \
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
RUN curl https://pecl.php.net/get/oci8-3.3.0.tgz --output /oci8-3.3.0.tgz && \
    cd / && \
    tar -zxvf /oci8-3.3.0.tgz && \
    cd /oci8-3.3.0 && \
    /usr/local/lsws/lsphp82/bin/phpize && \
    ./configure -with-oci8=instantclient,/usr/oracle/instantclient_21_10 --with-php-config=/usr/local/lsws/lsphp82/bin/php-config && \
    make install && \
    mv /20-oci8.ini /usr/local/lsws/lsphp82/etc/php.d/20-oci8.ini && \
    rm -r /oci8-3.3.0 && \
    rm -r /oci8-3.3.0.tgz

WORKDIR /var/www/vhosts/localhost

ENTRYPOINT ["/entrypoint.sh"]
