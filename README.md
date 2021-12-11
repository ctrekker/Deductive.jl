# PropositionalLogic.jl
Simple package for expressing and proving logical statements symbolically in Julia

## Installation
Currently this package is unregistered in Julia's general registry. Instead install through this repository directly.
```julia-repl
(@v1.7) pkg> add https://github.com/ctrekker/PropositionalLogic.jl
```

## Getting Started
Several operators are exported and their use is required in defining statements.

| Symbol | Completion Sequence | Description                                                                |
|--------|---------------------|----------------------------------------------------------------------------|
| ¬      | \neg                | [Negation](https://en.wikipedia.org/wiki/Negation)                         |
| ∧      | \wedge              | [Logical Conjunction](https://en.wikipedia.org/wiki/Logical_conjunction)   |
| ∨      | \vee                | [Logical Disjunction](https://en.wikipedia.org/wiki/Logical_disjunction)   |
| →      | \rightarrow         | [Material Implication](https://en.wikipedia.org/wiki/Material_conditional) |
| ↔      | \leftrightarrow     | [Material Equivalence](https://en.wikipedia.org/wiki/If_and_only_if)       |
