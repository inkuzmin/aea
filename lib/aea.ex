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


  def prepare() do

    IO.puts "Building hierarchy..."
    AEA.OBO.start

    IO.puts "Building maps"
    AEA.GMT.start

    IO.puts "Building lists"
    AEA.Cache.start_link

#    AEA.Cache.write :genes, (AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list)
#    AEA.Cache.write :terms, (AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list)

#    mtilda_gts = multiple_randomize(m_g, m_t, iterations, [])
#
#    p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)
#
#    {m_gt, mtilda_gts, p}
  end


  def determine_ms(genes, term) do
      terms = term |> get_terms_of_branch

      m_gt = determine_m_gt genes, terms
      m_t = terms |> get_genes_for_terms |> List.flatten |> length
      m_g = genes |> get_terms_for_genes |> List.flatten |> length

      {m_gt, m_g, m_t}
  end

  def shuffle(:genes) do
    AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list |> Enum.shuffle
  end
  def shuffle(:terms) do
    AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list |> Enum.shuffle
  end

  def randomize(gs, ts, m_g, m_t) do
    shuffled_genes = gs |> Enum.shuffle # shuffle(:genes) # AEA.Cache.read(:genes) |> Enum.shuffle
    shuffled_terms = ts |> Enum.shuffle # shuffle(:terms) # AEA.Cache.read(:terms) |> Enum.shuffle

    genes = AEA.Helpers.get_keys_with_closest_number_of_values :genes_to_terms, m_g, shuffled_genes, 0, []
    terms = AEA.Helpers.get_keys_with_closest_number_of_values :terms_to_genes, m_t, shuffled_terms, 0, []

    {genes, terms}
  end

#  def multiple_randomize(m_g, m_t, 0, mtilda_gts) do
#      mtilda_gts
#  end
#  def multiple_randomize(m_g, m_t, n, mtilda_gts) when n > 0 do
#      {g, t} = randomize(m_g, m_t)
#      mtilda_gt = determine_m_gt(g, t)
#      multiple_randomize(m_g, m_t, n - 1, [mtilda_gt | mtilda_gts])
#  end

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
                terms
            _ ->
                IO.inspect "Parsing error with #{inspect term}"
                [ ]
        end
  end

  def get_all_terms_of_branch([]) do
    []
  end
  def get_all_terms_of_branch([t | ts]) do
    [ t ] ++ get_all_terms_of_branch(get_terms_of_branch(t)) ++ get_all_terms_of_branch(ts)
  end

  def make_parent_to_children_table() do
    terms = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

    Enum.map terms, fn(term) ->
      [term | get_terms_of_branch(term)]
    end

  end

  def make_parent_to_progeny_table() do
    terms = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

    Enum.map terms, fn(term) ->
      get_all_terms_of_branch([term]) |> List.flatten |> Enum.uniq
    end
  end
end
