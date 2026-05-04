defmodule Temporalex.AuthorityGuard do
  @moduledoc false

  @required_refs [
    :authority_ref,
    :endpoint_ref,
    :namespace_ref,
    :task_queue_ref,
    :worker_identity_ref,
    :workflow_auth_metadata_ref
  ]

  @connection_fields [:address, :namespace, :api_key, :headers]
  @server_fields @connection_fields ++ [:task_queue, :worker_identity, :workflow_auth_metadata]

  @spec governed?(keyword()) :: boolean()
  def governed?(opts) when is_list(opts), do: Keyword.has_key?(opts, :governed_authority)
  def governed?(_opts), do: false

  @spec validate_supervisor_opts(keyword()) ::
          :ok
          | {:error,
             {:unmanaged_env_authority, atom()} | {:missing_governed_authority_refs, [atom()]}}
  def validate_supervisor_opts(opts), do: validate_governed_opts(opts, @server_fields)

  @spec validate_connection_opts(keyword()) ::
          :ok
          | {:error,
             {:unmanaged_env_authority, atom()} | {:missing_governed_authority_refs, [atom()]}}
  def validate_connection_opts(opts), do: validate_governed_opts(opts, @connection_fields)

  @spec validate_server_opts(keyword()) ::
          :ok
          | {:error,
             {:unmanaged_env_authority, atom()} | {:missing_governed_authority_refs, [atom()]}}
  def validate_server_opts(opts), do: validate_governed_opts(opts, @server_fields)

  @spec validate_supervisor_opts!(keyword()) :: :ok
  def validate_supervisor_opts!(opts), do: raise_on_error(validate_supervisor_opts(opts))

  @spec validate_connection_opts!(keyword()) :: :ok
  def validate_connection_opts!(opts), do: raise_on_error(validate_connection_opts(opts))

  @spec validate_server_opts!(keyword()) :: :ok
  def validate_server_opts!(opts), do: raise_on_error(validate_server_opts(opts))

  defp validate_governed_opts(opts, fields) when is_list(opts) do
    if governed?(opts) do
      with :ok <- validate_required_refs(Keyword.get(opts, :governed_authority)) do
        validate_no_raw_fields(opts, fields)
      end
    else
      :ok
    end
  end

  defp validate_governed_opts(_opts, _fields), do: :ok

  defp validate_required_refs(authority) do
    missing =
      Enum.reject(@required_refs, fn ref ->
        authority_ref_present?(authority, ref)
      end)

    case missing do
      [] -> :ok
      refs -> {:error, {:missing_governed_authority_refs, refs}}
    end
  end

  defp validate_no_raw_fields(opts, fields) do
    case Enum.find(fields, &raw_field_present?(opts, &1)) do
      nil -> :ok
      field -> {:error, {:unmanaged_env_authority, field}}
    end
  end

  defp authority_ref_present?(authority, ref) when is_list(authority) do
    authority
    |> Keyword.get(ref)
    |> present_value?()
  end

  defp authority_ref_present?(authority, ref) when is_map(authority) do
    present_value?(Map.get(authority, ref)) or
      present_value?(Map.get(authority, Atom.to_string(ref)))
  end

  defp authority_ref_present?(_authority, _ref), do: false

  defp raw_field_present?(opts, field) do
    opts
    |> Keyword.get(field)
    |> present_value?()
  end

  defp present_value?(value) when value in [nil, "", []], do: false
  defp present_value?(_value), do: true

  defp raise_on_error(:ok), do: :ok

  defp raise_on_error({:error, reason}) do
    raise ArgumentError, "invalid governed Temporalex authority options: #{inspect(reason)}"
  end
end
