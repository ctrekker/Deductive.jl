# proof strategies:
#  direct
#  implication
#  contradiction

# "formalized" with given / goal table

export GivenGoal, given, goal, rule_matches, rule_combinations


"""
    GivenGoal(given::Set{AbstractExpression}, goal::Set{AbstractExpression})

Initialize a structure representing a proof starting and ending point, with given and goal sets of expressions respectively. This
structure on its own isn't enough to conduct a proof, however. A proof requires both a `GivenGoal` and a logical calculus which
defines the allowed elementary operations on expressions. For example, if operating within propositional logic, see the 
PropositionalCalculus definition.
"""
struct GivenGoal
    given::Set{AbstractExpression}
    goal::Set{AbstractExpression}
end
GivenGoal(given::Vector{T}, goal::Vector{U}) where {T <: AbstractExpression, U <: AbstractExpression} = GivenGoal(Set(Vector{AbstractExpression}(given)), Set(Vector{AbstractExpression}(goal)))
given(gg::GivenGoal) = gg.given
goal(gg::GivenGoal) = gg.goal

function find_matches(gg::GivenGoal, rule::InferenceRule)
    matching_statements = Dict{AbstractExpression, Vector{AbstractExpression}}()

    for premise ∈ premises(rule)
        matching_statements[premise] = AbstractExpression[]

        for st ∈ given(gg)
            if matches(st, premise)
                push!(matching_statements[premise], st)
            end
        end
    end

    matching_statements
end


SymbolMap = Dict{LogicalSymbol, AbstractExpression}
function is_partner(sym_map::SymbolMap, compare_sym_map::SymbolMap)
    all([!haskey(compare_sym_map, sym) || compare_sym_map[sym] == mapped for (sym, mapped) ∈ sym_map])
end
function has_partner(sym_map::SymbolMap, compare_sym_map_set::Set{SymbolMap})
    any([is_partner(sym_map, compare_sym_map) for compare_sym_map ∈ compare_sym_map_set])
end


"""
    rule_matches(ir::InferenceRule, haystack::Set{T}) where {T <: AbstractExpression}

Computes a vector of matches in which each element is a valid set of possible symbol values, with the catch being that
any two sets drawn from different elements of the output vector may or may not be compatible. It is not recommended that
this function be used externally. Instead, see [rule_combinations](@ref), which outputs a more usable form of rule match,
which instead enumerates over all possible matches. Although informationally identical, [rule_combinations](@ref) is
usually preferable due to its linearly iterable ouptut.
"""
function rule_matches(ir::InferenceRule, haystack::Set{T}) where {T <: AbstractExpression}
    smatches = set_matches(premises(ir), haystack; strict=false)
    sym_matches = Dict(st => Set{Dict{LogicalSymbol, AbstractExpression}}() for st ∈ keys(smatches))


    # cache rule matches
    for (st, match_set) ∈ smatches
         sym_matches[st] = Set(find_matches(match, st) for match ∈ match_set)
    end


    symbol_maps = collect(values(sym_matches))
    
    reduced_symbol_maps = [
        begin
            symbol_maps_without_current = filter(x->x!=symbol_map_set, symbol_maps)
            filter(symbol_map_set) do symbol_map
                all([has_partner(symbol_map, compare_symbol_map_set) for compare_symbol_map_set ∈ symbol_maps_without_current])
            end
        end
        for symbol_map_set ∈ symbol_maps
    ]
end

"""
    rule_combinations(rule_variables::Set{LogicalSymbol}, reduced_symbol_maps::Vector{Set{SymbolMap}}, current_symbol_map=SymbolMap())

Given a set of variables which all valid combinations must map to and a list of symbol map sets, compute the set of valid
combinations of these symbol maps. In most cases this signature should be avoided in favor of the rule_combinations implementation
which directly takes an inference rule and set of expressions.
"""
function rule_combinations(rule_variables::Set{LogicalSymbol}, reduced_symbol_maps::Vector{Set{SymbolMap}}, current_symbol_map=SymbolMap())
    if length(keys(current_symbol_map)) == length(rule_variables)
        return Set{SymbolMap}([current_symbol_map])
    end

    symbol_maps = first(reduced_symbol_maps)
    combinations = Set{SymbolMap}()

    for symbol_map ∈ symbol_maps
        if length(keys(symbol_map)) == length(rule_variables)
            push!(combinations, symbol_map)
        elseif is_partner(symbol_map, current_symbol_map)
            rc = rule_combinations(rule_variables, reduced_symbol_maps[2:end], merge(symbol_map, current_symbol_map))
            union!(combinations, rc)
        end
    end

    return combinations
end

"""
    rule_combinations(ir::InferenceRule, haystack::Set{T}) where {T <: AbstractExpression}

Find all valid symbol substitutions which can be performed on a set of statements by an inference rule.

## Examples

The following code demonstrates that modus ponens can be applied on this set of statements by taking a → b to be true
and uses this to imply c. Since the rule for modus ponens is stated with the inference rule (p, p → q) ⊢ q, the 
variable substitutions corresponding to the logic above would be `p => a → b` and `q => c`.
```julia
@symbols a b c
modus_ponens = rule_by_name(PropositionalCalculus, "Modus Ponens")
my_premises = Set{AbstractExpression}([
    a → b,
    (a → b) → c
])

rule_combinations(modus_ponens, my_premises)
#= Results in:
Set with 1 element:
  Dict(q => c, p => a → b)
=#
```

Similarly we inspect an example where multiple possible variable substitutions exist. The rule for double negation introduction
is defined as p ⊢ ¬¬p, which can apply universally to all statements in a set of premises.

```julia
@symbols a b
double_negation = rule_by_name(PropositionalCalculus, "Double Negation Introduction")
my_premises = Set{AbstractExpression}([
    a,
    b,
    a ∧ b
])

rule_combinations(double_negation, my_premises)
#= Results in:
Set with 3 elements:
  Dict(p => a ∧ b)
  Dict(p => a)
  Dict(p => b)
```
"""
function rule_combinations(ir::InferenceRule, haystack::Set{T}) where {T <: AbstractExpression}
    rule_combinations(variables(premises(ir)), rule_matches(ir, haystack))
end

"""
    prove(gg::GivenGoal; calculus=PropositionalCalculus)

Prove a given-goal table using the specified logical calculus, which by default is [PropositionalCalculus](@ref).
"""
function prove(gg::GivenGoal; calculus=PropositionalCalculus)
    # naive iteration
    for rule ∈ calculus
        println(premises(rule) => conclusion(rule))
    end
end
