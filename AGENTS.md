# Agent Instructions

## Dependency Sources

Temporalex is not in the Weld consumer set. Do not add a Weld dependency,
Weld task, or Weld Credo check as part of Phase 2 cleanup.

Cross-repo dependency selection belongs in
`build_support/dependency_sources.config.exs` and is consumed through the
canonical `build_support/dependency_sources.exs` helper. This repo currently
has no cross-repo dependencies, so the manifest is intentionally empty.

Machine-local dependency overrides belong in `.dependency_sources.local.exs`.
Keep that file untracked.

Dependency source selection must not read environment variables.

## Runtime Environment

Runtime application code under `lib/**` must not call direct OS environment
APIs such as `System.get_env/1`, `System.fetch_env/1`, `System.fetch_env!/1`,
`System.put_env/2`, `System.delete_env/1`, or `System.get_env/0`.

Deployment environment reads belong at OTP boot boundaries such as
`config/runtime.exs` or a `Config.Provider`. Runtime modules should receive
explicit options or materialized application config.
