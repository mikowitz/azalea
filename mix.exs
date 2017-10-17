defmodule Azalea.Mixfile do
  use Mix.Project

  @name    :azalea
  @version "0.1.0"

  @deps [
    { :credo, "~> 0.8.8", only: [:dev, :test], runtime: false },
    { :ex_doc, "~> 0.18.1", only: [:dev, :test], runtime: false},
    { :mix_test_watch, "~> 0.5.0", only: :dev, runtime: false },
    { :stream_data, "~> 0.3.0" }
  ]

  # ------------------------------------------------------------

  def project do
    in_production = Mix.env == :prod
    [
      app:     @name,
      version: @version,
      elixir:  ">= 1.5.2",
      deps:    @deps,
      build_embedded:  in_production,
    ]
  end

  def application do
    [
      extra_applications: [         # built-in apps that need starting
        :logger
      ],
    ]
  end
end
