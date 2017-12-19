defmodule Cumulus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Cumulus.Worker.start_link(arg)
      # {Cumulus.Worker, arg},
      Honeydew.worker_spec(
        {:global, :encoder}, 
        Cumulus.Encoder, 
        num: 2, 
        nodes: [:"studio@zacks-macbook-pro"]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cumulus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end