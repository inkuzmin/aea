defmodule AEA.OBO do

  @filename "./data/go.obo"
  @cache "./cache/terms_to_terms.csv"

  def start_from_cashe(cache \\ @cache) do
     case File.exists? cache do
       true -> AEA.Helpers.tsf_to_table(cache) |> AEA.Helpers.table_to_map
       false -> :error
     end
  end

  def start(filename \\ @filename) do
    terms_to_children = filename |> Path.expand |> File.read! |> parse
    terms_to_children |> AEA.Helpers.map_to_table |> AEA.Helpers.save_as_csv(@cache)

    terms_to_children
  end

  def parse(string) do
    [ _header | stanzas ] = String.split(string, "\n\n")
    Enum.reduce(stanzas, %{}, &parse_stanza/2)
  end

  def parse_stanza(stanza, acc) do
    case String.split(stanza, "\n") do
      [ "[Term]" | tags ] ->
        t = Enum.map(tags, &parse_tag/1)

        case Keyword.get(t, :is_obsolete) != "true" do
          true ->
            a = save_rel acc, Keyword.get(t, :id), Keyword.take(t, [:is_a]), :is_a
            save_rel a, Keyword.get(t, :id), Keyword.take(t, [:relationship]), :part_of
          false ->
            acc
        end

      _ ->
        IO.puts "Unknown stanza"
        acc
    end
  end

  def parse_tag(tag) do
    case String.split(tag, ":", [parts: 2, trim: true]) do
      [ tag, value ] ->
        { String.to_atom(tag), String.strip(value) }
      _ ->
        IO.puts "Unknown tag"
    end
  end

  def save_rel(acc, id, parents, :is_a) do
    Enum.reduce parents, acc, fn({_,parent}, a) ->
      case Regex.run(~r{GO:\d+}, parent) do
        [ parent_id ] ->
          add a, parent_id, [ id ]
        _ ->
          IO.puts "Unknown id"
          a
      end
    end
  end
  def save_rel(acc, id, parents, :part_of) do
    Enum.reduce parents, acc, fn({_,parent}, a) ->
      case Regex.run(~r{part_of (GO:\d+)}, parent) do
        [ _, parent_id ] ->
           add a, parent_id, [ id ]
        _ ->
          IO.puts "Unknown id"
          a
      end
    end
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