defmodule AEA.Methods.Computational do
    use GenServer

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def go(pid, gene_set) do
      GenServer.cast(pid, {:go, gene_set})
    end

    def put(pid, term, p) do
      GenServer.cast(pid, {:put, term, p})
    end

    # Server Callbacks
    def init(:ok) do
      { :ok, {0, []} }
    end

    def handle_cast({:go, gene_set}, {_number_of_terms, _ps}) do
        [{:all, all_terms}] = :ets.lookup :terms, :all
        [{:all, all_genes}] = :ets.lookup :genes, :all

        Enum.each all_terms, fn(term) ->
            {:ok, pid} = AEA.Determine.start_link
            AEA.Determine.determine pid, self(), all_genes, all_terms, gene_set, term
        end

        {:noreply, {length(all_terms), []}}
    end

    def handle_cast({:put, term, p}, {number_of_terms, ps}) do
        ps = [ [term, p] | ps ]

        if length(ps) >= number_of_terms do
#          Enum.each ps, fn({term, p}) ->
#            IO.puts "p-val of #{term} = #{p}"
#          end

          AEA.Helpers.save_as_csv ps, "results.csv"
          {:stop, :normal, {number_of_terms, ps}}
        else
          {:noreply, {number_of_terms, ps}}
        end
    end


end