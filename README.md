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

### **OUTDATED** Predicate Logic (first order)
With predicates, statements like "for all x, P(x) is true" can be written. Due to some Julia parser issues, defining a function with the symbols for universal (∀) and existential (∃) quantification isn't possible. Instead we settle for the symbols Ā (typed A\bar) and Ē (typed (E\bar)). Here's an example of their use:

```julia
using Deductive

x = FreeVariable(:x)
P = Proposition(:P)

Ā(x, P(x))  # like saying "for all x, P(x) is true"
Ē(x, P(x))  # like saying "for some x, P(x) is true"
¬Ē(x, ¬P(x))  # like saying "there does not exist x such that P(x) is false", which is equivalent to Ā(x, P(x))
```

As an interesting example, the equivalence between Ā(x, P(x)) and ¬Ē(x, ¬P(x)) can be proven as a tautology within this package using the `tableau` function. This logical equivalence can be expressed as a statement Ā(x, P(x)) ⟷ ¬Ē(x, ¬P(x)), or "for all x, P(x) is true if and only if there does not exist any x such that P(x) is false".

```julia
using Deductive

x = FreeVariable(:x)
P = Proposition(:P)

my_statement = Ā(x, P(x)) ⟷ ¬(Ē(x, ¬P(x)))
# prove by contradiction
tableau(¬my_statement)  # returns false, since the contradiction of a tautology is always false
```

### Generating Human-Readable Proofs (WIP)
The method of analytic tableaux is a complete method for proving zeroth and first order logic problems. To export these proofs in human-readable form the `prove` function is exported. Instead of simply yielding a `true` or `false`, this function will return a full proof containing the steps taken to determine whether a set of propositions are consistent.

```julia
using Deductive

a, b, c, d = LogicalSymbol.([:a, :b, :c, :d])

# basic example from above
prove(a ∧ b, ¬a)
#= Output:
┌─────────────┬───────────┬────────────────┬────────────┐
│ Line Number │ Statement │       Argument │ References │
│       Int64 │    String │         String │     String │
├─────────────┼───────────┼────────────────┼────────────┤
│           1 │     a ∧ b │     Assumption │            │
│           2 │      ¬(a) │     Assumption │            │
│           3 │         a │ Simplification │          1 │
│           4 │         b │ Simplification │          1 │
│           5 │  a ∧ ¬(a) │  Contradiction │       3, 2 │
└─────────────┴───────────┴────────────────┴────────────┘
=#

# a far more fun example :)
prove(a → b, b → c, c → d, a, ¬d)
#= Output:
┌─────────────┬──────────────────────────┬─────────────────────────┬────────────┐
│ Line Number │                Statement │                Argument │ References │
│       Int64 │                   String │                  String │     String │
├─────────────┼──────────────────────────┼─────────────────────────┼────────────┤
│           1 │                    a → b │              Assumption │            │
│           2 │                    b → c │              Assumption │            │
│           3 │                    c → d │              Assumption │            │
│           4 │                        a │              Assumption │            │
│           5 │                     ¬(d) │              Assumption │            │
│           6 │                 ¬(c) ∨ d │ Replacement Rule <TODO> │            │
│           7 │                 ¬(a) ∨ b │ Replacement Rule <TODO> │            │
│           8 │                 ¬(b) ∨ c │ Replacement Rule <TODO> │            │
│           9 │                     ¬(c) │                  Case 1 │          6 │
│          10 │                        d │                  Case 2 │          6 │
│          11 │                     ¬(a) │                  Case 1 │          7 │
│          12 │                        b │                  Case 2 │          7 │
│          13 │                 a ∧ ¬(a) │           Contradiction │      4, 11 │
│          14 │                     ¬(b) │                  Case 1 │          8 │
│          15 │                        c │                  Case 2 │          8 │
│          16 │                 b ∧ ¬(b) │           Contradiction │     12, 14 │
│          17 │                 c ∧ ¬(c) │           Contradiction │      15, 9 │
│          18 │ ¬(¬(b) ∨ c) ∧ (¬(b) ∨ c) │           Contradiction │     14, 15 │
│          19 │ ¬(¬(a) ∨ b) ∧ (¬(a) ∨ b) │           Contradiction │     11, 12 │
│          20 │                 d ∧ ¬(d) │           Contradiction │      10, 5 │
│          21 │ ¬(¬(c) ∨ d) ∧ (¬(c) ∨ d) │           Contradiction │      9, 10 │
└─────────────┴──────────────────────────┴─────────────────────────┴────────────┘
=#
```

As is clear from the second example, several arguments are missing regarding replacement rules, and the organization is rather poor. This feature is very much work in progress right now.
