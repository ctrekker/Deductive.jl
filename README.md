# Deductive.jl
Simple package for expressing and proving [zeroth order](https://en.wikipedia.org/wiki/Propositional_calculus) and [first order](https://en.wikipedia.org/wiki/First-order_logic) logical statements and theorems symbolically in Julia

## Installation
Currently this package is unregistered in Julia's general registry. Instead install through this repository directly.
```julia-repl
(@v1.7) pkg> add https://github.com/ctrekker/PropositionalLogic.jl
```

## Getting Started
### Propositional Logic (zeroth order)
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

### Predicate Logic (first order)
With predicates, statements like "for all x, P(x) is true" can be written. Due to some Julia parser issues, defining a function with the symbols for universal (∀) and existential (∃) quantification isn't possible. Instead we settle for the symbols Ā (typed A\bar) and Ē (typed (E\bar)). Here's an example of their use:

```julia
using Deductive

x = FreeVariable(:x)
P = Proposition(:P)

Ā(x, P(x))  # like saying "for all x, P(x) is true"
Ē(x, P(x))  # like saying "for some x, P(x) is true"
¬Ē(x, ¬P(x))  # like saying "there does not exist x such that P(x) is false", which is equivalent to Ā(x, P(x))
```

As an interesting example, the equivalence between Ā(x, P(x)) and ¬Ē(x, ¬P(x)) can be proven as a tautology within this package using the `prove` function. This logical equivalence can be expressed as a statement Ā(x, P(x)) ⟷ ¬Ē(x, ¬P(x)), or "for all x, P(x) is true if and only if there does not exist any x such that P(x) is false".

```julia
using Deductive

x = FreeVariable(:x)
P = Proposition(:P)

my_statement = Ā(x, P(x)) ⟷ ¬(Ē(x, ¬P(x)))
# prove by contradiction
prove(¬my_statement)  # returns false, since the contradiction of a tautology is always false
```
