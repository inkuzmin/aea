defmodule AEA.Analytical do

    use GenServer

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def put(pid, term, p) do
      GenServer.cast(pid, {:put, term, p})
    end

    def go(pid, gene_set) do
      GenServer.cast(pid, {:go, gene_set})
    end


    # Server Callbacks
    def init(:ok) do
      { :ok, {0, []} }
    end

    # Helpers
    def handle_cast({:go, gene_set}, {_number_of_terms, _ps}) do
      [{:all, all_terms}] = :ets.lookup :terms, :all
      [{:all, all_genes}] = :ets.lookup :genes, :all

      {:ok, m_tot} = AEA.Determine.determine_m_tot all_genes, all_terms



      Enum.each all_terms, fn(term) ->

        {:ok, pid} = AEA.Calculate.start_link
        AEA.Calculate.calculate pid, self(), gene_set, term, m_tot
      end


      {:noreply, {length(all_terms), []}}
    end

    def handle_cast({:put, term, p}, {number_of_terms, ps}) do
        ps = [ [term, p] | ps ]

        if length(ps) >= number_of_terms do
          AEA.Helpers.save_as_csv ps, "results.csv"
          {:stop, :normal, {number_of_terms, ps}}
        else
          {:noreply, {number_of_terms, ps}}
        end
    end

    def handle_info(msg, state) do
      IO.puts "received unknown #{inspect msg}"
      {:noreply, state}
    end

    def terminate(_reason, _state) do
      IO.puts "Done!"
      :ok
    end
end