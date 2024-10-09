defmodule SimpleKVaaS.DB do
  use GenServer
  require Logger

  @ttl_prefix "time//"

  def init(args) do
    {:ok, args}
  end

  def start_link do
    path = Application.get_env(:simple_kvaas, :db_path)
    {:ok, db} = :eleveldb.open(String.to_charlist(path), [create_if_missing: true])
    Logger.info("db opened")
    GenServer.start_link(__MODULE__, db, [name: :db])
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
    }
  end

  def get(key) do
    GenServer.call(:db, {:get, key})
  end

  def key_stream() do
    GenServer.call(:db, {:key_stream})
  end
  def key_stream(prefix) do
    GenServer.call(:db, {:key_stream, prefix})
  end

  def put(key, value) do
    GenServer.cast(:db, {:put, key, value})
  end

  def del(key) do
    GenServer.cast(:db, {:delete, key})
  end

  def handle_call({:get, key}, _from, db) do
    {:reply, :eleveldb.get(db, key, []), db}
  end

  def handle_call({:key_stream}, _from, db) do
    {:reply, stream(db, &(!String.contains?(&1, "/"))), db}
  end

  def handle_call({:key_stream, prefix}, _from, db) do
    {:reply, stream(db, &(String.starts_with?(&1, prefix <> "/"))), db}
  end

  def handle_cast({:put, key, value}, db) do
    :ok = :eleveldb.put(db, key, value, [])
    :ok = :eleveldb.put(db, @ttl_prefix <> key, to_string(:os.system_time(:seconds)), [])
    {:noreply, db}
  end

  def handle_cast({:delete, key}, db) do
    :ok = :eleveldb.delete(db, key, [])
    :ok = :eleveldb.delete(db, @ttl_prefix <> key, [])
    {:noreply, db}
  end

  def terminate(reason, db) do
    Logger.info("db will be closed due to #{reason}")
    :eleveldb.close(db)
  end

  defp stream(db, func) do
    Stream.resource(
      fn ->
        {:ok, iter} = :eleveldb.iterator(db, [], :keys_only)
        {:first, iter}
      end,
      fn {state, iter} ->
        case :eleveldb.iterator_move(iter, state) do
          {:ok, k} ->
            case func.(k) do
              true -> {[k], {:next, iter}}
              false -> {[], {:next, iter}}
            end
          _ -> {:halt, {state, iter}}
        end
      end,
      fn {_, iter} ->
        :eleveldb.iterator_close(iter)
      end
    )
  end
end
