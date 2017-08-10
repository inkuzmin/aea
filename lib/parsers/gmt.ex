defmodule AEA.GMT do

    @filename "./data/hsapiens.GO.ENSG.gmt"
    @cache_ts "./cache/terms_to_genes.csv"
    @cache_gs "./cache/genes_to_terms.csv"

    def start_from_cache(cache_ts \\ @cache_ts, cache_gs \\ @cache_gs) do
       ts = case File.exists? cache_ts do
         true -> AEA.Helpers.tsf_to_table(cache_ts) |> AEA.Helpers.table_to_map
         false -> :error
       end
       gs = case File.exists? cache_gs do
         true -> AEA.Helpers.tsf_to_table(cache_gs) |> AEA.Helpers.table_to_map
         false -> :error
       end
       {ts, gs, Map.keys(ts), Map.keys(gs)}
    end

    def start(filename \\ @filename) do

       {ts, gs} = filename |> Path.expand |> File.stream! |> parse

       ts_table = ts |> AEA.Helpers.map_to_table
       gs_table = gs |> AEA.Helpers.map_to_table

       AEA.Helpers.save_as_csv(ts_table, @cache_ts)
       AEA.Helpers.save_as_csv(gs_table, @cache_gs)

       {ts, gs, Map.keys(ts), Map.keys(gs)}
    end

    def parse(lines) do
      Enum.reduce(lines, { %{}, %{} }, fn(line, { terms_to_genes, genes_to_terms }) ->
        case line |> String.replace("\n", "") |> String.split("\t", trim: true) do
          [term | [ _term_name | genes ] ] ->
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