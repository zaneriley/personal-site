<p align="center">
  <img src="https://github.com/zaneriley/personal-site/blob/main/logo.png" alt="Zane Riley Portfolio Logo" width="500"/>
</p>

# Zane Riley's Product Design Portfolio (WIP)

<p align="left">
    <img src="https://img.shields.io/website?url=https%3A%2F%2Fzaneriley.com&up_message=online&down_message=offline&label=portfolio" alt="Website Status" />
    <img src="https://img.shields.io/github/actions/workflow/status/zaneriley/personal-site/ci.yml" alt="GitHub Actions Workflow Status" />
    <a href='https://coveralls.io/github/zaneriley/personal-site?'><img src='https://coveralls.io/repos/github/zaneriley/personal-site/badge.svg?branch=main' alt='Coverage Status' /></a>
</p>

<p align="left">
  <img src="https://img.shields.io/github/license/zaneriley/personal-site" alt="GitHub License" />
  <img src="https://img.shields.io/github/stars/zaneriley/personal-site?style=social" alt="Github Stars" />
</p>

<p align="left">
  <a href="#introduction">Introduction</a> •
  <a href="#features">Features</a> •
  <a href="#technical-details">Technical Details</a> •
  <a href="#development-and-deployment">Development and Deployment</a> •
  <a href="#future-improvements">Future Improvements</a> •
  <a href="#acknowledgements-and-version-history">Acknowledgements & Version History</a> •
  <a href="#using-this-project">Using This Project</a> •
  <a href="#license">License</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#contact">Contact</a>
</p>

## Introduction

This repository houses my product design portfolio, showcasing various projects and designs I've worked on. 

About me: product-focused designer with 10+ years of experience, based in Tokyo, Japan (prev in San Francisco) 

**Why all this for a website?**
- It's a personal website, so why not? It's one of the few times you can build what you want without compromises. For example, I was able to incorporate features like a custom optically-aligned typographic "engine" that might be less practical in large-team settings or with less technical designers.
- I heard all of my eng friends saying how fast you can build features in elixir/phoenix, and I wanted to build something with a lot more infra and a better DX (e.g. admin interface, metrics, gitops)
- It'll be reusable for future app development
- This is also a homelab project

## Features

### Dev tools

Offers tools to ensure code quality and consistency:
- Automated code formatting and linting
- Comprehensive test suite with coverage reporting
- Security checks with Sobelow
- Static code analysis with Dialyzer
- Git hooks for pre-commit and pre-push checks

You can read more in <a href="#development-and-deployment">Development and Deployment</a>

### Internationalization

The portfolio supports both English (/en) and Japanese (/ja) languages. It determines the locale, by in order:
* Locale in URL
* Accept-Language header to detect the user's preferred language.

For application and landing page content, we use Gettext for translations. Case studies and other long form content have separate markdown files for each language.

You can also add a new language in `/gettext/` for UI and `/priv/content/schema/` for whichever schema you want to translate.

### Admin Interface

An admin interface with a Markdown-based system allows for creating case studies with live reloading. This feature is only accessible in the development environment and is not exposed in production.

### Optically-Aligned Typography System

A optically-aligned typographic "engine"  that optically adjusts typgographic elements. The goal is to ensure that the container aligns precisely with the visible text content—from the ascender down to the bottom of the x-height—rather than encompassing the entire line-height box. This precise alignment makes it so all objects are equally spaced optically. 

It requires specific integration for each typeface you use, so it's not practical for most teams. 

In the future, you can get this for free if [CSS Inline Layout Module Level 3](https://www.w3.org/TR/css-inline-3/) is implemented.

## Technical Details

<p align="left">
  <img src="https://img.shields.io/badge/Elixir-4B275F?style=flat&logo=elixir&logoColor=white" alt="Elixir" />
  <img src="https://img.shields.io/badge/Phoenix-FD4F00?style=flat&logo=phoenix-framework&logoColor=white" alt="Phoenix Framework" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=flat&logo=tailwind-css&logoColor=white" alt="TailwindCSS" />
</p>

### Backend

The backend is built with Elixir and Phoenix. PostgreSQL is used as the database for storing project data and user interactions. Obviously overkill for what's basically a website, but I hope to use the infra for other projects.

### Frontend

On the frontend, we use:
- esbuild: An extremely fast JavaScript bundler and minifier
- TailwindCSS: A utility-first CSS framework
- Heroicons: For SVG icons

### Database and Content Management

PostgreSQL is used for data storage. A file watcher looks for markdown files with the correct frontmatter key-value pairs to update records in the database.

## Development and Deployment

### Local Development

To set up the project locally:

1. Clone the repository
2. Ensure you have Docker installed
3. Run `docker-compose up -d` to start the application
4. Run `./run mix ecto.setup` to initially set up the db
4. Visit `localhost:8000` in your browser

### Code Quality and Git Hooks

This project uses Lefthook for managing Git hooks to ensure code quality and consistency. The configuration can be found in `.lefthook.yml`. Here's a brief overview of what's included:

- **Pre-commit hooks**: Format Elixir files and ensure containers are running.
- **Pre-push hooks**: Run format checks, linting (Credo), and tests for Elixir code.

To use these hooks, install Lefthook by following the instructions at [Lefthook's GitHub repository](https://github.com/evilmartians/lefthook).

These hooks help maintain code quality, but you bypass the checks easily if you want to do it all in CI workflows.

### Deployment

Deployment details are still being finalized. The project uses GitHub Actions for CI/CD, as indicated by the workflow status badge at the top of this README. Below is a WIP:

You'll need to make sure the env variables are set to production, namely:
```bash
export DOCKER_WEB_VOLUME=./priv/static:/app/priv/static # Use this for production
#export DOCKER_WEB_VOLUME=.:/app  # use this for dev 
```

### Troubleshooting

If you encounter issues running `mix ecto.drop` while the app is running, try stopping the web app first:
```bash
docker compose stop web
```
If that doesn't work:
```bash
docker exec -it YOURAPP-postgres-1 psql -U YOURUSER -d YOURDATABASE -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'YOURDATABASE' AND pid <> pg_backend_pid();"
```
Then drop your database:
```bash
docker exec -it YOURAPP-postgres-1 psql -U YOURAPP -d postgres -c "DROP DATABASE YOURDATABASE;"
```
and the test database as well (otherwise they'll be out of sync)
```bash
docker exec -it YOURAPP-postgres-1 psql -U YOURAPP -d postgres -c "DROP DATABASE YOURDATABASE_test;"
```

After that, run your app again with `docker compose up -d` and then do `./run mix ecto.setup`.

## Future Improvements

Planned enhancements include:
- Image optimization and minification
- OG graph image generation
- Performance optimizations
- Full implementation of telemetry

## Acknowledgements and Version History

A special thanks to [Nick Janetakis](https://nickjanetakis.com) for creating the docker-phoenix-example, which served as the foundation for this portfolio.

Previous portfolio versions:
- 2016 – 2024: Built using React, NextJS, and Styled-Components. [Code available here](https://github.com/zaneriley/personal-site/tree/Portfolio).
- 2014 – 2016: Built using Vanilla JS. [View on Wayback Machine](https://web.archive.org/web/20150711234633/http://zaneriley.com/).
- 2010: Built using Flash.

## License

This project is licensed under AGPL-3.0. See the [LICENSE](LICENSE) file for details.

### Using this for your own portfolio

If you're using this project as a base for your own portfolio website, I ask that you provide credit for the original work. Here's how you can do that:

1. Include a comment in your main layout file (e.g., `root.html.heex`) that says:
```
<!-- Based on Zane Riley's Portfolio: https://github.com/zaneriley/personal-site -->
```
2. Add a line to your README.md file:
```markdown
This project is based on [Zane Riley's Portfolio](https://github.com/zaneriley/personal-site).
```
By providing credit, you help support open-source projects and allow others to discover and learn from the original work. Thank you for your consideration!


## Contributing
Contributions are welcome, but obviously since this is my personal site I'd be amazed if anyone would want to.

## Contact

Project Link: [https://github.com/zaneriley/personal-site](https://github.com/zaneriley/personal-site)

---
