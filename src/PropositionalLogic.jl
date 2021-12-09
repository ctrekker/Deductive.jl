module PropositionalLogic

using Symbolics
using Symbolics: Sym, Symbolic, Term
using DataFrames

export LogicalSymbol, truthtable
export ¬, →, ⟶, ←, ⟵, ↔, ⟷, ∨, ∧

SB = Union{Symbolic{Bool}, Term}
LogicalSymbol = Sym{Bool}

∨(p::Bool, q::Bool) = p || q
∨(p::SB, q::SB) = Term(∨, [p, q])
∧(p::Bool, q::Bool) = p && q
∧(p::SB, q::SB) = Term(∧, [p, q])

¬(x::Bool) = !x
¬(x::SB) = Term(¬, [x])

→(p::Bool, q::Bool) = ¬p ∨ q  # material implication
→(p::SB, q::SB) = Term(→, [p, q])
⟶ = →

←(p::Bool, q::Bool) = p ∨ ¬q  # material implication
←(p::SB, q::SB) = Term(←, [p, q])
⟵ = ←

⟷(p::Bool, q::Bool) = (p ∧ q) ∨ (¬p ∧ ¬q)  # material implication
⟷(p::SB, q::SB) = Term(⟷, [p, q])
↔ = ⟷


function truthtable(st::Term)
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

_dict_from_combination_index(variables, index::Int) = Dict([variables[i] => Bool(index >> (i-1) & 1) for i ∈ 1:length(variables)])


end # module
