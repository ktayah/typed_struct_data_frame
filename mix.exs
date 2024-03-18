defmodule TypedStructDataFrame.MixProject do
  use Mix.Project

  @repo_url "https://github.com/ktayah/typed_struct_data_frame"

  def project do
    [
      app: :typed_struct_data_frame,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "TypedStructDataFrame",
      docs: [
        main: "TypedStructDataFrame",
        source_url: @repo_url,
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:decimal, "~> 2.1.1"},
      {:money, "~> 1.12.4"},
      {:typed_struct, "~> 0.3.0"},
      # FIXME: Upgrade explorer to 0.8.1
      {:explorer, "== 0.7.1"},
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end

  defp description do
    """
    A `TypedStruct` plugin to allow conversions to and from Explorer.DataFrames
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/typed_struct/changelog.html",
        "GitHub" => @repo_url
      }
    ]
  end
end
