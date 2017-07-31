defmodule AEA.GMT do

    def start(:re) do
      filename |> read_gmt
    end
    def start() do
       _terms_to_genes = :ets.new(:terms_to_genes, [:set, :protected, :named_table])
       _genes_to_terms = :ets.new(:genes_to_terms, [:set, :protected, :named_table])
       filename |> read_gmt
    end

    defp read_gmt(path) do
      path |> File.stream! |> parse_lines
    end

    defp parse_lines(lines) do
      Enum.each(lines, &parse_line/1)
    end

    def parse_line(line) do
        case line |> String.replace("\n", "") |> String.split("\t", trim: true) do
          [term | [ term_name | genes ] ] ->
            Enum.each genes, &update_genes_table(&1, term)
            case :ets.lookup :terms_to_genes, term do
              [] ->
                :ets.insert :terms_to_genes, {term, genes}
              [{_, gs}] ->
                :ets.insert :terms_to_genes, {term, gs ++ genes}
            end
          _ ->
            :error
        end
    end

    defp update_genes_table(gene, term) do
      case :ets.lookup :genes_to_terms, gene do
        [] ->
          :ets.insert :genes_to_terms, {gene, [ term ]}
        [{_, ts}] ->
          :ets.insert :genes_to_terms, {gene, [ term | ts ]}
      end
    end

    defp filename do
      Path.expand("./data/hsapiens.GO.ENSG.gmt")
    end

end