defmodule AEA.OBO do

  def start(:re) do
    filename |> read_obo
  end
  def start() do
    _terms_to_terms = :ets.new(:terms_to_terms, [:set, :protected, :named_table])
    filename |> read_obo
  end

  def read_obo(path) do
    path |> File.read! |> parse_obo
  end

  def parse_obo(string) do
    [ _header | stanzas ] = String.split(string, "\n\n")
    Enum.each(stanzas, &parse_stanza/1)
  end

  def parse_stanza(stanza) do
    case String.split(stanza, "\n") do
      [ "[Term]" | tags ] ->
        t = Enum.map(tags, &parse_tag/1)

        if Keyword.get(t, :is_obsolete) != "true" do
            save_rel Keyword.get(t, :id), Keyword.take(t, [:is_a]), :is_a # is_a values
            save_rel Keyword.get(t, :id), Keyword.take(t, [:relationship]), :part_of # relationship values
        end
      _ ->
        IO.puts "Unknown stanza"
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

  def save_rel(id, parents, :is_a) do
    Enum.each parents, fn({_,parent}) ->
      case Regex.run(~r{GO:\d+}, parent) do
        [ parent_id ] -> upsert parent_id, id # save
        _ -> IO.puts "Unknown id"
      end
    end
  end
  def save_rel(id, parents, :part_of) do
    Enum.each parents, fn({_,parent}) ->
      case Regex.run(~r{part_of (GO:\d+)}, parent) do
        [ _, parent_id ] -> upsert parent_id, id # save
        _ -> IO.puts "Unknown id"
      end
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

  def filename do
    Path.expand("./data/go.obo")
  end


end