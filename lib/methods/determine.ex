defmodule AEA.Determine do

    use GenServer

    @iterations 1000

    # Client API

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def put(pid, gs, ts) do
      GenServer.cast(pid, {:put, gs, ts})
    end

    def get(pid) do
      GenServer.call(pid, :get)
    end

    #  def go(pid, genes, term, iterations) do
    def determine(pid, parent_id, all_genes, all_terms, gene_set, term) do
      GenServer.cast(pid, {:determine, parent_id, all_genes, all_terms, gene_set, term})
    end


    # Server Callbacks

    def init(:ok) do
      { :ok, {0, "", 0, []} }
    end

    def handle_cast({:determine, parent_id, all_genes, all_terms, gene_set, term}, {_parent_id, _term, _m_gt, mtilda_gts}) do
      {m_gt, m_g, m_t} = determine_ms(gene_set, term)

      if m_gt > 0 do
          Enum.each 1..@iterations, fn(_) ->
            {:ok, pid} = AEA.Randomize.start_link
            AEA.Randomize.randomize pid, self(), all_genes, all_terms, m_g, m_t
          end

          {:noreply, {parent_id, term, m_gt, mtilda_gts}}
      else
          AEA.Computational.put(parent_id, term, 1)

          {:stop, :normal, {parent_id, term, m_gt, mtilda_gts}}
      end
    end

    def handle_cast({:put, gs, ts}, {parent_id, term, m_gt, mtilda_gts}) do
      mtilda_gt = determine_m_gt(gs, ts)

      mtilda_gts = [ mtilda_gt | mtilda_gts ]

      if length(mtilda_gts) < @iterations do
        {:noreply,  {parent_id, term, m_gt, mtilda_gts}}
      else
        p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)

        AEA.Computational.put(parent_id, term, p)

        {:stop, :normal, {parent_id, term, m_gt, mtilda_gts}}
      end
    end

    def handle_call(:get, _from, state) do
      {:reply, state, state }
    end

    def handle_info(_msg, state) do
    #    IO.puts "received #{inspect msg}"
      {:noreply, state}
    end

    def terminate(_reason, _state) do
#      IO.puts "determination"
      :ok
    end


    # Helpers

    def determine_m_tot(genes, terms) do
      m_tot1 = terms |> get_genes_for_terms |> List.flatten |> length
      m_tot2 = genes |> get_terms_for_genes |> List.flatten |> length

      if m_tot1 == m_tot2 do
        {:ok, m_tot1}
      else
        :error
      end
    end

    def determine_m_gt(genes, terms) do
      gene_sets = terms |> get_genes_for_terms

      Enum.reduce gene_sets, 0, fn (gene_set, acc) ->
        acc + (AEA.Helpers.intersect(gene_set, genes) |> length)
      end
    end

    def determine_ms(genes, term) do
        terms = term |> get_terms_of_branch

        m_gt = determine_m_gt genes, terms

        # m_t = terms |> get_genes_for_terms |> List.flatten |> length
        m_t = AEA.Helpers.get_total_number_of_values_for_keys(:terms_to_genes, terms)

        # m_g = genes |> get_terms_for_genes |> List.flatten |> length
        m_g = AEA.Helpers.get_total_number_of_values_for_keys(:genes_to_terms, genes)

        {m_gt, m_g, m_t}
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
                  [ term | terms ]
              _ ->
                  IO.inspect "Parsing error with #{inspect term}"
                  []

          end
    end



end