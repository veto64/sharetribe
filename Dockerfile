FROM ruby:2.6.5-buster

MAINTAINER veto <veto@myridia.com>

ENV REFRESHED_AT 2019-09-20

RUN apt-get update && apt-get dist-upgrade -y

RUN apt-get update && apt-get install -y \
  apache2 \
  apt-transport-https \ 
  lsb-release \
  ca-certificates \
  curl \
  wget \	      
  apt-utils \
  openssh-server \
  supervisor \
  default-mysql-client \
  libpcre3-dev \
  gcc \
  make \
  emacs-nox \ 
  git \
  gnupg \
  sqlite3 \
  sphinxsearch \
  redis-server \
  unzip 


# Prevent GPG from trying to bind on IPv6 address even if there are none
RUN mkdir ~/.gnupg \
  && chmod 600 ~/.gnupg \
  && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

#
# Node (based on official docker node image)
#

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 10.15.3

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs



# Install base gems  
ENV BUNDLE_BIN="/opt/app/vendor/bundle"
RUN gem install bundler foreman 
RUN useradd -m -s /bin/bash app \
&& mkdir /opt/app /opt/app/client /opt/app/log /opt/app/tmp && chown -R app:app /opt/app

WORKDIR /opt/app
ENV RAILS_ENV production
USER root

# set webserver files
run mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor; 

ENV GEM_HOME="/opt/app/vendor/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH


# Set the service
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 80 5000 3000

CMD ["/usr/bin/supervisord"]

