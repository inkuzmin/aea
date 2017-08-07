defmodule AEA.Randomize.Worker do
  @moduledoc false

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def randomize(pid, coord_pid, genes, terms, m_g, m_t, iterations) do
    GenServer.cast(pid, {:randomize, coord_pid, genes, terms, m_g, m_t, iterations})
  end

  # Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:randomize, coord_pid, genes, terms, m_g, m_t, iterations}, state) do
    {g, t} = AEA.randomize(genes, terms, m_g, m_t)
    mtilda_gt = AEA.determine_m_gt(g, t)

    AEA.put coord_pid, mtilda_gt, iterations

     {:stop, :normal, state}
  end

  def handle_info(msg, state) do
#    IO.puts "received #{inspect msg}"
    {:noreply, state}
  end

  def terminate(reason, stats) do
#    IO.puts "server terminated because of #{inspect reason}"
#        inspect stats
    :ok
  end
end