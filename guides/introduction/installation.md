# Installation

## Dependencies

Add Temporalex to your `mix.exs`:

```elixir
def deps do
  [{:temporalex, "~> 0.1.0"}]
end
```

Temporalex compiles a Rust NIF under the hood. You need the Rust toolchain installed:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Verify it's working:

```bash
rustc --version
# rustc 1.75.0 or later
```

Then fetch dependencies:

```bash
mix deps.get
mix compile
```

The first compile takes a few minutes — it's building the Temporal Rust Core SDK. Subsequent compiles are fast.

## Running Temporal Locally

You need a Temporal server to develop against. Start it through the repo-owned
application substrate that consumes Temporalex instead of launching a raw
Temporal CLI dev server directly. In this workspace, Mezzanine owns that local
substrate:

```bash
cd /home/home/p/g/n/mezzanine
just dev-up
just dev-status
```

This provides Temporal at `http://localhost:7233` with a web UI at
`http://localhost:8233`. Stop it from the same Mezzanine checkout with
`just dev-down` when your local development session is finished.

## Your First Connection

Add Temporalex to your application's supervision tree:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    {Temporalex,
      name: MyApp.Temporal,
      task_queue: "default",
      workflows: [],
      activities: []}
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Start your app. If you see `Server ready` in the logs, you're connected.

```
[info] Connection starting name=MyApp.Temporal.Connection address=http://localhost:7233
[info] Connection established name=MyApp.Temporal.Connection
[info] Server ready task_queue=default
```

## Temporal Cloud

For Temporal Cloud instead of local dev:

```elixir
{Temporalex,
  name: MyApp.Temporal,
  address: "https://my-namespace.tmprl.cloud:7233",
  namespace: "my-namespace",
  api_key: temporal_cloud_api_key,
  task_queue: "default",
  workflows: [],
  activities: []}
```

## What's Next

You're connected. Now let's [write your first workflow](../learning/workflows.md).
