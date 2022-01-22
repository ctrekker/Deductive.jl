push!(LOAD_PATH, "../src/")

using Documenter, Deductive

makedocs(
    sitename="Deductive Documentation",
    modules = [Deductive],
    pages = [
        "index.md",
        "Propositional Logic" => "propositional_logic.md",
        "Internals" => [
            "Expressions" => "internals/expressions.md",
            "Proof Utilities" => "internals/proof_utilities.md",
            "Assertion Proofs" => "internals/assertion_proofs.md",
            "Indexes" => "internals/indexes.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/ctrekker/Deductive.jl.git",
)
