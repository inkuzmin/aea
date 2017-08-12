defmodule AEA.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts
  end

  def parse_args(args) do
      {opts, genes, _} = args
        |> OptionParser.parse(switches: [method: :string, ],
                              aliases: [m: :method])
      {opts, genes}
  end

  def response({opts, genes}) do

     case String.upcase(opts[:method]) do
       "AEA" ->
            AEA.bootstrap
            {:ok, pid} = AEA.Computational.start_link
            AEA.Computational.go pid, genes
       "AEA-A" ->
            AEA.bootstrap
            {:ok, pid} = AEA.Analytical.start_link
            AEA.Analytical.go pid, genes
     end

     Process.sleep(:infinity)
  end




end