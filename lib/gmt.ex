defmodule AEA.GMT do

    def start(filename \\ "./data/hsapiens.GO.ENSG.gmt") do

       {ts, gs} = filename |> Path.expand |> File.stream! |> parse

       ts_table = ts |> AEA.Helpers.map_to_table
       gs_table = gs |> AEA.Helpers.map_to_table

       AEA.Helpers.save_as_csv(ts_table, "./cache/terms_to_genes.csv")
       AEA.Helpers.save_as_csv(gs_table, "./cache/genes_to_terms.csv")

       {ts, gs}
    end

    def parse(lines) do
      Enum.reduce(lines, { %{}, %{} }, fn(line, { terms_to_genes, genes_to_terms }) ->
        case line |> String.replace("\n", "") |> String.split("\t", trim: true) do
          [term | [ term_name | genes ] ] ->
            {
              add(terms_to_genes, term, genes),
              Enum.reduce(genes, genes_to_terms, fn(gene, acc) -> add(acc, gene, [term]) end)
            }
          _ ->
            { terms_to_genes, genes_to_terms }
        end
      end)
    end

    def add(table, key, new) when is_list(new) do
       case Map.has_key?(table, key) do
         true  -> Map.update! table, key, fn(value) ->
               new ++ value
           end
         false ->
             Map.put table, key, new
       end
    end

end