defmodule AEA do

  import AEA.Helpers


  def bootstrap() do
    {terms_to_genes, genes_to_terms, terms, genes} = AEA.GMT.start_from_cache
    terms_to_terms = AEA.Hierarchy.start_from_cache

    terms_to_genes |> map_to_table |> table_to_ets(:terms_to_genes)
    genes_to_terms |> map_to_table |> table_to_ets(:genes_to_terms)
    terms_to_terms |> map_to_table |> table_to_ets(:terms_to_terms)
    terms |> list_to_ets(:terms)
    genes |> list_to_ets(:genes)

    {genes, terms}

  end

  def prepare() do
#    p = ((Enum.filter mtilda_gts, fn(mtilda_gt) -> mtilda_gt >= m_gt  end) |> length) / length(mtilda_gts)
#
#    {m_gt, mtilda_gts, p}
  end

  def calculate_aea(all_genes, all_terms, gene_set) do
      Enum.each all_terms, fn(term) ->
          {:ok, pid} = AEA.Determine.start_link
          AEA.Determine.go(pid, all_genes, all_terms, gene_set, term, 2)
      end
  end

  def calculate_aea_a(all_genes, all_terms, gene_set, term) do
    m_tot = AEA.Determine.determine_m_tot all_genes, all_terms

    {m_gt, m_g, m_t} = AEA.Determine.determine_ms gene_set, term

    Enum.reduce m_gt..min(m_g, m_t), 0, fn(i, acc) ->
        acc + AEA.Math.choose(m_t, i) * AEA.Math.choose(m_tot - m_t, m_g - i) / AEA.Math.choose(m_tot, m_g)
    end
  end


end
