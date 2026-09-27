# Changelog

All notable changes to the Taro Worker (`taro-api`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Worker skeleton: Hono + `@hono/zod-openapi` app with `buildApp(deps)` and `makeProdDeps(env)`.
- `GET /v1/health` returning `{ status, workerVersion, environment }`.
- `wrangler.toml` with `dev`, `staging` and `prod` environments and placeholder bindings.
- Vitest in workerd (`@cloudflare/vitest-pool-workers`) with istanbul coverage gates, ESLint and Prettier.
