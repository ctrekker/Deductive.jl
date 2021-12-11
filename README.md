# Deductive.jl
Simple package for expressing and proving [zeroth order](https://en.wikipedia.org/wiki/Propositional_calculus) and [first order](https://en.wikipedia.org/wiki/First-order_logic) logical statements and theorems symbolically in Julia

## Installation
Currently this package is unregistered in Julia's general registry. Instead install through this repository directly.
```julia-repl
(@v1.7) pkg> add https://github.com/ctrekker/PropositionalLogic.jl
```

## Getting Started
```julia
using Deductive
a, b = LogicalSymbol.([:a, :b])

prove(a ∧ b)      # true
prove(a ∧ b, ¬a)  # false, because contradiction

println(truthtable(a ∧ b))
#= Outputs:
 Row │ a      b      a ∧ b 
     │ Bool   Bool   Bool  
─────┼─────────────────────
   1 │ false  false  false
   2 │  true  false  false
   3 │ false   true  false
   4 │  true   true   true
=#
```

Several operators are exported and their use is required in defining statements.

| Symbol | Completion Sequence | Description                                                                |
|--------|---------------------|----------------------------------------------------------------------------|
| ¬      | \neg                | [Negation](https://en.wikipedia.org/wiki/Negation)                         |
| ∧      | \wedge              | [Logical Conjunction](https://en.wikipedia.org/wiki/Logical_conjunction)   |
| ∨      | \vee                | [Logical Disjunction](https://en.wikipedia.org/wiki/Logical_disjunction)   |
| →      | \rightarrow         | [Material Implication](https://en.wikipedia.org/wiki/Material_conditional) |
| ⟷      | \leftrightarrow     | [Material Equivalence](https://en.wikipedia.org/wiki/If_and_only_if)       |
