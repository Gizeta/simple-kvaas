defmodule SimpleKVaaS do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: SimpleKVaaS.Server, options: [
        port: Application.get_env(:simple_kvaas, :server_port)
      ]),
      SimpleKVaaS.DB,
    ]

    options = [strategy: :one_for_one, name: SimpleKVaaS.Supervisor]
    Supervisor.start_link(children, options)
  end
end
