# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.8
FROM ruby:$RUBY_VERSION-slim as base

# Rails application directory
WORKDIR /app

# Set production environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage for dependencies and assets
FROM base as build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application source code
COPY . .

# Precompile bootsnap cache for faster startup
RUN bundle exec bootsnap precompile app/ lib/

# Precompile static assets for production without requiring production credentials
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final production stage
FROM base

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq-dev postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy compiled gems and application from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /app /app

# Run as non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Set entrypoint
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Default command to start Puma
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
