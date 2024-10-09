defmodule SimpleKVaaS.Server do
  use Plug.Router
  use Plug.ErrorHandler
  alias SimpleKVaaS.DB
  import Plug.Conn

  plug :match
  plug :dispatch

  get "/get/:key" do
    conn |> do_read(key)
  end

  get "/set/:key/:value" do
    conn |> do_write(key, value)
  end

  post "/set/:key" do
    value = conn |> build_body()
    conn |> do_write(key, value)
  end

  get "/:scope/get/:key" do
    conn |> do_read("#{scope}/#{key}")
  end

  get "/:scope/set/:key/:value" do
    conn |> do_write("#{scope}/#{key}", value)
  end

  post "/:scope/set/:key" do
    value = conn |> build_body()
    conn |> do_write("#{scope}/#{key}", value)
  end

  get "/list" do
    conn |> do_list("")
  end

  get "/list/:scope" do
    conn |> do_list(scope)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    send_resp(conn, conn.status, "error: " <> reason)
  end

  defp do_read(conn, key) do
    conn |> put_resp_content_type("text/html;charset=UTF-8")
    case DB.get(key) do
      {:ok, value} ->
        send_resp(conn, 200, value)
      :not_found ->
        send_resp(conn, 404, "not found")
      _ ->
        send_resp(conn, 500, "erred")
    end
  end

  defp do_write(conn, key, value) do
    DB.put(key, value)
    send_resp(conn, 200, "ok")
  end

  defp do_list(conn, "") do
    conn = conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)

    Enum.map(DB.key_stream(), fn (k) ->
      chunk(conn, k)
      chunk(conn, "\n")
    end)
    conn
  end

  defp do_list(conn, scope) do
    conn = conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)

    Enum.map(DB.key_stream(scope), fn (k) ->
      chunk(conn, k)
      chunk(conn, "\n")
    end)
    conn
  end

  defp build_body(conn, chunked \\ "") do
    case read_body(conn) do
      {:ok, body, _} -> chunked <> body
      {:more, body, conn} -> build_body(conn, chunked <> body)
    end
  end
end
