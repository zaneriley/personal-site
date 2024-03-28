# Zane Riley's Product Design Portfolio
![Website](https://img.shields.io/website?url=https%3A%2F%2Fzaneriley.com&up_message=online&down_message=offline&label=portfolio)
![GitHub License](https://img.shields.io/github/license/zaneriley/personal-site)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/zaneriley/personal-site/ci.yml)

This repository houses my product design portfolio, showcasing various projects and designs I've worked on. The portfolio is built using Phoenix (PETAL stack basically). The foundation of this portfolio is based on the excellent example provided by Nick Janetakis' [docker-phoenix-example](https://github.com/nickjj/docker-phoenix-example), which offers a great starting point for Phoenix applications with Docker.

## About me

Extremely product-focused designer with 10+ years of experience based in Tokyo, Japan. 

Focused on building things that help people beyond the screen. My ultimate goal is to make things that help people shape the future they desire, not a future that is imposed upon them. 


# Prtfolio overview

For portfolios, I prioritize building exactly what I envision, even if it involves learning new technologies or techniques. This is my first major project built with Elixir or Phoenix. I also incorporated features (like a custom optically-aligned typographic "engine") that might be less practical in large-team settings or with less technical designers.

Features include:

- Internationalization support for English (/en) and Japanese (/ja)
- Admin interface and Markdown-based system for creating case studies with live reloading.
- Light/dark mode with real-time updates across sessions and preferences stored in local storage.


## Tech Stack

This project utilizies [Phoenix](https://phoenixframework.org/), a framework written in [Elixir](https://elixir-lang.org/). While an unconventional choice for a largely static site, Phoenix's great developer experience helped me build a number of features really quickly.
 content, Phoenix's outstanding developer experience enabled the rapid development of several key features.
### Back-end

- [Elixir and Phoenix](https://www.phoenixframework.org/): For server-side logic and web page rendering.
- [PostgreSQL](https://www.postgresql.org/): As the database for storing project data and user interactions.

### Front-end

- [esbuild](https://esbuild.github.io/): For an extremely fast JavaScript bundler and minifier.
- [TailwindCSS](https://tailwindcss.com/): For utility-first CSS framework.
- [Heroicons](https://heroicons.com/): For SVG icons.

## Feature details

### Internationalization

#### Detecting the user's preferred language
- Uses the [Accept-Language header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language) to determine whether the users language is supported (english or japanese in our case)
- Sets a session key to maintain that language setting, allowing user to override and choose another language.
- Sets hreflang tags, and sets a language response header

#### Translating content
- For application and landing page content, we use [Gettext](https://hexdocs.pm/gettext/Gettext.html) to translate content into multiple languages. 
- For case studies, we have separate markdown files for each language.

### Light/Dark Mode

Of course we need dark mode, but this is overengineered to real-time update across all a users sessions (e.g. in our case, their open tabs). If you put a user auth system in place, you could make this a setting and update aross all their devices. Additionally, we update instantly client-side first, and then debounce updates to the server.

Here's a quick breakdown:

1. **Theme storage:** Each user's theme choice (light or dark) is saved both in the browser's localStorage (for quick access) and on the server using a combination of Elixir's GenServer and your choice of database.

2. **Real-time Updates:** We use Phoenix Channels to make sure that if a user changes their theme on one tab, it updates automatically on any other open tabs. (This is just a portfolio, so theres no need for a user auth system where you could track user sessions across devices.)

3. **Server-side Logic:** The core logic for managing theme preferences lives in an Elixir module called `LightDarkMode.GenServer`. This module is responsible for storing a user's theme preference, handling requests to toggle the theme, and sending out updates.

4. **Front-end:** The JavaScript part of the code handles: Connecting to a user's specific Phoenix channel, listening for theme changes from the server, applying the correct CSS classes to the page to switch between light and dark modes, and sending theme change requests to the server when the user toggles the theme switch.

## Acknowledgements

A special thanks to [Nick Janetakis](https://nickjanetakis.com) for creating the docker-phoenix-example, which served as the foundation for this portfolio. 

## Previous portfolios
- 2024 – Present: Built using Elixir, Phoenix, and Tailwind.
- 2016 – 2024: Built using React, NextJS, and Styled-Components. [Code available here](https://github.com/zaneriley/personal-site/tree/Portfolio).
- 2014 – 2016: Built using Vanilla JS. [View on Wayback Machine](https://web.archive.org/web/20150711234633/http://zaneriley.com/).
- 2010: Built using Flash.
