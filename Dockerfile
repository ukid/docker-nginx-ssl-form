FROM ghcr.io/linuxserver/swag AS builder

ENV NGINX_VERSION 1.18.0

# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  wget

# Download sources
RUN wget -c http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx.tar.gz && \
  wget -c https://github.com/calio/form-input-nginx-module/archive/v0.12.tar.gz -O form-input-nginx-module.tar.gz && \
  wget -c https://github.com/vision5/ngx_devel_kit/archive/v0.3.1.tar.gz -O ngx_devel_kit.tar.gz && \
  tar zxvf nginx.tar.gz && \
  tar zxvf form-input-nginx-module.tar.gz && \
  tar zxvf ngx_devel_kit.tar.gz

RUN  CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p' | sed -n -e 's/--add-dynamic-module.*//p' | sed -n -e 's/--with-perl_modules_path=\/usr\/lib\/perl5\/vendor_perl//p' | sed -n -e 's/--with-http_perl_module=dynamic//p') && \
  cd nginx-$NGINX_VERSION && \
  ./configure $CONFARGS --add-dynamic-module=../ngx_devel_kit-0.3.1 --add-dynamic-module=../form-input-nginx-module-0.12 && \
  make



FROM ghcr.io/linuxserver/swag
# Extract the dynamic module NCHAN from the builder image
COPY --from=builder nginx-1.18.0/objs/ndk_http_module.so /usr/lib/nginx/modules/ndk_http_module.so
COPY --from=builder nginx-1.18.0/objs/ngx_http_form_input_module.so /usr/lib/nginx/modules/ngx_http_form_input_module.so
RUN echo "load_module \"modules/ndk_http_module.so\";" > /etc/nginx/modules/http_module.conf
RUN echo "load_module \"modules/ngx_http_form_input_module.so\";" > /etc/nginx/modules/http_form_input_module.conf
