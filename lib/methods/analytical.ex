defmodule AEA.Methods.Analytical do

    use GenServer

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    # Server Callbacks
    def init(:ok) do
      {:ok, []}
    end

    # Helpers
    def calculate(gene_set) do
      [{:all, all_terms}] = :ets.lookup :terms, :all
      [{:all, all_genes}] = :ets.lookup :genes, :all

      {:ok, m_tot} = AEA.Determine.determine_m_tot all_genes, all_terms



      ps = Enum.map all_terms, fn(term) ->
        {m_gt, m_g, m_t} = AEA.Determine.determine_ms gene_set, term

        if m_gt > 0 do
            [term, AEA.Math.pval(m_gt, m_g, m_t, m_tot)]
        else
            [term, 1]
        end
      end

      AEA.Helpers.save_as_csv ps, "results.csv"
    end

end