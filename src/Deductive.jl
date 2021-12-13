module Deductive

using Symbolics
using Symbolics: Sym, Symbolic, Term
using DataFrames, PrettyTables

export FreeVariable, LogicalSymbol, Predicate, truthtable, tableau, prove
export ¬, →, ⟶, ⟹, ←, ⟵, ↔, ⟷, ⇔, ∨, ∧
export Ē, Ā

function FreeVariable(sym::Symbol, metadata::Symbol)
    Sym{Any, Symbol}(sym, metadata)
end
function FreeVariable(sym::Symbol)
    FreeVariable(sym, :free)
end
FreeVariableType = Sym{Any}
LogicalSymbol = Sym{Bool}
SB = Union{LogicalSymbol, Term}

Predicate(sym::Symbol) = (st) -> begin
    Term{Bool}(LogicalSymbol(sym), [st]; metadata=:predicate)
end


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
function Ē(x::FreeVariableType, st::SB)
    quantified_var = Sym{Any, Symbol}(Symbolics.tosymbol(x), :quantified)
    Term(Ē, [quantified_var, substitute(st, x => quantified_var)])
end
function Ā(x::FreeVariableType, st::SB)
    quantified_var = Sym{Any, Symbol}(Symbolics.tosymbol(x), :quantified)
    Term(Ā, [quantified_var, substitute(st, x => quantified_var)])
end

function substitute_quantified(term::Term, substitution::FreeVariableType)
    term_args = arguments(term)
    substitute(term_args[2], term_args[1] => substitution)
end


# free variable unary "placeholder"
# marker for substitution with a skolem variable
_f = FreeVariable(:_f, :definitionallyfree)


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


# proof utilities
struct ProofLine
    linenum::Int
    statement::SB
    argument::String
    references::Vector{ProofLine}
end
function ProofLine(line::Int, statement::SB, argument::String="N/A")
    ProofLine(line, statement, argument, ProofLine[])
end
function ProofLine(line::Int, statement::SB, argument::String, reference::ProofLine)
    ProofLine(line, statement, argument, [reference])
end
# in most cases this shouldn't get shown since we also override Base.show(::IO, ::Vector{ProofLine})
# put another way, this is the best we can print out a proof line without context from the proof itself
function Base.show(io::IO, line::ProofLine)
    print(io, line.linenum)
    print(io, "\t")
    print(io, replace(string(line.statement), "Deductive." => ""))
    print(io, "\t")
    print(io, line.argument)
    
    if length(line.references) > 0
        print(io, "\t")
        print(io, "(" * join([string(ref.linenum) for ref ∈ line.references], ", ") * ")")
    end
end

function find_proof_line_by_statement(proof::Vector{ProofLine}, statement::SB)
    for line ∈ proof
        if isequal(line.statement, statement)
            return line
        end
    end

    nothing
end


function Base.show(io::IO, m::MIME"text/plain", proof::Vector{ProofLine})
    proof_table = DataFrame("Line Number" => Int[], "Statement" => String[], "Argument" => String[], "References" => String[])

    for line ∈ proof
        push!(proof_table, Dict(
            "Line Number" => line.linenum,
            "Statement" => replace(string(line.statement), "Deductive." => ""),
            "Argument" => line.argument,
            "References" => join([string(ref.linenum) for ref ∈ line.references], ", ")
        ))
    end

    # display_size=(-1, -1) forces pretty_table to print all rows and columns regardless of screen size
    pretty_table(io, proof_table; display_size=(-1, -1))
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


tableau(proposition::SB; kw...) = tableau([proposition]; kw...)
tableau(propositions...; kw...) = tableau([propositions...]; kw...)
function tableau(propositions::Union{Set, Vector}; skolem_vars=[], proof::Vector{ProofLine}=ProofLine[])
    if length(proof) == 0
        for proposition ∈ propositions
            push!(proof, ProofLine(length(proof) + 1, Symbolics.value(proposition), "Assumption"))
        end
    end
    simplified_propositions = Set(simplify.(propositions; rewriter=simplify_statement))

    for proposition ∈ simplified_propositions
        if isnothing(find_proof_line_by_statement(proof, proposition))
            push!(proof, ProofLine(length(proof) + 1, Symbolics.value(proposition), "Replacement Rule <TODO>"))
        end
    end

    return _tableau_simplified(simplified_propositions; skolem_vars=skolem_vars, proof=proof)
end

function _tableau_simplified(propositions::Set; skolem_vars=[], proof::Vector{ProofLine}=ProofLine[])
    # compile list of all free variables in all propositions
    free_vars = collect(Iterators.flatten([Symbolics.get_variables(p) for p ∈ propositions]))
    free_vars = filter([istree(v) ? first(arguments(v)) : v for v ∈ free_vars]) do v
        v.metadata == :free
    end

    # when a quantifier is simplified we find existing skolem variables and substitute them in for universal free variables
    function populate_skolems(term::Term, unary_operator=identity)
        placeholder_assertion = unary_operator(substitute_quantified(term, _f))
        realized_assertions = [unary_operator(substitute_quantified(term, var)) for var ∈ Iterators.flatten([skolem_vars, free_vars])]

        Set([placeholder_assertion, realized_assertions...])
    end

    # when a quantifier is simplified a new skolem variable can be created in some cases
    # this function creates a new skolem variable and substitutes it into all free variable predicates
    function create_skolem(term::Term, reduced_propositions, unary_operator=identity)
        new_skolem_var = FreeVariable(Symbol("c" * string(length(skolem_vars) + 1)), :skolem)
        new_assertion = unary_operator(substitute_quantified(term, new_skolem_var))
        realized_placeholders = [substitute(st, _f => new_skolem_var) for st ∈ reduced_propositions]

        new_skolem_var, Set([realized_placeholders..., new_assertion])
    end

    ordered_propositions = [propositions...]
    for p ∈ propositions
        pv = Symbolics.value(p)

        if !istree(pv) || pv.metadata == :predicate
            # check for contradiction
            contradiction_index = findfirst([isequal(¬p, q) for q ∈ ordered_propositions])
            if !isnothing(contradiction_index)
                contradictory_statement = ordered_propositions[contradiction_index]
                contradiction_references = [
                    find_proof_line_by_statement(proof, pv),
                    find_proof_line_by_statement(proof, contradictory_statement)
                ]

                if any(isnothing.(contradiction_references))
                    @error "Contradiction found, but one or more references is missing"
                else
                    push!(proof, ProofLine(length(proof) + 1, p ∧ contradictory_statement, "Contradiction", contradiction_references))
                end

                return false
            end
        else
            term_op = operation(pv)
            term_args = arguments(pv)
            reduced_propositions = setdiff(propositions, Set([p]))

            if length(term_args) == 2 # binary operation
                line_ref = find_proof_line_by_statement(proof, pv)

                if term_op == ∧
                    # break up term and make one recursive call

                    # add simplification to proof
                    push!(proof, ProofLine(length(proof) + 1, term_args[1], "Simplification", line_ref))
                    push!(proof, ProofLine(length(proof) + 1, term_args[2], "Simplification", line_ref))

                    if !tableau(reduced_propositions ∪ Set(term_args); skolem_vars=skolem_vars, proof=proof)
                        return false
                    end
                    break
                elseif term_op == ∨
                    # consider both arguments of term and make two recursive calls
                    
                    # case-by-case checking
                    case1_linenum, case2_linenum = length(proof) + 1, length(proof) + 2
                    push!(proof, ProofLine(case1_linenum, term_args[1], "Case 1", line_ref))
                    push!(proof, ProofLine(case2_linenum, term_args[2], "Case 2", line_ref))

                    if !tableau(reduced_propositions ∪ Set([term_args[1]]); skolem_vars=skolem_vars, proof=proof) && !tableau(reduced_propositions ∪ Set([term_args[2]]); skolem_vars=skolem_vars, proof=proof)
                        push!(proof, ProofLine(length(proof) + 1, ¬pv ∧ pv, "Contradiction", [proof[case1_linenum], proof[case2_linenum]]))

                        return false
                    end
                    break
                elseif term_op == Ā  # asserted universal quantifier
                    # create free variable
                    if !tableau(reduced_propositions ∪ populate_skolems(pv); skolem_vars=skolem_vars, proof=proof)
                        return false
                    end
                    break
                elseif term_op == Ē  # asserted existential quantifier
                    # substitute skolem variable
                    new_skolem_var, new_propositions = create_skolem(pv, reduced_propositions)
                    if !tableau(reduced_propositions ∪ new_propositions; skolem_vars=[skolem_vars..., new_skolem_var], proof=proof)
                        return false
                    end
                    break
                end
            else # unary operation (¬, logical statements)
                subterm = first(term_args)

                if istree(subterm)
                    subterm_op = operation(subterm)

                    # check for negated quantifiers
                    if subterm_op == Ā  # denied universal quantifier
                        new_skolem_var, new_propositions = create_skolem(subterm, reduced_propositions, ¬)
                        if !tableau(reduced_propositions ∪ new_propositions; skolem_vars=[skolem_vars..., new_skolem_var], proof=proof)
                            return false
                        end
                        break
                    elseif subterm_op == Ē  # denied existential quantifier
                        if !tableau(reduced_propositions ∪ populate_skolems(subterm, ¬); skolem_vars=skolem_vars, proof=proof)
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


prove(proposition::SB; kw...) = prove([proposition]; kw...)
prove(propositions...; kw...) = prove([propositions...]; kw...)
function prove(propositions::Union{Set, Vector})
    proof = ProofLine[]
    tableau(propositions; proof=proof)

    proof
end


_dict_from_combination_index(variables, index::Int) = Dict([variables[i] => Bool(index >> (i-1) & 1) for i ∈ 1:length(variables)])


end # module
