defmodule AEA do

  def init(genes, term, iterations) do

    {m_gt, m_g, m_t} = determine_ms(genes, term)

    gs = AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list
    ts = AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list

    mtilda_gts = multiple_randomize(gs, ts, m_g, m_t, iterations, [])

    p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)

    {m_gt, mtilda_gts, p}
  end
  def init(genes, term) do
    init(genes, term, 10_000)
  end


  def determine_ms(genes, term) do
      terms = term |> get_terms_of_branch

      m_gt = determine_m_gt genes, terms
      m_t = terms |> get_genes_for_terms |> List.flatten |> length
      m_g = genes |> get_terms_for_genes |> List.flatten |> length

      {m_gt, m_g, m_t}
  end

  def shuffle(:genes) do
    AEA.Helpers.get_ets_keys_lazy(:genes_to_terms) |> Enum.to_list |> Enum.shuffle
  end
  def shuffle(:terms) do
    AEA.Helpers.get_ets_keys_lazy(:terms_to_genes) |> Enum.to_list |> Enum.shuffle
  end

  def randomize(gs, ts, m_g, m_t) do
    shuffled_genes = gs |> Enum.shuffle
    shuffled_terms = ts |> Enum.shuffle

    genes = AEA.Helpers.get_keys_with_closest_number_of_values :genes_to_terms, m_g, shuffled_genes, 0, []
    terms = AEA.Helpers.get_keys_with_closest_number_of_values :terms_to_genes, m_t, shuffled_terms, 0, []

    {genes, terms}
  end

  def multiple_randomize(gs, ts, m_g, m_t, 0, mtilda_gts) do
      mtilda_gts
  end
  def multiple_randomize(gs, ts, m_g, m_t, n, mtilda_gts) when n > 0 do
      {g, t} = randomize(gs, ts, m_g, m_t)
      mtilda_gt = determine_m_gt(g, t)
      multiple_randomize(gs, ts, m_g, m_t, n - 1, [mtilda_gt | mtilda_gts])
  end

  def determine_m_gt(genes, terms) do
    gene_sets = terms |> get_genes_for_terms

    m_gt = Enum.reduce gene_sets, 0, fn (gene_set, acc) ->
      acc + (AEA.Helpers.intersect(gene_set, genes) |> length)
    end
  end


  def get_terms_for_genes(genes) do
    AEA.Helpers.get_values_for_keys(:genes_to_terms, genes)
  end

  def get_genes_for_terms(terms) do
    AEA.Helpers.get_values_for_keys(:terms_to_genes, terms)
  end


  def get_terms_of_branch(term) do
        case :ets.lookup(:terms_to_terms, term) do
            [{ term, terms }] ->
                [ term | terms ]
            _ ->
                IO.puts "Parsing error with #{inspect term}"

        end
  end

end
