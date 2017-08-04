defmodule Hierarchy do

    def start(:re) do
      build_hierarchy
    end
    def start() do
      _terms_to_terms = :ets.new(:terms_to_branches, [:set, :protected, :named_table])
      build_hierarchy
    end

    def build_hierarchy do

#      table = make_parent_to_progeny_table()
#      Enum.each table

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

    def make_parent_to_children_table() do
      terms = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

      Enum.map terms, fn(term) ->
        [term | get_terms_of_branch(term)]
      end

    end

    def in_GMT(list, terms) do
      Enum.filter list, fn(term) ->
          Enum.member? terms, term
      end
    end

    def make_parent_to_progeny_table() do
      terms = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

      Enum.map terms, fn(term) ->
        get_all_terms_of_branch([term]) |> List.flatten |> Enum.uniq |> in_GMT(terms)
      end
    end

    def upsert(parent, child) do
      case :ets.lookup :terms_to_terms, parent do
        [] ->
          :ets.insert :terms_to_terms, {parent, [ child ]}
        [{_, children}] ->
          :ets.insert :terms_to_terms, {parent, [ child | children ]}
      end
    end



end