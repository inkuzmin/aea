defmodule AEA.Hierarchy do

    def start(terms_list, children_table) do
      make_parent_to_progeny_table(terms_list)
    end

    def get_terms_of_branch(term) do
          case :ets.lookup(:terms_to_terms, term) do
              [{ term, terms }] ->
                  terms
              _ ->
                  IO.inspect "Parsing error with #{inspect term}"
                  [ ]
          end
    end

    def get_all_terms_of_branch([]) do
      []
    end
    def get_all_terms_of_branch([t | ts]) do
      [ t ] ++ get_all_terms_of_branch(get_terms_of_branch(t)) ++ get_all_terms_of_branch(ts)
    end


    def in_GMT(list, terms) do
      Enum.filter list, fn(term) ->
          Enum.member? terms, term
      end
    end

    def make_parent_to_progeny_table(terms) do
      Enum.map terms, fn(term) ->
        get_all_terms_of_branch([term]) |> List.flatten |> Enum.uniq |> in_GMT(terms)
      end
    end

end