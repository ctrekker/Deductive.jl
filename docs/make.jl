push!(LOAD_PATH,"../src/")

using Documenter, Deductive

makedocs(
    sitename="Deductive Documentation",
    modules = [Deductive],
    pages = [
        "index.md",
        "Propositional Logic" => "propositional_logic.md",
        "Internals" => [
            "Expressions" => "internals/expressions.md",
        ]
    ]
)

deploydocs(
    repo = "github.com/ctrekker/Deductive.jl.git",
)
