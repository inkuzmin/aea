defmodule AEA.Cache do
  use GenServer

  @name Cache

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: Cache])
  end

  def write(key, value) do
    GenServer.call(@name, {:write, key, value})
  end

  def read(key) do
    GenServer.call(@name, {:read, key})
  end

  def delete(key) do
    GenServer.cast(@name, {:delete, key})
  end

  def clear() do
    GenServer.cast(@name, :clear)
  end

  def exist?(key) do
    GenServer.call(@name, {:exist?, key})
  end


  # Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:write, key, value}, _from, state) do
    new_state = Map.put state, key, value
    {:reply, new_state, new_state}
  end
  def handle_call({:read, key}, _from, state) do
    value = Map.get state, key
    {:reply, value, state}
  end
  def handle_cast({:delete, key}, _from, state) do
    new_state = Map.delete state, key
    {:no_reply, new_state}
  end
  def handle_cast(:clear, _from, _state) do
    {:no_reply, %{}}
  end
  def handle_call({:exist?, key}, _from, state) do
    reply = Map.has_key? state, key
    {:reply, reply, state}
  end

  # Helpers

end