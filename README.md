# AEA

Elixir implementation of the Annotation Enrichment Analysis proposed by Kimberly Glass, Michelle Girvan in [Annotation Enrichment Analysis: An Alternative Method for Evaluating the Functional Properties of Gene Sets](https://www.nature.com/articles/srep04191)

# Running
Install dependencies:
```
$ mix deps.get
```

Start IEX session:
```
$ iex -S mix
```

In the IEX session build ETS (this step requires the following files in the `cache` directory:
* genes_to_terms.csv
* terms_to_genes.csv
* terms_to_term.csv
* terms_to_progeny.csv
```
iex(1)> AEA.bootstrap
```

Run computational method:
```
iex(2)> {:ok, pid} = AEA.Computational.start_link
iex(3)> AEA.Computational.go pid, ["ENSG00000154654", "ENSG00000140807", "ENSG00000111666", "ENSG00000168556"]
```

Or analytical one:
```
iex(2)> {:ok, pid} = AEA.Analytical.start_link
iex(3)> AEA.Analytical.go pid, ["ENSG00000154654", "ENSG00000140807", "ENSG00000111666", "ENSG00000168556"]
```