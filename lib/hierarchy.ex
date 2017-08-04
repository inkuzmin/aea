defmodule AEA.Hierarchy do

    @cache "./cache/terms_to_progeny.csv"

    def start_from_cache(cache \\ @cache) do
       case File.exists? cache do
         true -> AEA.Helpers.tsf_to_table(cache) |> AEA.Helpers.table_to_map
         false -> :error
       end
    end

    def start(terms, terms_to_children) do
      terms_to_progeny_table = Enum.map terms, fn(term) ->
        get_terms_of_branch([term], terms_to_children) |> List.flatten |> Enum.uniq |> Enum.filter(&Enum.member?(terms, &1))
      end

      terms_to_progeny_table |> AEA.Helpers.save_as_csv(@cache)

      terms_to_progeny_table |> AEA.Helpers.table_to_map
    end

    def get_terms_of_branch([], _terms_to_children) do
      []
    end
    def get_terms_of_branch([t | ts], terms_to_children) do
      children = case Map.fetch terms_to_children, t do
        {:ok, cs} -> cs
        :error -> []
      end
      [t] ++ get_terms_of_branch(children, terms_to_children) ++ get_terms_of_branch(ts, terms_to_children)
    end

end