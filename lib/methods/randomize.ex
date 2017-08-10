defmodule AEA.Randomize do
  @moduledoc false

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def randomize(pid, coord_pid, genes, terms, m_g, m_t) do
    GenServer.cast(pid, {:randomize, coord_pid, genes, terms, m_g, m_t})
  end

  # Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:randomize, coord_pid, genes, terms, m_g, m_t}, state) do
    {gs, ts} = randomize(genes, terms, m_g, m_t)

    AEA.Determine.put coord_pid, gs, ts

    {:stop, :normal, state}
  end

  def handle_info(_msg, state) do
#    IO.puts "received #{inspect msg}"
    {:noreply, state}
  end

  def terminate(_reason, _stats) do
#    IO.puts "random off"
#        inspect stats
    :ok
  end


  # Helpers

  def randomize(gs, ts, m_g, m_t) do
    genes = get_keys_with_closest_number_of_values :genes_to_terms, m_g, gs, 0, [], [], true
    terms = get_keys_with_closest_number_of_values :terms_to_genes, m_t, ts, 0, [], [], true

    {genes, terms}
  end

  @doc """
  One of the most important functions. Optimized and completely unreadably as those.
  """
  def get_keys_with_closest_number_of_values(table, _required_number_of_values, keys, acc_number_of_values, acc_keys, used_indexes, false)  when is_atom(table) do
    if acc_number_of_values == 0 do
        # This guarantees that at list one key will be returned
        Enum.map used_indexes, fn(idx) ->
            Enum.fetch! keys, idx
        end
    else
        acc_keys
    end
  end
  def get_keys_with_closest_number_of_values(table, required_number_of_values, keys, acc_number_of_values, acc_keys, used_indexes, continue?)  when is_atom(table) do
    try do
      max_index = (keys |> length)
      random_index = random_and_unused_index max_index, used_indexes


      key = Enum.fetch! keys, random_index
      used_indexes = [ random_index | used_indexes]

      i = case :ets.lookup(table, key) do
          [{_, values}] ->
            length(values)
          [] ->
            0
          _ ->
            IO.puts "Error with #{inspect key}"
            0
      end



      if (acc_number_of_values + i) - required_number_of_values >= 0 do
          if abs((acc_number_of_values + i) - required_number_of_values) <= abs(acc_number_of_values - required_number_of_values) do
              get_keys_with_closest_number_of_values(table, required_number_of_values, keys, (acc_number_of_values + i), [key | acc_keys], used_indexes, false)
          else
              get_keys_with_closest_number_of_values(table, required_number_of_values, keys, acc_number_of_values, acc_keys, used_indexes, false)
          end
      else
          get_keys_with_closest_number_of_values(table, required_number_of_values, keys, (acc_number_of_values + i), [key | acc_keys], used_indexes, continue?)
      end


    rescue
      e in RuntimeError ->
        IO.puts "#{inspect e}"
        get_keys_with_closest_number_of_values(table, required_number_of_values, keys, acc_number_of_values, acc_keys, used_indexes, false)
    end
  end

  def random_and_unused_index(max_index, used_indexes) do
    random_index = :rand.uniform(max_index) - 1
    if Enum.member? used_indexes, random_index do
      if length(used_indexes) == max_index do
        raise "all keys enumerated"
      else
        random_and_unused_index(max_index, used_indexes)
      end
    else
      random_index
    end
  end

end