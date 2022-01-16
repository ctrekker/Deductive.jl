# Propositional Logic

```julia
using Deductive

@symbols a b

tableau(a ∧ b)      # true
tableau(a ∧ b, ¬a)  # false, because contradiction

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
