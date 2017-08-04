defmodule AEA.Bootstrap do

  def start do
    create_table :terms_to_genes
    create_table :genes_to_terms
    create_table :genes
    create_table :terms
    create_table :terms_to_terms
    create_table :hierarchy

    :ok
  end

  def create_table(name) when is_atom(name) do
    try do
      _terms_to_genes = :ets.new(name, [:set, :protected, :named_table])
      {:ok, name}
    rescue
      _ -> {:error, "Table #{to_string name} exists."}
    end
  end


end