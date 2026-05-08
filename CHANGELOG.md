# Changelog

Automatically updated using Release Please. Follows [semantic versioning](https://semver.org/spec/v2.0.0.html), using [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).


## [0.4.10](https://github.com/zaneriley/personal-site/compare/v0.4.9...v0.4.10) (2026-05-08)


### Features

* **content:** add content validation command ([#70](https://github.com/zaneriley/personal-site/issues/70)) ([fed890b](https://github.com/zaneriley/personal-site/commit/fed890be418e0c1553cabc7a92a648816092f1e9))

## [0.4.9](https://github.com/zaneriley/personal-site/compare/v0.4.8...v0.4.9) (2026-05-08)


### Features

* **content:** formalize share preview fields ([1202518](https://github.com/zaneriley/personal-site/commit/1202518a49d775562fa963fe8aa35ab7ee10beba))

## [0.4.8](https://github.com/zaneriley/personal-site/compare/v0.4.7...v0.4.8) (2026-05-08)


### Features

* **content:** persist og frontmatter hints ([f010359](https://github.com/zaneriley/personal-site/commit/f010359ca8ed14e0b308f848d0e48beb1c353d79))
* **content:** persist og frontmatter hints ([951db5c](https://github.com/zaneriley/personal-site/commit/951db5c61f2b166c68b56caf258088ebf1000d0a))

## [0.4.7](https://github.com/zaneriley/personal-site/compare/v0.4.6...v0.4.7) (2026-05-08)


### Features

* **content:** promote webhook changes deterministically ([a2ed2d4](https://github.com/zaneriley/personal-site/commit/a2ed2d42ca9e91a8cf52da2597cf8a9319d08824))

## [0.4.6](https://github.com/zaneriley/personal-site/compare/v0.4.5...v0.4.6) (2026-05-07)


### Documentation

* **ops:** avoid stale release status ([18f3fc4](https://github.com/zaneriley/personal-site/commit/18f3fc413ef1c18b0d811b57ea9e4c9d3ba357a5))

## [0.4.5](https://github.com/zaneriley/personal-site/compare/v0.4.4...v0.4.5) (2026-05-07)


### CI

* upgrade actions to node 24 majors ([45c7767](https://github.com/zaneriley/personal-site/commit/45c77672d27449064d18cf8a2c0b7e0a1ebc2de6))

## [0.4.4](https://github.com/zaneriley/personal-site/compare/v0.4.3...v0.4.4) (2026-05-07)


### Documentation

* **ops:** update deploy status plan ([6dd705e](https://github.com/zaneriley/personal-site/commit/6dd705e167a3389abbab3c5dc702238a5972531e))

## [0.4.3](https://github.com/zaneriley/personal-site/compare/v0.4.2...v0.4.3) (2026-05-07)


### Features

* **ci:** add prod deployability gate ([1d6e5c7](https://github.com/zaneriley/personal-site/commit/1d6e5c7cdf78c31816208d83fc72d7733f90eccf))

## [0.4.2](https://github.com/zaneriley/personal-site/compare/v0.4.1-alpha.1...v0.4.2) (2026-05-07)


### Features

* **design:** WIP frontend overhaul to match current design explorations ([091459f](https://github.com/zaneriley/personal-site/commit/091459f70667b5eaf62c51f60fa0a8e35537d0d1))
* **docs:** Add documentation route to router ([adec14d](https://github.com/zaneriley/personal-site/commit/adec14dd640239ef11076c1eafc28307cf920086))
* **docs:** Add ExDoc serving plug to endpoint ([bc05767](https://github.com/zaneriley/personal-site/commit/bc0576702bbca68da75f1ecc32a4ce58ad3d731e))
* **i18n:** Add text justification for Japanese language ([ba8ca72](https://github.com/zaneriley/personal-site/commit/ba8ca7281f6c93a1913eb882265b282ef9419344))
* **theme:** add theme switcher functionality - Implement ThemeSwitcherHook - Add theme switching logic and user preference management - Update CSS for dark and light mode support ([e908510](https://github.com/zaneriley/personal-site/commit/e908510445a3650ab47c8132a90b36f38337fb33))
* **ui:** Add configuration and locale handling to typography helpers ([f790ff5](https://github.com/zaneriley/personal-site/commit/f790ff5f48aafd3b302a865a3530a60f394d3e49))
* **ui:** Implement dark mode color variables and adjust themes ([77d61da](https://github.com/zaneriley/personal-site/commit/77d61da85f9d1b9ed59d3cc21139e2118b8d12d9))


### Bug Fixes

* **assets:** build tailwind directly inside css container ([3009e3e](https://github.com/zaneriley/personal-site/commit/3009e3e3ebf08271ccf35529f191f8b32527996a))
* **components:** declare user_locale attr on PortfolioItemList ([f086a35](https://github.com/zaneriley/personal-site/commit/f086a3530757cec43c06756bbdd26088d5cda0e2))
* **layout:** restore grid layout processing log message ([cc826ee](https://github.com/zaneriley/personal-site/commit/cc826eece9bdfa2573e059964826edda04f44f84))
* **typography:** correct heading tag in typography transform ([3ac7c1e](https://github.com/zaneriley/personal-site/commit/3ac7c1ef61e8d29b6d7070e8a9e787ae31957934))


### Documentation

* **backend:** Update core Portfolio module documentation ([3256196](https://github.com/zaneriley/personal-site/commit/325619665dfb1694c576b9aa3f8f1d745be7cbc9))
* bootstrap repo AGENTS.md from /grill-me on deploy/ops scope ([f334e36](https://github.com/zaneriley/personal-site/commit/f334e361f7f030e24adef7c5b8d8ac1603967bbf))
* dependabot triage clean — 213 alerts auto-resolved by JS deps upgrade ([5ed9965](https://github.com/zaneriley/personal-site/commit/5ed99659fc7b466313375901cf9283a31b64e6fe))
* **markdown:** Update comments in parser ([b543fcf](https://github.com/zaneriley/personal-site/commit/b543fcfd58e150347a8254d19ca63dccfcbd79bb))


### CI

* add gitleaks secret-scan gate ([a40fd9a](https://github.com/zaneriley/personal-site/commit/a40fd9a369340fb2b23bb6d3bf601cc9dbf5477e))
* add strict acceptance gates ([acd481e](https://github.com/zaneriley/personal-site/commit/acd481edee2a16a2b715b01c86583cc483690f20))
* add workflow gate integrity checks ([fb72f78](https://github.com/zaneriley/personal-site/commit/fb72f78ea0d98465cdd3125b373666af67aa9103))
* close gate integrity review gaps ([ae50abf](https://github.com/zaneriley/personal-site/commit/ae50abf89bc2bc7426587d770da7bb67fb82f800))
* expose acceptance gates as staged checks ([0927a49](https://github.com/zaneriley/personal-site/commit/0927a497012a64e95f995bfdf4db1a7e450c1701))
* harden release-please automation ([5768aeb](https://github.com/zaneriley/personal-site/commit/5768aebdd3cef7e196d1fbfda6e9184789eeff2e))
* make quality gates strict ([4298ab7](https://github.com/zaneriley/personal-site/commit/4298ab74ea778ccbbccbf92375c87526b82099b6))


### Miscellaneous

* **deps:** remove unused :dns_cluster + purge :debug logs in prod ([d12da17](https://github.com/zaneriley/personal-site/commit/d12da17db89cf2d775f53c590399898ad63765b9))
* **deps:** Update dependencies for documentation ([26b7bad](https://github.com/zaneriley/personal-site/commit/26b7bad7af35bc7692c1992d0ab56a463c346262))
* **deps:** update JS dependencies ([fe1b61c](https://github.com/zaneriley/personal-site/commit/fe1b61c5cd331b548d1dd4824f02499fe7db0e8e))
* **dialyzer:** Ignore specific errors and patterns ([d0c2609](https://github.com/zaneriley/personal-site/commit/d0c2609c85d331d6e6d90dcfb7f3f0ecada3646a))
* **git:** Update .gitignore exclusions ([e818fbb](https://github.com/zaneriley/personal-site/commit/e818fbbae1487fdd70a95ab0fca9734b5cd0890f))
* ignore .tmp/ ([a8d91f6](https://github.com/zaneriley/personal-site/commit/a8d91f6ec3ad5383e5df7511677b21adf98ebf9c))
* **lint:** Ignore specific Credo check in kitchen_sink_live ([7b8de16](https://github.com/zaneriley/personal-site/commit/7b8de1629682e631e4f71936612a41b30847585f))
* remove .cursor rules ([67a75be](https://github.com/zaneriley/personal-site/commit/67a75be6c99c8fb349e5a04346487bedb1a72f03))
* Remove temporary analysis and archive files ([0553457](https://github.com/zaneriley/personal-site/commit/0553457c2c8107bbf971d8a461f699bdda171d09))
* **scripts:** Update run script helper functions ([e9ca95f](https://github.com/zaneriley/personal-site/commit/e9ca95f7fbc0003c1fe78eaa0a5fbb2e9dc95db5))
* symlink elixir-phoenix-style skill into .agents/skills/ ([2528b5c](https://github.com/zaneriley/personal-site/commit/2528b5cf6f235e55e8589595018093c08f67e4bc))
* Update generated timestamp in typography CSS ([8e45932](https://github.com/zaneriley/personal-site/commit/8e459324e886999ec1ebdd84cebaec092e797f53))

## [0.4.1-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.4.0-alpha.1...v0.4.1-alpha.1) (2024-09-14)


### Features

* **release:** Create release setup to migrate DB and pull repo ([#45](https://github.com/zaneriley/personal-site/issues/45)) ([d4b26ae](https://github.com/zaneriley/personal-site/commit/d4b26ae591ba1b0f401e0f52e61551e749d4c262))

## [0.4.0-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.3.3-alpha.1...v0.4.0-alpha.1) (2024-09-09)


### Features

* **webhook:** implement GitHub webhook for content updates ([2c23562](https://github.com/zaneriley/personal-site/commit/2c2356209d0cae5fa7089d84666975d711d7a073))

## [0.3.3-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.3.2-alpha.1...v0.3.3-alpha.1) (2024-08-18)


### Documentation

* **readme:** update features and development tools information ([a385f3d](https://github.com/zaneriley/personal-site/commit/a385f3d8ea9fbe6dfa0d99711b624b1630741246))

## [0.3.2-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.3.1-alpha.1...v0.3.2-alpha.1) (2024-08-17)


### Bug Fixes

* **docker:** ensure static assets directory exists in entrypoint script ([086c3c1](https://github.com/zaneriley/personal-site/commit/086c3c17dc06180b8dcb6bea42de808ab2bf6a94))

## [0.3.1-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.3.0-alpha.1...v0.3.1-alpha.1) (2024-08-16)


### Bug Fixes

* remove duplicate Plug.Exception implementation for Ecto.NoResultsError ([31d5a91](https://github.com/zaneriley/personal-site/commit/31d5a9172c32010fc2ba8bbf23f3dfcec7fa6cd9))

## [0.3.0-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.2.0-alpha.1...v0.3.0-alpha.1) (2024-08-16)


### Features

* **content:** implement markdown rendering with custom components and caching ([#37](https://github.com/zaneriley/personal-site/issues/37)) ([0ed94ff](https://github.com/zaneriley/personal-site/commit/0ed94ff3c94a5e02b91b7674148d1151f28d30d2))

## [0.2.0-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.1.1-alpha.1...v0.2.0-alpha.1) (2024-07-30)


### Features

* **content:** offer note i18n translations, restructure content management system ([#35](https://github.com/zaneriley/personal-site/issues/35)) ([a36042b](https://github.com/zaneriley/personal-site/commit/a36042b2477a24d6b5619003acf87478e3fb83d7))

## [0.1.1-alpha.1](https://github.com/zaneriley/personal-site/compare/v0.1.0-alpha.1...v0.1.1-alpha.1) (2024-07-11)


### Miscellaneous

* **release:** bump version to 0.1.0-alpha.2 ([#31](https://github.com/zaneriley/personal-site/issues/31)) ([dbd011d](https://github.com/zaneriley/personal-site/commit/dbd011d80bdb9f731dc2dc11af954dffea08d243))

## 0.1.0-alpha.1 (2024-07-04)

* This commit replaces the entire React-based portfolio  with the new Elixir and Phoenix based portfolio

### Features

* **ci:** integrate Coveralls for test coverage reporting ([#20](https://github.com/zaneriley/personal-site/issues/20)) ([8f27d2d](https://github.com/zaneriley/personal-site/commit/8f27d2d9b349d6db96e328e2ab45eef70b58d921))
* **ci:** integrate sobelow security checks ([#23](https://github.com/zaneriley/personal-site/issues/23)) ([20dc6cf](https://github.com/zaneriley/personal-site/commit/20dc6cfd1676de374ef89392a93303e8de0c5881))
* **lang-switcher:** resolve conflicts favoring local implementation ([65a1fd6](https://github.com/zaneriley/personal-site/commit/65a1fd612134b2246579417979694e0da34b1a1a))
* merge new Elixir-based portfolio, replacing React version ([3e9ac76](https://github.com/zaneriley/personal-site/commit/3e9ac76c478d5eb4ecfa21a825ba1a0cd803bebc))
* **nav:** implement nav as liveview, with lang switcher, url-based routing.  ([#24](https://github.com/zaneriley/personal-site/issues/24)) ([7d47b8a](https://github.com/zaneriley/personal-site/commit/7d47b8aa69f06009de8e31e73cee615dd1cf6b7c))
* **security:** implement content security policy ([cc789a9](https://github.com/zaneriley/personal-site/commit/cc789a98f4a3e0ee194feb70a42f5792c3a00bf8))
* **versioning:** initialize project version ([be7f00b](https://github.com/zaneriley/personal-site/commit/be7f00b712772de73551c041ed2d75534b9b17bb))


### Bug Fixes

* **csp:** use lowercase header names for content security policy ([8925030](https://github.com/zaneriley/personal-site/commit/8925030aad6a8dbc5111ac32a3d095bdd56fcbf0))
* **lefthook:** change elixir format check to format action ([4d9d939](https://github.com/zaneriley/personal-site/commit/4d9d93963fbc3442803163fde3c5d1d6403ac938))


### Documentation

* add moduledocs and improve code documentation ([b406206](https://github.com/zaneriley/personal-site/commit/b4062060f8dc5ab733ef0d3a06fc3c3dc2878d3e))
* **readme:** add work in progress badge and refine project description ([94208aa](https://github.com/zaneriley/personal-site/commit/94208aa53f04bac7123fcb21c38e9d599799158c))
* update license and usage terms in README ([b20c76b](https://github.com/zaneriley/personal-site/commit/b20c76b49e2dcfe98677f041b3e668c94abae0a0))


### Miscellaneous

* **ci:** Modify config for release please ([2a43a13](https://github.com/zaneriley/personal-site/commit/2a43a13219ee65236b449b274b279775d43fe959))
* **readme:** clarify project ([#28](https://github.com/zaneriley/personal-site/issues/28)) ([07c41ad](https://github.com/zaneriley/personal-site/commit/07c41ad8c8065c21db5485cb0a1de55e4ee9b9bf))
* **readme:** fix coverage badge to reflect main branch ([425b8e1](https://github.com/zaneriley/personal-site/commit/425b8e1bc489bd0660dfc2bf1635ecbe78216270))
* **release:** configure pre-1.0 versioning ([e2958f5](https://github.com/zaneriley/personal-site/commit/e2958f524f29d586cb00a8ae69f786b3d7eaa817))
* **release:** configure release-please ([1ce5ffb](https://github.com/zaneriley/personal-site/commit/1ce5ffb3db1f3dded79c939382e99467f7a18264))

## [0.1.0] - 2024-06-27

- Initial release
