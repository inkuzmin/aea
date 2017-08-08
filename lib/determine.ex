defmodule AEA.Determine do

    use GenServer

    # Client API

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def put(pid, gs, ts, iterations) do
      GenServer.cast(pid, {:put, gs, ts, iterations})
    end

    def get(pid) do
      GenServer.call(pid, :get)
    end

    #  def go(pid, genes, term, iterations) do
    def go(pid, all_genes, all_terms, gene_set, term, iterations \\ 10_000) do
      GenServer.cast(pid, {:go, all_genes, all_terms, gene_set, term, iterations})
    end


    # Server Callbacks

    def init(:ok) do
      {:ok, []}
    end

    def handle_cast({:put, gs, ts, iterations}, state) do
      mtilda_gt = determine_m_gt(gs, ts)

      new_state = [ mtilda_gt | state ]
      if length(new_state) < iterations do
        {:noreply, new_state}
      else
        {:stop, :normal, new_state}
      end
    end


    #  def handle_cast({:go, genes, term, iterations}, state) do
    def handle_cast({:go, all_genes, all_terms, gene_set, term, iterations}, state) do

      {m_gt, m_g, m_t} = determine_ms(gene_set, term)

      if m_gt > 0 do
          Enum.each 1..iterations, fn(_) ->
            {:ok, pid} = AEA.Randomize.start_link
            AEA.Randomize.randomize pid, self(), all_genes, all_terms, m_g, m_t, iterations
          end
      else
          0
      end
        {:noreply, state }
    end

    def handle_call(:get, _from, state) do
      {:reply, state, state }
    end

    def handle_info(_msg, state) do
    #    IO.puts "received #{inspect msg}"
      {:noreply, state}
    end

    def terminate(_reason, state) do
    #    IO.puts "server terminated because of #{inspect reason}"

      IO.puts "#{inspect state}"
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
        m_t = terms |> get_genes_for_terms |> List.flatten |> length
        m_g = genes |> get_terms_for_genes |> List.flatten |> length

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
                  Enum.map terms, &get_terms_of_branch/1

                  [ term | terms ] # TODO: recursively take all children
              _ ->
                  IO.inspect "Parsing error with #{inspect term}"
                  []

          end
    end



end