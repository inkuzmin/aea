defmodule AEA.Helpers do

    def get_ets_keys_lazy(table_name) when is_atom(table_name) do
        eot = :"$end_of_table"

        Stream.resource(
            fn -> [] end,

            fn acc ->
                case acc do
                    [] ->
                        case :ets.first(table_name) do
                            ^eot -> {:halt, acc}
                            first_key -> {[first_key], first_key}
                        end

                    acc ->
                        case :ets.next(table_name, acc) do
                            ^eot -> {:halt, acc}
                            next_key -> {[next_key], next_key}
                        end
                end
            end,

            fn _acc -> :ok end
        )
    end

    def intersect(a, b), do: a -- (a -- b)


end