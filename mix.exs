defmodule Policy.Mixfile do
  use Mix.Project

  def project do
    [app: :policy,
     version: "1.0.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: Mix.env != :test,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:plug, "~> 1.0"},
     {:ecto, "~> 2.0"}]
  end

  defp description do
    """
    Policy is an authorization management framework for Phoenix.  It aims to be
    minimally invasive and secure by default.
    """
  end

  defp package do
    [name: :policy,
     maintainers: ["Ben Cates <ben@system76.com>"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/system76/policy"}]
  end
end
