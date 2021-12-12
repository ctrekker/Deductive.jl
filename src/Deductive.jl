module Deductive

using Symbolics
using Symbolics: Sym, Symbolic, Term
using DataFrames

export FreeVariable, LogicalSymbol, Predicate, truthtable, prove
export ¬, →, ⟶, ⟹, ←, ⟵, ↔, ⟷, ⇔, ∨, ∧
export Ē, Ā

FreeVariable = Sym{Any}
LogicalSymbol = Sym{Bool}
SB = Union{LogicalSymbol, Term}

Predicate(sym::Symbol) = (st) -> Term{Bool}(LogicalSymbol(sym), [st]; metadata=:predicate)


∨(p::Bool, q::Bool) = p || q
∨(p::SB, q::SB) = Term(∨, [p, q])
∧(p::Bool, q::Bool) = p && q
∧(p::SB, q::SB) = Term(∧, [p, q])

¬(x::Bool) = !x
¬(x::SB) = Term(¬, [x])

→(p::Bool, q::Bool) = ¬p ∨ q  # material implication
→(p::SB, q::SB) = Term(→, [p, q])
⟶ = ⟹ = →

←(p::Bool, q::Bool) = p ∨ ¬q  # material implication
←(p::SB, q::SB) = Term(←, [p, q])
⟵ = ←

⟷(p::Bool, q::Bool) = (p ∧ q) ∨ (¬p ∧ ¬q)  # material implication
⟷(p::SB, q::SB) = Term(⟷, [p, q])
↔ = ⇔ = ⟷


# quantifiers
Ē(x::FreeVariable, st::SB) = Term(Ē, [x, st])
Ā(x::FreeVariable, st::SB) = Term(Ā, [x, st])

# free variable unary "placeholder"
# marker for substitution with a skolem variable
_f = FreeVariable(:_f)


function truthtable(st::SB)
    variables = Symbolics.get_variables(st)
    combinations = 2 ^ length(variables)
    st_sym = Symbol(string(st))
    table = DataFrame(Dict(Symbol(var) => Bool[] for var ∈ variables)..., Dict(st_sym => Bool[])...)

    for i ∈ 0:(combinations-1)
        variable_values = _dict_from_combination_index(variables, i)
        result = substitute(st, variable_values)
        push!(table, merge(Dict(Symbol(k) => v for (k, v) ∈ variable_values), Dict(st_sym => result)))
    end

    table
end


demorgan_and = @rule ¬(~p ∧ ~q) => ¬~p ∨ ¬~q
demorgan_or = @rule ¬(~p ∨ ~q) => ¬~p ∧ ¬~q
double_negative = @rule ¬¬~p => ~p
material_implication = @rule ~p → ~q => ¬~p ∨ ~q
reverse_material_implication = @rule ~p ← ~q => ~p ∨ ¬~q
negated_material_implication = @rule ¬(~p → ~q) => ~p ∧ ¬~q
negated_reverse_material_implication = @rule ¬(~p ← ~q) => ¬~p ∧ ~q
material_equivalence = @rule ~p ⟷ ~q => (~p ∧ ~q) ∨ (¬~p ∧ ¬~q)
negated_material_equivalence = @rule ¬(~p ⟷ ~q) => (~p ∧ ¬~q) ∨ (¬~p ∧ ~q)

# These rules require some extra things, such as substitution by skolem constants after rule application
deny_universal =     @rule ¬Ā(~x, ~y) => ¬~y
assert_existential = @rule  Ē(~x, ~y) =>  ~y
assert_universal =   @rule  Ā(~x, ~y) =>  ~y
deny_existential =   @rule ¬Ē(~x, ~y) => ¬~y

simplify_statement = Symbolics.RestartedChain([
    demorgan_and,
    demorgan_or,
    double_negative,
    material_implication,
    reverse_material_implication,
    negated_material_implication,
    negated_reverse_material_implication,
    material_equivalence,
    negated_material_equivalence
])

prove(proposition::SB) = prove([proposition])
prove(propositions...) = prove([propositions...])
function prove(propositions::Union{Set, Vector}; skolem_vars=[])
    simplified_propositions = Set(simplify.(propositions; rewriter=simplify_statement))
    return _prove_simplified(simplified_propositions; skolem_vars=skolem_vars)
end

function _prove_simplified(propositions::Set; skolem_vars=[])
    for p ∈ propositions
        pv = Symbolics.value(p)

        if !istree(pv) || pv.metadata == :predicate
            # check for contradiction
            if any([isequal(¬p, q) for q ∈ propositions])
                return false
            end
        else
            term_op = operation(pv)
            term_args = arguments(pv)
            reduced_propositions = setdiff(propositions, Set([p]))
            if length(term_args) == 2 # binary operation
                if term_op == ∧
                    # break up term and make one recursive call
                    if !prove(reduced_propositions ∪ Set(term_args); skolem_vars=skolem_vars)
                        return false
                    end
                    break
                elseif term_op == ∨
                    # consider both arguments of term and make two recursive calls
                    if !prove(reduced_propositions ∪ Set([term_args[1]]); skolem_vars=skolem_vars) && !prove(reduced_propositions ∪ Set([term_args[2]]); skolem_vars=skolem_vars)
                        return false
                    end
                    break
                elseif term_op == Ā  # universal quantifier
                    placeholder_assertion = substitute(term_args[2], term_args[1] => _f)
                    realized_assertions = [substitute(term_args[2], term_args[1] => skolem_var) for skolem_var ∈ skolem_vars]
                    if !prove(reduced_propositions ∪ Set([placeholder_assertion, realized_assertions...]))
                        return false
                    end
                    break
                elseif term_op == Ē  # existential quantifier
                    new_skolem_var = FreeVariable(Symbol("c" * string(length(skolem_vars) + 1)))
                    new_assertion = substitute(term_args[2], term_args[1] => new_skolem_var)
                    realized_placeholders = [substitute(st, _f => new_skolem_var) for st ∈ reduced_propositions]
                    if !prove(reduced_propositions ∪ realized_placeholders ∪ Set([new_assertion]); skolem_vars=[skolem_vars..., new_skolem_var])
                        return false
                    end
                    break
                end
            else # unary operation (¬, logical statements)
                subterm = first(term_args)

                if subterm isa Term
                    subterm_op = operation(subterm)
                    subterm_args = arguments(subterm)

                    # check for negated quantifiers
                    if subterm_op == Ā  # denied universal quantifier
                        new_skolem_var = FreeVariable(Symbol("c" * string(length(skolem_vars) + 1)))
                        new_assertion = ¬substitute(subterm_args[2], subterm_args[1] => new_skolem_var)
                        realized_placeholders = [substitute(st, _f => new_skolem_var) for st ∈ reduced_propositions]
                        if !prove(reduced_propositions ∪ realized_placeholders ∪ Set([new_assertion]); skolem_vars=[skolem_vars..., new_skolem_var])
                            return false
                        end
                        break
                    elseif subterm_op == Ē  # denied existential quantifier
                        placeholder_assertion = ¬substitute(term_args[2], term_args[1] => _f)
                        realized_assertions = [¬substitute(term_args[2], term_args[1] => skolem_var) for skolem_var ∈ skolem_vars]
                        if !prove(reduced_propositions ∪ Set([placeholder_assertion, realized_assertions...]))
                            return false
                        end
                        break
                    end
                end
            end
        end
    end
    
    return true
end

_dict_from_combination_index(variables, index::Int) = Dict([variables[i] => Bool(index >> (i-1) & 1) for i ∈ 1:length(variables)])


end # module
