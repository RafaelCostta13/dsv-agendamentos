FROM ruby:3.4.13-slim

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev postgresql-client git ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler --version 2.6.2 --no-document

ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
RUN groupadd --gid "${LOCAL_GID}" rails && \
    useradd --uid "${LOCAL_UID}" --gid "${LOCAL_GID}" --create-home rails && \
    chown rails:rails /rails

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# The first build bootstraps the lockfile; see README before homologation.
# After Gemfile.lock is exported, subsequent builds use the frozen dependency set.
COPY --chown=rails:rails Gemfile* .ruby-version ./
RUN if [ -f Gemfile.lock ]; then bundle config set --local frozen true; fi && \
    bundle _2.6.2_ install && \
    chown -R rails:rails /usr/local/bundle

COPY --chown=rails:rails . .
RUN mkdir -p log tmp/pids storage && chown -R rails:rails log tmp storage

USER rails:rails
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
