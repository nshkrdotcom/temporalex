defmodule Temporalex.SourcePolicyTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)

  test "repo-owned source avoids pattern engines" do
    assert_no_tokens!(source_files(), pattern_engine_tokens())
  end

  test "repo-owned source avoids dynamic atom construction" do
    assert_no_tokens!(source_files(), atom_construction_tokens())
  end

  test "repo-owned source avoids quoted atom literals outside strings" do
    hits =
      for file <- source_files(),
          source = File.read!(file),
          quoted_atom_literal?(source) do
        relative_path(file) <> " contains quoted atom literal"
      end

    assert hits == []
  end

  test "docs do not prescribe raw local Temporal dev server commands" do
    assert_no_tokens!(doc_files(), [raw_temporal_dev_command_token()])
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
      source_tree_files(
        [
          Path.join(@repo_root, "lib"),
          Path.join(@repo_root, "test"),
          Path.join(@repo_root, "native/temporalex_native/src")
        ],
        [".ex", ".exs", ".rs"]
      )
  end

  defp doc_files do
    source_tree_files([Path.join(@repo_root, "README.md"), Path.join(@repo_root, "guides")], [
      ".md"
    ])
  end

  defp source_tree_files(paths, extensions) do
    paths
    |> Enum.flat_map(&walk_files/1)
    |> Enum.filter(&has_extension?(&1, extensions))
    |> Enum.sort()
  end

  defp walk_files(path) do
    cond do
      File.dir?(path) ->
        path
        |> File.ls!()
        |> Enum.flat_map(&walk_files(Path.join(path, &1)))

      File.regular?(path) ->
        [path]

      true ->
        []
    end
  end

  defp has_extension?(path, extensions) do
    Enum.any?(extensions, &String.ends_with?(path, &1))
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

  defp raw_temporal_dev_command_token do
    IO.iodata_to_binary(["temporal", " server ", "start", "-dev"])
  end

  defp atom_construction_tokens do
    [
      ["String.to_", "atom"],
      ["String.to_existing_", "atom"],
      ["binary_to_", "atom"],
      ["binary_to_existing_", "atom"],
      ["list_to_", "atom"],
      ["list_to_existing_", "atom"],
      ["Module.", "concat"],
      [<<58>>, "#", "{"],
      [<<58>>, <<34>>, "#", "{"]
    ]
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp quoted_atom_literal?(source), do: quoted_atom_literal?(source, :code)

  defp quoted_atom_literal?(<<>>, _mode), do: false

  defp quoted_atom_literal?(<<?#, rest::binary>>, :code) do
    rest
    |> skip_until_newline()
    |> quoted_atom_literal?(:code)
  end

  defp quoted_atom_literal?(<<?", rest::binary>>, :code) do
    rest
    |> skip_string()
    |> quoted_atom_literal?(:code)
  end

  defp quoted_atom_literal?(<<?', rest::binary>>, :code) do
    rest
    |> skip_charlist()
    |> quoted_atom_literal?(:code)
  end

  defp quoted_atom_literal?(<<?~, sigil, delimiter, rest::binary>>, :code)
       when sigil in [?s, ?S] do
    rest
    |> skip_sigil(closing_delimiter(delimiter))
    |> quoted_atom_literal?(:code)
  end

  defp quoted_atom_literal?(<<?:, ?", _rest::binary>>, :code), do: true

  defp quoted_atom_literal?(<<_char, rest::binary>>, :code),
    do: quoted_atom_literal?(rest, :code)

  defp skip_until_newline(<<>>), do: <<>>
  defp skip_until_newline(<<?\n, rest::binary>>), do: rest
  defp skip_until_newline(<<_char, rest::binary>>), do: skip_until_newline(rest)

  defp skip_string(<<>>), do: <<>>
  defp skip_string(<<?\\, _escaped, rest::binary>>), do: skip_string(rest)
  defp skip_string(<<?", rest::binary>>), do: rest
  defp skip_string(<<_char, rest::binary>>), do: skip_string(rest)

  defp skip_charlist(<<>>), do: <<>>
  defp skip_charlist(<<?\\, _escaped, rest::binary>>), do: skip_charlist(rest)
  defp skip_charlist(<<?', rest::binary>>), do: rest
  defp skip_charlist(<<_char, rest::binary>>), do: skip_charlist(rest)

  defp closing_delimiter(40), do: 41
  defp closing_delimiter(91), do: 93
  defp closing_delimiter(123), do: 125
  defp closing_delimiter(60), do: 62
  defp closing_delimiter(delimiter), do: delimiter

  defp skip_sigil(rest, nil), do: rest
  defp skip_sigil(<<>>, _closing), do: <<>>
  defp skip_sigil(<<?\\, _escaped, rest::binary>>, closing), do: skip_sigil(rest, closing)
  defp skip_sigil(<<closing, rest::binary>>, closing), do: rest
  defp skip_sigil(<<_char, rest::binary>>, closing), do: skip_sigil(rest, closing)

  defp relative_path(path), do: Path.relative_to(path, @repo_root)
end
