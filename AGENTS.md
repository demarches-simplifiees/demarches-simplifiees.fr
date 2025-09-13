# Repository Guidelines

## Project Structure & Module Organization
- `app/`: Rails MVC, views (HAML), components, and `app/javascript` (Vite/React/TS).
- `spec/`: RSpec tests (models, controllers, system, GraphQL, etc.).
- `lib/`: internal libraries and cops; `config/`: environments, routes, initializers.
- `db/`: migrations and seeds; `public/`: static assets; `bin/`: helper scripts.
- Docs in `doc/` and API docs tooling in `api_doc/`.

## Build, Test, and Development Commands
- Setup: `bin/setup` (deps, DB, assets). Update: `bin/update`.
- Run locally: `bin/dev` (Overmind runs web, jobs, and `bin/vite`). Alt: `overmind start -f Procfile.dev`.
- Ruby tests: `bin/rspec` or `bin/rake spec`. Example: `bin/rspec spec/models/user_spec.rb:12`.
- JS tests: `bun run test` (Vitest). Coverage: `bun run coverage`.
- Lint all: `bin/rake lint`. Specific: `bundle exec rubocop`, `bun run lint:js`, `bun run lint:types`, `bun run lint:css`.

## Coding Style & Naming Conventions
- Ruby: 2-space indent, Rails/RSpec cops via RuboCop (`.rubocop.yml`). Files `snake_case.rb`; classes `CamelCase`.
- Views: HAML checked by `haml-lint`.
- Frontend: TypeScript + React via Vite. Use PascalCase for components, camelCase for variables; keep code in `app/javascript`.
- Formatting: Prettier for styles and TS; ESLint rules in `eslint.config.ts`.

## Testing Guidelines
- Frameworks: RSpec (+ Capybara/Playwright) and Vitest.
- Ruby specs end with `_spec.rb` under `spec/…`. System specs may require Chrome; run visibly: `NO_HEADLESS=1 bin/rspec spec/system`.
- JS unit tests live alongside code as `*.test.ts(x)`.
- Coverage: SimpleCov (Ruby) and Vitest coverage; keep meaningful assertions.

## Commit & Pull Request Guidelines
- Commits: imperative mood, focused scope; reference issues (e.g., `Fix: redeliver webhooks (#123)`).
- PRs: clear description, linked issues, screenshots for UI changes, migration notes, and added/updated tests. Ensure CI is green.

## Security & Configuration Tips
- Do not commit secrets. Use `.env`/`.env.test` (dotenv) locally.
- Prereqs: PostgreSQL ≥ 15, Redis (Sidekiq), ImageMagick with restricted policy. Sidekiq dev: `overmind start -f Procfile.sidekiq.dev`.
