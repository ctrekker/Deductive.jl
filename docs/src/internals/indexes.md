# Indexes

In Deductive an interface for defining indexes on tables is defined. This redefinition is necessary since the form of index is often
different (although similar) to the classic balancing binary tree structure which most indexes employ.

```@docs
Deductive.index
```

## Index Structure

This structure provides the interface from which all indexes will use. The parametric type `E` describes the element type which
is being indexed, and the type `T` describes the type of table which the index is using.

```@docs
Deductive.Index
Deductive.add!(idx::Deductive.Index{E, T}, el::E) where {E, T}
Deductive.search(idx::Deductive.Index{E, T}, pattern::E) where {E, T}
```

## Expression Indexing

Expression indexing allows for very quick pattern matching across very large sets of expressions simultaneously. Indexing doesn't
improve the pattern match speed of a single pattern, but drastically decreases pattern match speed of multiple indexed expressions
by leveraging similarities in structure across different indexed expressions.

```@docs
Deductive.OperatorIndexTable
Deductive.roots
Deductive.operators
Deductive.add!(table::Deductive.OperatorIndexTable, entry::Tuple{Int, LogicalSymbol})
Deductive.add!(table::Deductive.OperatorIndexTable, entry::Tuple{Int, LogicalExpression})
Deductive.search(table::Deductive.OperatorIndexTable, sym::LogicalSymbol)
Deductive.search(table::Deductive.OperatorIndexTable, operator_pattern::LogicalExpression)
```
