defmodule Temporalex.AuthorityGuardTest do
  use ExUnit.Case, async: true

  alias Temporalex.AuthorityGuard

  @authority_refs [
    authority_ref: "authority://temporalex/test",
    endpoint_ref: "endpoint://temporalex/test",
    namespace_ref: "namespace://temporalex/default",
    task_queue_ref: "task-queue://temporalex/default",
    worker_identity_ref: "worker://temporalex/test",
    workflow_auth_metadata_ref: "workflow-auth://temporalex/test"
  ]

  test "standalone explicit connection and worker options remain valid" do
    assert :ok =
             AuthorityGuard.validate_supervisor_opts(
               name: MyApp.Temporal,
               address: "http://localhost:7233",
               namespace: "default",
               api_key: "standalone-api-key",
               headers: [{"authorization", "Bearer standalone"}],
               task_queue: "default"
             )
  end

  test "governed connection rejects raw endpoint namespace and auth options" do
    for {field, opts} <- governed_connection_cases() do
      assert {:error, {:unmanaged_env_authority, ^field}} =
               AuthorityGuard.validate_connection_opts(
                 Keyword.merge([governed_authority: @authority_refs, name: :conn], opts)
               )
    end
  end

  test "governed worker rejects raw task queue identity and workflow auth metadata" do
    for {field, opts} <- governed_worker_cases() do
      assert {:error, {:unmanaged_env_authority, ^field}} =
               AuthorityGuard.validate_server_opts(
                 Keyword.merge([governed_authority: @authority_refs], opts)
               )
    end
  end

  test "governed authority requires all reference fields" do
    assert {:error, {:missing_governed_authority_refs, missing}} =
             AuthorityGuard.validate_connection_opts(
               governed_authority: [authority_ref: "authority://temporalex/test"]
             )

    assert :endpoint_ref in missing
    assert :namespace_ref in missing
    assert :task_queue_ref in missing
    assert :worker_identity_ref in missing
    assert :workflow_auth_metadata_ref in missing
  end

  defp governed_connection_cases do
    [
      address: [address: "https://env-temporal.invalid:7233"],
      namespace: [namespace: "env-namespace"],
      api_key: [api_key: "env-api-key"],
      headers: [headers: [{"authorization", "Bearer env-api-key"}]]
    ]
  end

  defp governed_worker_cases do
    [
      task_queue: [task_queue: "env-task-queue"],
      worker_identity: [worker_identity: "env-worker"],
      workflow_auth_metadata: [workflow_auth_metadata: %{tenant: "env-tenant"}]
    ]
  end
end
