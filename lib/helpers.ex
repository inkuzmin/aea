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


     def get_values_for_keys(table, keys) when is_atom(table) do
       Enum.map keys, fn (k) ->
         case :ets.lookup(table, k) do
             [{_, values}] ->
                 values
             [] ->
                 []
             _ ->
                 IO.puts "Another error with #{inspect k}"
         end
       end
     end

     def measure(function) do
       function
       |> :timer.tc
       |> elem(0)
       |> Kernel./(1_000_000)
     end




    @doc """
    One of the most important functions.
    """
    def get_keys_with_closest_number_of_values(table, required_number_of_values, [ key ], acc_number_of_values, acc_keys)  when is_atom(table) do
      if acc_number_of_values == 0 do
          # This guarantees that at list one key will be returned
          [ key ]
      else
          acc_keys
      end
    end
    def get_keys_with_closest_number_of_values(table, required_number_of_values, [key | keys], acc_number_of_values, acc_keys)  when is_atom(table) do
      i = case :ets.lookup(table, key) do
          [{_, values}] ->
            length(values)
          [] ->
            0
          _ ->
            IO.puts "Error with #{inspect key}"
            0
      end

      if (acc_number_of_values + i) - required_number_of_values >= 0 do
          if abs((acc_number_of_values + i) - required_number_of_values) <= abs(acc_number_of_values - required_number_of_values) do
              get_keys_with_closest_number_of_values(table, required_number_of_values, [key], (acc_number_of_values + i), [key | acc_keys])
          else
              get_keys_with_closest_number_of_values(table, required_number_of_values, [key], acc_number_of_values, acc_keys)
          end
      else
          get_keys_with_closest_number_of_values(table, required_number_of_values, keys, (acc_number_of_values + i), [key | acc_keys])
      end
    end


end