defmodule AEA.Calculate do

    use GenServer

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def calculate(pid, parent_id, gene_set, term, m_tot) do
      GenServer.cast(pid, {:calculate, parent_id, gene_set, term, m_tot})
    end

    # Server Callbacks
    def init(:ok) do
      {:ok, []}
    end

    def handle_cast({:calculate, parent_id, gene_set, term, m_tot}, state) do
      {m_gt, m_g, m_t} = AEA.Determine.determine_ms(gene_set, term)

      if m_gt > 0 do
        p = AEA.Math.pval(m_gt, m_g, m_t, m_tot)
        AEA.Analytical.put(parent_id, term, p)
      else
        AEA.Analytical.put(parent_id, term, 1)
      end

      {:stop, :normal, state}
    end

    def handle_info(_msg, state) do
    #    IO.puts "received #{inspect msg}"
      {:noreply, state}
    end

    def terminate(_reason, _state) do
    #      IO.puts "determination"
      :ok
    end

end