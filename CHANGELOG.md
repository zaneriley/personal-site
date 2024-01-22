# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- Various optional env vars in `config/runtime.exs` have defaults added to them
- Add `required: false` to `depends_on` in `docker-compose.yml` (requires Docker Compose v2.20.2+)

#### Languages and services

- Update `Elixir` to `1.16.0`
- Update `Node` to `20.6.1`
- Update `Postgres` to `16.0`

#### Back-end dependencies

- Update `credo` to `1.7.3`
- Update `ecto_sql` to `3.11.1`
- Update `excoveralls` to `0.18.0`
- Update `finch` to `0.17.0`
- Update `floki` to `0.35.2`
- Update `gettext` to `0.24.0`
- Update `heroicons` to `0.5.3`
- Update `jason` to `1.4.1`
- Update `phoenix_ecto` to `4.4.3`
- Update `phoenix_html` to `4.0.0`
- Update `phoenix_live_dashboard` to `0.8.3`
- Update `phoenix_live_view` to `0.20.3`
- Update `phoenix` to `1.7.10`
- Update `plug_cowboy` to `2.6.1`
- Update `postgrex` to `0.17.4`
- Update `swoosh` to `1.14.4`
- Update `telemetry_metrics` to `0.6.2`

#### Front-end dependencies

- Update `autoprefixer` to `10.4.17`
- Update `esbuild` to `0.19.11`
- Update `phoenix_html` to `4.0.0`
- Update `phoenix_live_view` to `0.20.3`
- Update `phoenix` to `1.7.10`
- Update `postcss-import` to `16.0.0`
- Update `postcss` to `8.4.33`
- Update `tailwindcss` to `3.4.1`
- Update `topbar` to `2.0.2`

## [0.8.0] - 2023-02-25

### Added

- Ability to customize `UID` and `GID` if you're not using `1000:1000` (check the `.env.example` file)
- Output `docker compose logs` in CI for easier debugging

#### Back-end dependencies

- Add `heroicons`

### Changed

- Reference `PORT` variable in the `docker-compose.yml` web service instead of hard coding `8000`
- Adjust Hadolint to exit > 0 if any style warnings are present
- Rename `esbuild.config.js` to `esbuild.config.mjs` and refactor config for esbuild 0.17+
- Adjust `assets/js/app.js` to use topbar 2.X
- Tons of file changes for upgrading from Phoenix 1.6 to 1.7

#### Languages and services

- Update `Elixir` to `1.14.3`
- Update `Node` to `18.10.0`
- Update `Postgres` to `15.2`

#### Back-end dependencies

- Update `ecto_sql` to `3.9.2`
- Update `excoveralls` to `0.15.3`
- Update `floki` to `0.34.0`
- Update `gettext` to `0.22.0`
- Update `jason` to `1.4.0`
- Update `phoenix_html` to `3.3.0`
- Update `phoenix_live_dashboard` to `0.7.2`
- Update `phoenix_live_reload` to `1.4.1`
- Update `phoenix_live_view` to `0.18.16`
- Update `phoenix` to `1.7.0`
- Update `plug_cowboy` to `2.6.0`
- Update `postgrex` to `0.16.5`
- Update `swoosh` to `1.9.1`

#### Front-end dependencies

- Update `autoprefixer` to `10.4.13`
- Update `esbuild` to `0.17.8`
- Update `phoenix_html` to `3.3.0`
- Update `phoenix_live_view` to `0.18.16`
- Update `phoenix` to `1.7.0`
- Update `postcss-import` to `15.1.0`
- Update `postcss` to `8.4.21`
- Update `tailwindcss` to `3.2.6`
- Update `topbar` to `2.0.1`

### Removed

- `set -o nounset` from `run` script since it's incompatible with Bash 3.2 (default on macOS)

## [0.7.0] - 2022-09-09

### Added

- `set -o nounset` to `run` script to exit if there's any undefined variables

### Changed

- Switch Docker Compose `env_file` to `environment` for `postgres` to avoid needless recreates on `.env` changes
- Replace override file with Docker Compose profiles for running specific services
- Update Github Actions to use Ubuntu 22.04
- Adjust `x-assets` to use a `stop_grace_period` of `0` for faster CTRL+c times in dev

#### Languages and services

- Update `Elixir` to `1.14.0`
- Update `Node` to `16.15.1`
- Update `PostgreSQL` to `14.5`

#### Back-end dependencies

- Update `credo` to `1.6.7`
- Update `ecto_sql` to `3.8.3`
- Update `excoveralls` to `0.14.6`
- Update `floki` to `0.33.X`
- Update `gettext` to `0.20.0`
- Update `phoenix_live_view` to `0.17.11`
- Update `phoenix` to `1.6.12`
- Update `postgrex` to `0.16.4`
- Update `swoosh` to `1.8.0`

#### Front-end dependencies

- Update `autoprefixer` to `10.4.8`
- Update `esbuild` to `0.15.2`
- Update `phoenix_live_view` to `0.17.11`
- Update `phoenix` to `1.6.11`
- Update `postcss` to `8.4.16`
- Update `tailwindcss` to `3.1.8`

## Removed

- Deleted `:gettext` in `compilers` in `mix.exs` (this was a new compiler warning)
- Drop support for Docker Compose v1 (mainly to use profiles in an optimal way, it's worth it!)

## [0.6.0] - 2022-05-15

### Added

- [esbuild-copy-static-files](https://github.com/nickjj/esbuild-copy-static-files) plugin to drastically improve Phoenix Live Reload (check the `esbuild.config.js` file)

### Changed

- Only show Topbar if a response takes longer than 500ms to load in `assets/js/app.js`
- Refactor `/up/` endpoint into its own controller and add `/up/databases` as a second URL

#### Languages and services

- Update `Elixir` to `1.13.4`
- Update `Node` to `16.14.2`
- Update `PostgreSQL` to `14.2`

#### Back-end dependencies

- Update `credo` to `1.6.4`
- Update `ecto_sql` to `3.8.1`
- Update `excoveralls` to `0.14.5`
- Update `gettext` to `0.19.1`
- Update `phoenix_live_dashboard` to `0.6.5`
- Update `phoenix_live_view` to `0.17.9`
- Update `phoenix` to `1.6.8`
- Update `postgrex` to `0.16.3`
- Update `swoosh` to `1.6.6`

#### Front-end dependencies

- Update `autoprefixer` to `10.4.7`
- Update `esbuild` to `0.14.39`
- Update `phoenix_live_view` to `0.17.9`
- Update `phoenix` to `1.6.8`
- Update `postcss-import` to `14.1.0`
- Update `postcss` to `8.4.13`
- Update `tailwindcss` to `3.0.24`

### Fixed

- `COPY --chown=node:node ../ ../` has been fixed to be `COPY --chown=node:node . ..`
- Ensure the `rename-project` script renames your project after adding custom non-web tests

## [0.5.0] - 2021-12-26

### Changed

- Update `assets/tailwind.config.js` based on the new TailwindCSS v3 defaults
- Replace all traces of Webpack with esbuild
- Move JS and CSS from `assets/app` to `assets/js` and `assets/css`
- Rename `webpack` Docker build stage to `assets`
- Copy all files into the `assets` build stage to simplify things
- Replace `cp -a` with `cp -r` in Docker entrypoint to make it easier to delete older assets
- Rename `run hadolint` to `run lint:dockerfile`
- Rename `run credo` to `run lint`
- Rename `run coveralls` to `run test:coverage`
- Rename `run coveralls:details` to `run test:coverage:details`
- Rename `run bash` to `run shell`

#### Languages and services

- Update `Elixir` to `1.13.1`
- Update `Node` to `16.13.1`

#### Back-end dependencies

- Update `gettext` to `0.19.0`
- Update `json` to `1.3.0`
- Update `phoenix_html` to `3.2.0`
- Update `phoenix` to `1.6.5`

#### Front-end dependencies

- Update `autoprefixer` to `10.4.0`
- Update `phoenix_html` to `3.1.0`
- Update `phoenix` to `1.6.5`
- Update `postcss` to `8.4.5`
- Update `tailwindcss` to `3.0.7`

### Removed

- Deleting old assets in the Docker entrypoint (it's best to handle this out of band in a cron job, etc.)

## [0.4.0] - 2021-12-09

### Added

- Lint Dockerfile with <https://github.com/hadolint/hadolint>

### Changed

#### Languages and services

- Update `Elixir` to `1.13.0`
- Update `Node` to `14.18.1`
- Update `PostgreSQL` to `14.1` and switch to Debian Bullseye Slim

#### Back-end dependencies

- Update `credo` to `1.6.1`
- Update `ecto_sql` to `3.7.1`
- Update `excoveralls` to `0.14.4`
- Update `floki` to `0.32.0`
- Update `phoenix_html` to `3.1.0`
- Update `phoenix_live_dashboard` to `0.6.2`
- Update `phoenix_live_view` to `0.17.5`
- Update `phoenix` to `1.6.4`
- Update `swoosh` to `1.5.2`

#### Front-end dependencies

- Update `@babel/core` to `7.16.0`
- Update `@babel/preset-env` to `7.16.4`
- Update `@babel/register` to `7.16.0`
- Update `autoprefixer` to `10.4.0`
- Update `babel-loader` to `8.2.3`
- Update `copy-webpack-plugin` to `10.0.0`
- Update `css-loader` to `6.5.1`
- Update `css-minimizer-webpack-plugin` to `3.2.0`
- Update `mini-css-extract-plugin` to `2.4.5`
- Update `phoenix_live_view` to `0.17.5`
- Update `phoenix` to `1.6.2`
- Update `postcss-loader` to `6.2.1`
- Update `postcss` to `8.4.3`
- Update `tailwindcss` to `2.2.19`
- Update `webpack-cli` to `4.9.1`
- Update `webpack` to `5.64.4`

### Fixed

- `channel_case.ex` had the old `setup tags` code, now it's been updated
- Ensure the prod Elixir Docker build stage is also using Elixir 1.13.0

## [0.3.0] - 2021-09-25

### Added

- Swoosh back-end dependency for sending emails (introduced by Phoenix 1.6)

### Changed

- `tailwind.config.js` now uses `'/app/lib/portfolio_web/**/*.*ex'` to match Elixir and all template types
- Convert all templates to HEEx
- Update all `test/support/*_case.ex` files to use Phoenix 1.6's updated `setup tags do ... end`

#### Languages and services

- Update `Elixir` to `1.12.3`
- Update `PostgreSQL` to `13.4`

#### Back-end dependencies

- Update `ecto_sql` to `3.7.0`
- Update `excoveralls` to `0.14.2`
- Update `phoenix_ecto` to `4.4.0`
- Update `phoenix_html` to `3.0.4`
- Update `phoenix_live_dashboard` to `0.5.2`
- Update `phoenix_live_reload` to `1.3.3`
- Update `phoenix_live_view` to `0.16.4`
- Update `phoenix` to `1.6.0`
- Update `plug_cowboy` to `2.5.2`
- Update `telemetry_metrics` to `0.6.1`
- Update `telemetry_poller` to `1.0.0`

#### Front-end dependencies

- Update `@babel/core` to `7.15.5`
- Update `@babel/preset-env` to `7.15.4`
- Update `@babel/register` to `7.15.3`
- Update `autoprefixer` to `10.3.4`
- Update `copy-webpack-plugin` to `9.0.1`
- Update `css-loader` to `6.2.0`
- Update `css-minimizer-webpack-plugin` to `3.0.2`
- Update `mini-css-extract-plugin` to `2.2.2`
- Update `phoenix_live_view` to `0.16.0`
- Update `phoenix_live_view` to `0.16.3`
- Update `phoenix` to `1.6.0-rc.0`
- Update `postcss-loader` to `6.1.1`
- Update `postcss` to `8.3.6`
- Update `tailwindcss` to `2.2.9`
- Update `webpack-cli` to `4.8.0`
- Update `webpack` to `5.52.0`

### Fixed

- `root.html.heex`'s meta description referencing Django instead of Phoenix

## [0.2.0] - 2021-06-18

### Added

- `bin/rename-project` script to assist with renaming the project

### Changed

- Use the Docker Compose spec in `docker-compose.yml` (removes `version:` property)
- Update Tailwind from `2.1.1` to `2.2.2`
- Update all Webpack related dependencies to their latest versions
- Update Elixir from `1.11.4` to `1.12.1`
- Update PostgreSQL from `13.2` to `13.3`
- Update `phoenix` from `1.5.8` to `1.5.9`
- Update `ecto_sql` from `3.6.0` to `3.6.2`
- Update `floki` from `0.27.x` to `0.31.x`
- Update `plug_cowboy` from `2.4.1` to `2.5.0`
- Update `postgrex` from `0.15.8` to `0.15.9`
- Update `excoveralls` from `0.14.0` to `0.14.1`
- Update `credo` from `1.5.5` to `1.5.6`
- Update `phoenix_live_view` from `0.15.4` to `0.15.7`

## [0.1.0] - 2021-04-15

### Added

- Everything!

[Unreleased]: https://github.com/nickjj/docker-phoenix-example/compare/0.8.0...HEAD
[0.8.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/nickjj/docker-phoenix-example/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/nickjj/docker-phoenix-example/releases/tag/0.1.0
