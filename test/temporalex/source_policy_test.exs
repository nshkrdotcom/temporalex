defmodule Temporalex.SourcePolicyTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)

  test "repo-owned source avoids pattern engines" do
    assert_no_tokens!(source_files(), pattern_engine_tokens())
  end

  test "repo-owned source avoids dynamic atom construction" do
    assert_no_tokens!(source_files(), atom_construction_tokens())
  end

  defp assert_no_tokens!(files, tokens) do
    hits =
      for file <- files,
          source = File.read!(file),
          token <- tokens,
          String.contains?(source, token),
          do: relative_path(file) <> " contains " <> inspect(token)

    assert hits == []
  end

  defp source_files do
    [
      Path.join(@repo_root, "mix.exs"),
      Path.join(@repo_root, "native/temporalex_native/Cargo.toml")
    ] ++
      Path.wildcard(Path.join(@repo_root, "lib/**/*.ex")) ++
      Path.wildcard(Path.join(@repo_root, "test/**/*.exs")) ++
      Path.wildcard(Path.join(@repo_root, "native/temporalex_native/src/*.rs"))
  end

  defp pattern_engine_tokens do
    [
      ["Re", "gex"],
      [<<126>>, "r"],
      [<<58>>, "r", "e", "."],
      ["String.", "mat", "ch"],
      ["Reg", "Exp"],
      ["reg", "exp"],
      ["re", ".compile"],
      ["re", ".search"],
      ["re", ".match"],
      ["re", ".fullmatch"],
      ["re", ".sub"],
      ["re", ".split"],
      ["re", ".findall"],
      ["re", ".finditer"],
      ["from ", "re ", "import"],
      ["import ", "re"]
    ]
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp atom_construction_tokens do
    [
      ["String.to_", "atom"],
      ["String.to_existing_", "atom"],
      ["binary_to_", "atom"],
      ["binary_to_existing_", "atom"],
      ["list_to_", "atom"],
      ["list_to_existing_", "atom"],
      [<<58>>, "#", "{"],
      [<<58>>, <<34>>, "#", "{"]
    ]
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp relative_path(path), do: Path.relative_to(path, @repo_root)
end
