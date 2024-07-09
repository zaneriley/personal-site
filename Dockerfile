# Stage 1: Build assets
FROM node:20.6.1-bookworm-slim AS assets

LABEL maintainer="Zane Riley <zaneriley@gmail.com>"

WORKDIR /app/assets

ARG UID=1000
ARG GID=1000

# Install build dependencies and clean up apt cache
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  # Update node user and group IDs and set ownership
  && groupmod -g "${GID}" node && usermod -u "${UID}" -g "${GID}" node \
  && mkdir -p /node_modules && chown node:node -R /node_modules /app

USER node

# Copy package.json and yarn files and install dependencies
COPY --chown=node:node assets/package.json assets/*yarn* ./
RUN yarn install && yarn cache clean

ARG NODE_ENV="production"
ENV NODE_ENV="${NODE_ENV}" \
    PATH="${PATH}:/node_modules/.bin" \
    USER="node"

# Copy application code
COPY --chown=node:node . ..

# Conditionally build assets based on NODE_ENV
RUN if [ "${NODE_ENV}" != "development" ]; then \
  ../run yarn:build:js && ../run yarn:build:css; else mkdir -p /app/priv/static; fi

###############################################################################

# Stage 2: Development environment
FROM elixir:1.17.1-slim AS dev
LABEL maintainer="Zane Riley <zaneriley@gmail.com>"

WORKDIR /app

ARG UID=1000
ARG GID=1000

# Install development dependencies and clean up apt cache
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates build-essential curl inotify-tools \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  # Create elixir user and group and set ownership
  && groupadd -g "${GID}" elixir \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" elixir \
  && mkdir -p /mix && chown elixir:elixir -R /mix /app

USER elixir

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

ARG MIX_ENV="prod"
ENV MIX_ENV="${MIX_ENV}" \
    USER="elixir"

# Copy mix files and fetch dependencies based on MIX_ENV
COPY --chown=elixir:elixir mix.* ./
RUN if [ "${MIX_ENV}" = "dev" ]; then \
  mix deps.get --verbose; else mix deps.get --only "${MIX_ENV}"; fi

# Copy config files and compile dependencies  
COPY --chown=elixir:elixir config/config.exs config/"${MIX_ENV}".exs config/
RUN mix deps.compile

# Copy built assets from Stage 1
COPY --chown=elixir:elixir --from=assets /app/priv/static /public
COPY --chown=elixir:elixir . .

# Conditionally digest assets, create a release, and clean up based on MIX_ENV
RUN if [ "${MIX_ENV}" != "dev" ]; then \
  ln -s /public /app/priv/static \
    && mix phx.digest && mix release && rm -rf /app/priv/static; fi

  
ENTRYPOINT ["/app/bin/docker-entrypoint-web"]

EXPOSE 8000

CMD ["iex", "-S", "mix", "phx.server"]

###############################################################################

# Stage 3: Production environment
FROM elixir:1.17.1-slim AS prod
LABEL maintainer="Zane Riley <zaneriley@gmail.com>"

WORKDIR /app

ARG UID=1000
ARG GID=1000

# Install production dependencies and clean up apt cache
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  # Create elixir user and group and set ownership
  && groupadd -g "${GID}" elixir \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" elixir \
  && chown elixir:elixir -R /app

USER elixir

ENV USER=elixir

# Copy built assets and release from Stage 2
COPY --chown=elixir:elixir --from=dev /public /public
COPY --chown=elixir:elixir --from=dev /mix/_build/prod/rel/portfolio ./
COPY --chown=elixir:elixir bin/docker-entrypoint-web bin/

ENTRYPOINT ["/app/bin/docker-entrypoint-web"]

EXPOSE 8000

CMD ["bin/portfolio", "start"]