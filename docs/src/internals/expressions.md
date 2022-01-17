# Expressions

Fundamentally software attempting to both define and prove theorems requires an extensive set of utilities surrounding the function of manipulating expressions. The lowest level of abstraction of expressions in this package is `AbstractExpression`, from which all expression types inherit from. Anything from symbols to sets are expressions, and a good rule for determining whether something is an expression or not is if it would make mathematical sense to write such an expression down as either a statement or a mathematical object. Logical operations are not expressions since on their own they carry no meaning without arguments.

## Logical Symbols

```@docs
LogicalSymbol
@symbols
name(::LogicalSymbol)
metadata(::LogicalSymbol)
```
