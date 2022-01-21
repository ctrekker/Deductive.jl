# Assertion Proofs

Assertion proofs are a kind of proof structured in a manner where one starts with a set of statements they would like to prove in terms of another set of statements. Deductive makes this distinction so that a given-goal structure can be defined which describes such a system. 

## Given Goal Proofs

Given-goal systems are useful for a number of reasons, such as allowing for clear meta-transformations like a contradictory or contrapositive system, better reflecting the underlying form which mathematical proofs usually fall under, and cutting down on search algorithm costs by utilizing inference rules as a means of statement transformation instead of replacement rules, which can be applied recursively to an expression tree rather than just the "top".

```@docs
GivenGoal
given
goal
```

## Matching Algorithms

The given-goal proof definition requires one to apply inference rules repeatedly. These inference rules take the form of a set of expressions which, when matched to a subset of the statements in a given section of a proof, the [`conclusion`](@ref) part of the inference rule becomes the logical consequence of that subset of given statements.

```@docs
rule_matches
rule_combinations
is_partner_map
has_partner_map
```
