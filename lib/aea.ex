defmodule AEA do

  use GenServer
  import AEA.Helpers

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def put(pid, mtilda_gt) do
    GenServer.cast(pid, {:put, mtilda_gt})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def go(pid, genes, term, iterations) do
    GenServer.cast(pid, {:go, genes, term, iterations})
  end

  # Server Callbacks
  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:put, mtilda_gt}, state) do
    {:noreply, [ mtilda_gt | state ]}
  end

  def handle_cast({:go, genes, term, iterations}, state) do

    {m_gt, m_g, m_t} = determine_ms(genes, term)

    gs = AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list
    ts = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

    Enum.each 1..iterations, fn(_) ->
      {:ok, pid} = AEA.Randomize.Worker.start_link
      AEA.Randomize.Worker.randomize pid, self(), gs, ts, m_g, m_t
    end


    {:noreply, state }
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state }
  end


  # Helpers

  def bootstrap do
    {terms_to_genes, genes_to_terms, terms, genes} = AEA.GMT.start_from_cache
    terms_to_terms = AEA.Hierarchy.start_from_cache

    terms_to_genes |> map_to_table |> table_to_ets(:terms_to_genes)
    genes_to_terms |> map_to_table |> table_to_ets(:genes_to_terms)
    terms_to_terms |> map_to_table |> table_to_ets(:terms_to_terms)
    terms |> list_to_ets(:terms)
    genes |> list_to_ets(:genes)

    {genes, terms}
  end


  def prepare() do

    IO.puts "Building hierarchy..."
    AEA.OBO.start

    IO.puts "Building maps"
    AEA.GMT.start

    IO.puts "Building hierarchy"
    AEA.Hierarchy.start

#    IO.puts "Building lists"
#    AEA.Cache.start_link

#    AEA.Cache.write :genes, (AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list)
#    AEA.Cache.write :terms, (AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list)

#    mtilda_gts = multiple_randomize(m_g, m_t, iterations, [])
#
#    p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)
#
#    {m_gt, mtilda_gts, p}
  end

  def calculate_aea_a(all_genes, all_terms, gene_set, term) do
    m_tot = determine_m_tot all_genes, all_terms

    {m_gt, m_g, m_t} = determine_ms gene_set, term

    Enum.reduce m_gt..min(m_g, m_t), 0, fn(i, acc) ->
        acc + AEA.Math.choose(m_t, i) * AEA.Math.choose(m_tot - m_t, m_g - i) / AEA.Math.choose(m_tot, m_g)
    end
  end

  def determine_m_tot(genes, terms) do
    m_tot1 = terms |> get_genes_for_terms |> List.flatten |> length
    m_tot2 = genes |> get_terms_for_genes |> List.flatten |> length

    if m_tot1 == m_tot2 do
      {:ok, m_tot1}
    else
      :error
    end
  end


  def determine_ms(genes, term) do
      terms = term |> get_terms_of_branch

      m_gt = determine_m_gt genes, terms
      m_t = terms |> get_genes_for_terms |> List.flatten |> length
      m_g = genes |> get_terms_for_genes |> List.flatten |> length

      {m_gt, m_g, m_t}
  end

  def randomize(gs, ts, m_g, m_t) do
    genes = get_keys_with_closest_number_of_values :genes_to_terms, m_g, gs, 0, [], [], true
    terms = get_keys_with_closest_number_of_values :terms_to_genes, m_t, ts, 0, [], [], true

    {genes, terms}
  end

  @doc """
  One of the most important functions. Optimized and completely unreadably as those.
  """
  def get_keys_with_closest_number_of_values(table, required_number_of_values, keys, acc_number_of_values, acc_keys, used_indexes, false)  when is_atom(table) do
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


  def determine_m_gt(genes, terms) do
    gene_sets = terms |> get_genes_for_terms

    m_gt = Enum.reduce gene_sets, 0, fn (gene_set, acc) ->
      acc + (AEA.Helpers.intersect(gene_set, genes) |> length)
    end
  end


  def get_terms_for_genes(genes) do
    AEA.Helpers.get_values_for_keys(:genes_to_terms, genes)
  end

  def get_genes_for_terms(terms) do
    AEA.Helpers.get_values_for_keys(:terms_to_genes, terms)
  end


  def get_terms_of_branch(term) do
        case :ets.lookup(:terms_to_terms, term) do
            [{ term, terms }] ->
                Enum.map terms, &get_terms_of_branch/1

                [ term | terms ] # TODO: recursively take all children
            _ ->
                IO.inspect "Parsing error with #{inspect term}"
                []

        end
  end

end
