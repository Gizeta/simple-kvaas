defmodule SimpleKVaaS.DB do
  use GenServer
  require Logger

  @ttl_prefix "time/"

  def init(args) do
    {:ok, args}
  end

  def start_link do
    path = Application.get_env(:simple_kvaas, :db_path)
    {:ok, db} = :eleveldb.open(String.to_charlist(path), [create_if_missing: true])
    Logger.info("db opened")
    GenServer.start_link(__MODULE__, db, [name: :db])
  end

  def get(key) do
    GenServer.call(:db, {:get, key})
  end

  def put(key, value) do
    GenServer.cast(:db, {:put, key, value})
  end

  def del(key) do
    GenServer.cast(:db, {:delete, key})
  end

  def each(func) do
    GenServer.cast(:db, {:each, func})
  end

  def handle_call({:get, key}, _from, db) do
    {:reply, :eleveldb.get(db, key, []), db}
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

  def handle_cast({:each, func}, db) do
    {:ok, itr} = :eleveldb.iterator(db, [])
    case :eleveldb.iterator_move(itr, :first) do
      {:ok, key, value} ->
        func.(key, value)
        iter_loop(db, itr, func)
      _ ->
        :ok
    end
    {:noreply, db}
  end

  def terminate(reason, db) do
    Logger.info("db will be closed due to #{reason}")
    :eleveldb.close(db)
  end

  defp iter_loop(db, itr, func) do
    case :eleveldb.iterator_move(itr, :next) do
      {:ok, key, value} ->
        func.(key, value)
        iter_loop(db, itr, func)
      _ ->
        :ok
    end
  end
end
