# Lobsters
#
# VERSION latest

FROM ruby:2.3-alpine

# Setting this to true will retain linux
# build tools and dev packages.
ARG developer_build=false
# Args for labels.
ARG VCS_REF
ARG BUILD_DATE

#Labels
LABEL maintainer="James Brink, brink.james@gmail.com" \
      decription="Lobsters Rails Project" \
      version="latest" \
      org.label-schema.name="lobsters" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/jamesbrink/docker-lobsters" \
      org.label-schema.schema-version="1.0.0-rc1"

# Create lobsters user and group.
RUN addgroup -S lobsters && adduser -S -h /lobsters -s /bin/sh -G lobsters lobsters

# Copy Gemfile to container.
COPY ./lobsters/Gemfile ./docker-assets /lobsters/

# Install needed runtime & development dependencies. If this is a developer_build we don't remove
# the build-deps after doing a bundle install.
RUN apk --no-cache --update --virtual deps add mariadb-client-libs sqlite-libs tzdata nodejs \
    && apk --no-cache --virtual build-deps add build-base gcc mariadb-dev linux-headers sqlite-dev \
    && export PATH=/lobsters/.gem/ruby/2.3.0/bin:$PATH \
    && export GEM_HOME="/lobsters/.gem" \
    && export GEM_PATH="/lobsters/.gem" \
    && export BUNDLE_PATH="/lobsters/.bundle" \
    && cd /lobsters \
    && su lobsters -c "gem install bundler --user-install" \
    && su lobsters -c "bundle install --no-cache" \
    && if [ "${developer_build}" != "true" ]; then apk del build-deps; fi

# Copy lobsters into the container.
COPY ./lobsters /lobsters

RUN ls -lart /lobsters

# Set proper permissions and move assets and configs.
RUN chown -R lobsters:lobsters /lobsters \
    && mv /lobsters/docker-entrypoint.sh /usr/local/bin/ \
    && chmod 755 /usr/local/bin/docker-entrypoint.sh \
    && rm /lobsters/Gemfile.lock

# Drop down to unprivileged users
USER lobsters

# Set our working directory.
WORKDIR /lobsters/

# Set environment variables.
ENV MARIADB_HOST="mariadb" \
    MARIADB_PORT="3306" \
    MARIADB_PASSWORD="password" \
    MARIADB_USER="root" \
    LOBSTER_DATABASE="lobsters" \
    LOBSTER_HOSTNAME="localhost" \
    LOBSTER_SITE_NAME="Example News" \
    RAILS_ENV="development" \
    SECRET_KEY="" \
    GEM_HOME="/lobsters/.gem" \
    GEM_PATH="/lobsters/.gem" \
    BUNDLE_PATH="/lobsters/.bundle" \
    PATH="/lobsters/.gem/ruby/2.3.0/bin:$PATH"

# Expose HTTP port.
EXPOSE 3000

# Execute our entry script.
CMD ["/usr/local/bin/docker-entrypoint.sh"]
