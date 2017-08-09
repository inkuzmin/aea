defmodule AEA.Methods.Analytical do

    use GenServer

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

#    def go(pid, gene_set) do
#        [{_, ts}] = :ets.lookup :terms, :all
#    end

    # Server Callbacks
    def init(:ok) do
      {:ok, []}
    end


end