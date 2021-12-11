module Deductive

using Symbolics
using Symbolics: Sym, Symbolic, Term
using DataFrames

export LogicalSymbol, truthtable, prove
export ¬, →, ⟶, ⟹, ←, ⟵, ↔, ⟷, ⇔, ∨, ∧
export Ē, Ā

LogicalSymbol = Sym{Bool}
SB = Union{LogicalSymbol, Term}

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
Ē(x::SB) = Term(Ē, [x])
Ā(x::SB) = Term(Ā, [x])


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
function prove(propositions::Union{Set, Vector})
    simplified_propositions = Set(simplify.(propositions; rewriter=simplify_statement))
    return _prove_simplified(simplified_propositions)
end

function _prove_simplified(propositions::Set)
    for p ∈ propositions
        pv = Symbolics.value(p)

        if !istree(pv)
            # check for negation (contradiction)
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
                    if !prove(reduced_propositions ∪ Set(term_args))
                        return false
                    end
                elseif term_op == ∨
                    # consider both arguments of term and make two recursive calls
                    if !prove(reduced_propositions ∪ Set([term_args[1]])) && !prove(reduced_propositions ∪ Set([term_args[2]]))
                        return false
                    end
                end
            else # unary operation (¬)
                term_arg = first(term_args)
                # if the argument is a term, throw an error. this should never happen since it was removed beforehand
                if istree(term_arg)
                    throw(ErrorException("Improperly expanded predicate!"))
                end
            end
        end
    end
    
    return true
end

_dict_from_combination_index(variables, index::Int) = Dict([variables[i] => Bool(index >> (i-1) & 1) for i ∈ 1:length(variables)])


end # module
