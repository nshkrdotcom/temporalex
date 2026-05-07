defmodule Temporalex.RuntimePolicyTest do
  use ExUnit.Case, async: true

  alias Temporalex.RuntimePolicy

  test "bounds workflow activity retry worker signal and query vocabularies" do
    assert RuntimePolicy.default_runtime_mode() == :disabled
    assert :ok = RuntimePolicy.validate_runtime_mode(:disabled)
    assert :ok = RuntimePolicy.validate_runtime_mode(:live_temporal)

    assert {:error, {:unknown_runtime_mode, :ambient_default}} =
             RuntimePolicy.validate_runtime_mode(:ambient_default)

    refute RuntimePolicy.temporal_enabled?()
    refute RuntimePolicy.temporal_enabled?(%{})
    refute RuntimePolicy.temporal_enabled?(runtime_mode: :disabled)
    assert RuntimePolicy.temporal_enabled?(runtime_mode: :live_temporal)

    assert :ok = RuntimePolicy.validate_workflow_status(:running)

    assert {:error, {:unknown_workflow_status, :paused}} =
             RuntimePolicy.validate_workflow_status(:paused)

    assert :ok = RuntimePolicy.validate_activity_status(:completed)

    assert {:error, {:unknown_activity_status, :deferred}} =
             RuntimePolicy.validate_activity_status(:deferred)

    assert :ok = RuntimePolicy.validate_retry_reason(:timeout)

    assert {:error, {:unknown_retry_reason, :unknown_provider_retry}} =
             RuntimePolicy.validate_retry_reason(:unknown_provider_retry)

    assert :ok = RuntimePolicy.validate_worker_event_kind(:activation)

    assert {:error, {:unknown_worker_event_kind, :unsafely_dynamic}} =
             RuntimePolicy.validate_worker_event_kind(:unsafely_dynamic)

    assert :ok = RuntimePolicy.validate_signal_name("approval_received")

    assert {:error, {:invalid_signal_name, :empty}} =
             RuntimePolicy.validate_signal_name("")

    assert {:error, {:invalid_signal_name, :not_binary}} =
             RuntimePolicy.validate_signal_name(:approval_received)

    assert :ok = RuntimePolicy.validate_query_name("current_status")

    assert {:error, {:invalid_query_name, :blank}} =
             RuntimePolicy.validate_query_name("  ")

    assert {:error, {:invalid_query_name, :not_binary}} =
             RuntimePolicy.validate_query_name(:current_status)
  end
end
