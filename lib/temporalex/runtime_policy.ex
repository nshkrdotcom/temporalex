defmodule Temporalex.RuntimePolicy do
  @moduledoc """
  Bounded runtime vocabulary for Temporalex-owned lifecycle metadata.
  """

  @workflow_statuses [:idle, :yielded, :running, :done]
  @activity_statuses [:completed, :failed, :cancelled]
  @runtime_modes [:disabled, :live_temporal]
  @retry_reasons [
    :timeout,
    :cancellation,
    :nondeterminism,
    :worker_shutdown,
    :activity_failure,
    :workflow_failure
  ]
  @worker_event_kinds [:activation]

  @spec default_runtime_mode() :: :disabled
  def default_runtime_mode, do: :disabled

  @spec validate_runtime_mode(term()) :: :ok | {:error, {:unknown_runtime_mode, term()}}
  def validate_runtime_mode(mode) when mode in @runtime_modes, do: :ok
  def validate_runtime_mode(mode), do: {:error, {:unknown_runtime_mode, mode}}

  @spec temporal_enabled?(keyword() | map() | nil) :: boolean()
  def temporal_enabled?(attrs \\ nil)

  def temporal_enabled?(nil), do: false

  def temporal_enabled?(attrs) when is_list(attrs) do
    attrs |> Map.new() |> temporal_enabled?()
  end

  def temporal_enabled?(attrs) when is_map(attrs) do
    Map.get(attrs, :runtime_mode, Map.get(attrs, "runtime_mode", default_runtime_mode())) ==
      :live_temporal
  end

  def temporal_enabled?(_attrs), do: false

  @spec validate_workflow_status(term()) :: :ok | {:error, {:unknown_workflow_status, term()}}
  def validate_workflow_status(status) when status in @workflow_statuses, do: :ok
  def validate_workflow_status(status), do: {:error, {:unknown_workflow_status, status}}

  @spec validate_activity_status(term()) :: :ok | {:error, {:unknown_activity_status, term()}}
  def validate_activity_status(status) when status in @activity_statuses, do: :ok
  def validate_activity_status(status), do: {:error, {:unknown_activity_status, status}}

  @spec validate_retry_reason(term()) :: :ok | {:error, {:unknown_retry_reason, term()}}
  def validate_retry_reason(reason) when reason in @retry_reasons, do: :ok
  def validate_retry_reason(reason), do: {:error, {:unknown_retry_reason, reason}}

  @spec validate_worker_event_kind(term()) :: :ok | {:error, {:unknown_worker_event_kind, term()}}
  def validate_worker_event_kind(kind) when kind in @worker_event_kinds, do: :ok
  def validate_worker_event_kind(kind), do: {:error, {:unknown_worker_event_kind, kind}}

  @spec validate_signal_name(term()) :: :ok | {:error, {:invalid_signal_name, atom()}}
  def validate_signal_name(name), do: validate_external_name(name, :invalid_signal_name)

  @spec validate_query_name(term()) :: :ok | {:error, {:invalid_query_name, atom()}}
  def validate_query_name(name), do: validate_external_name(name, :invalid_query_name)

  @spec workflow_status!(term()) :: atom()
  def workflow_status!(status), do: unwrap!(status, validate_workflow_status(status))

  @spec activity_status!(term()) :: atom()
  def activity_status!(status), do: unwrap!(status, validate_activity_status(status))

  @spec retry_reason!(term()) :: atom()
  def retry_reason!(reason), do: unwrap!(reason, validate_retry_reason(reason))

  @spec worker_event_kind!(term()) :: atom()
  def worker_event_kind!(kind), do: unwrap!(kind, validate_worker_event_kind(kind))

  defp validate_external_name(name, error_kind) when is_binary(name) do
    cond do
      name == "" -> {:error, {error_kind, :empty}}
      String.trim(name) == "" -> {:error, {error_kind, :blank}}
      String.trim(name) != name -> {:error, {error_kind, :surrounding_whitespace}}
      String.contains?(name, <<0>>) -> {:error, {error_kind, :null_byte}}
      true -> :ok
    end
  end

  defp validate_external_name(_name, error_kind), do: {:error, {error_kind, :not_binary}}

  defp unwrap!(value, :ok), do: value

  defp unwrap!(_value, {:error, reason}) do
    raise ArgumentError, inspect(reason)
  end
end
