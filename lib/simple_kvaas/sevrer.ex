defmodule SimpleKVaaS.Server do
  use Plug.Router
  use Plug.ErrorHandler
  alias SimpleKVaaS.DB

  plug :match
  plug :dispatch

  get "/get/:key" do
    case DB.get(key) do
      {:ok, value} ->
        send_resp(conn, 200, value)
      :not_found ->
        send_resp(conn, 404, "not found")
      _ ->
        send_resp(conn, 500, "erred")
    end
  end

  get "/set/:key/:value" do
    DB.put(key, value)
    send_resp(conn, 200, "ok")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    send_resp(conn, conn.status, "error: " <> reason)
  end
end
