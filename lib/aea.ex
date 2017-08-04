defmodule AEA do

  use GenServer

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


  def bootstrap() do
    IO.puts "Initializing data"
    {terms_to_genes, genes_to_terms, terms, genes} = AEA.GMT.start_from_cache
#    terms_to_children = AEA.OBO.start_from_cache
    terms_to_progeny = AEA.Hierarchy.start_from_cache

    IO.puts "Startng in-memory storages..."
    terms_to_genes |> AEA.Helpers.map_to_table |> AEA.Helpers.table_to_ets(:terms_to_genes)
    genes_to_terms |> AEA.Helpers.map_to_table |> AEA.Helpers.table_to_ets(:genes_to_terms)
    terms |> AEA.Helpers.list_to_ets(:terms)
    genes |> AEA.Helpers.list_to_ets(:genes)
    terms_to_progeny |> AEA.Helpers.map_to_table |> AEA.Helpers.table_to_ets(:terms_to_progeny)




#    p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)

  end




  def determine_ms(genes, term) do
      terms = term |> get_terms_of_branch |> List.flatten

      m_gt = determine_m_gt genes, terms
      m_t = terms |> get_genes_for_terms |> List.flatten |> length
      m_g = genes |> get_terms_for_genes |> List.flatten |> length

      {m_gt, m_g, m_t}
  end


  def randomize(gs, ts, m_g, m_t) do
    shuffled_genes = gs |> Enum.shuffle # shuffle(:genes) # AEA.Cache.read(:genes) |> Enum.shuffle
    shuffled_terms = ts |> Enum.shuffle # shuffle(:terms) # AEA.Cache.read(:terms) |> Enum.shuffle

    genes = AEA.Helpers.get_keys_with_closest_number_of_values :genes_to_terms, m_g, shuffled_genes, 0, []
    terms = AEA.Helpers.get_keys_with_closest_number_of_values :terms_to_genes, m_t, shuffled_terms, 0, []

    {genes, terms}
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
    AEA.Helpers.get_values_for_keys(:terms_to_progeny, [term])
  end


end
