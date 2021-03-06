FROM hyperknot/baseimage16:1.0.2

MAINTAINER friends@niiknow.org

ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 \
    TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive \
    NGINX_VERSION=1.13.4-1~xenial_amd64.deb

ADD ./build/nginx_${NGINX_VERSION} /tmp

# ADD ./build/nginx-dbg_${NGINX_VERSION} /tmp

# start
RUN \
    cd /tmp \

# increase ulimit
    && echo "\n\n* soft nofile 800000\n* hard nofile 800000\n\n" >> /etc/security/limits.conf \

# add nginx repo
    && curl -s https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \

# update repo
    && apt-get update -y && apt-get upgrade -y --no-install-recommends --no-install-suggests \
    && apt-get install -y --no-install-recommends --no-install-suggests \
       nano libgd3 gettext-base unzip rsync \
    && dpkg --configure -a \

# install nginx
    && dpkg -i nginx_${NGINX_VERSION} \

#    && dpkg -i nginx-dbg_${NGINX_VERSION} \

# delete dummy conf
    && rm -rf /etc/nginx/conf.d/default.conf \

# re-enable all default services
    && rm -f /etc/service/syslog-forwarder/down \
    && rm -f /etc/service/cron/down \
    && rm -f /etc/service/syslog-ng/down \
    && rm -f /core \

# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && service nginx stop && update-rc.d -f nginx disable \

# cleanup
    && apt-get clean -y && apt-get autoclean -y \
    && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

ADD ./files /

RUN \
# generate fake ssl for server conf, allow for replacing it later
    bash /root/bin/placeholder-ssl.sh \
    && mkdir -p /app-start/etc \

# redirect /etc/nginx
    && mv /etc/nginx /app-start/etc/nginx \
    && rm -rf /etc/nginx \
    && ln -s /app/etc/nginx /etc/nginx \

# redirect logs
    && mkdir -p /app-start/var/log \
    && mv /var/log/nginx /app-start/var/log/nginx \
    && rm -rf /var/log/nginx \
    && ln -s /app/var/log/nginx /var/log/nginx

EXPOSE 80 443

VOLUME ["/app"]

CMD ["/sbin/my_init"]
