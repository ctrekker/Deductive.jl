export @logical_calculus, InferenceRule, PropositionalCalculus, ⊢

# TODO: implement set theoretic abstractions so a proper representation of the "universe of discourse" can be explicitly
#       defined in certain rules of inference (like the Principle of Explosion)

# the reason for this redeclaration is because a custom implementation of AbstractSet
# will be necessary for StatementSet to perform certain optimizations
Statement = AbstractExpression
StatementSet = Set{Statement}

"""
    InferenceRule(name::String, premise::StatementSet, conclusion::Statement)

Define a rule which maps a set of statements to a logical conclusion. The name is cited each time
a rule is applied in a proof step.
"""
struct InferenceRule
    name::String
    premise::StatementSet
    conclusion::Statement
end

InferenceRule(name::String, premise::Tuple{Vararg{T} where T}, conclusion::Statement) = InferenceRule(name, StatementSet(premise), conclusion)
InferenceRule(name::String, premise::T, conclusion::Statement) where {T <: Statement} = InferenceRule(name, (premise,), conclusion)


_leaf_symbols(::Symbol) = Set{Symbol}()
function _leaf_symbols(expr::Expr)
    args = expr.args[2:end]
    if all((x -> x isa Symbol).(args))
        return Set{Symbol}(args)
    end

    Set(Iterators.flatten(_leaf_symbols.(args)))
end

"""
Defines a logical calculus based on a set of inference rules which can be applied repeatedly to
a given set of statements (premises). See `PropositionalCalculus` for an example definition using
this macro.
"""
macro logical_calculus(var, defs)
    rules_list = defs.args[2].args

    if length(rules_list) % 3 != 0
        throw(ErrorException("Each inference rule requires a name, premises, and a conclusion"))
    end

    variables_list = Set{Symbol}()
    inference_expressions = Expr[]

    for i ∈ 1:3:length(rules_list)
        push!(inference_expressions, :(
            InferenceRule($(rules_list[i]), $(esc(rules_list[i+1])), $(esc(rules_list[i+2])))
        ))
        union!(variables_list, _leaf_symbols(rules_list[i+1]))
        union!(variables_list, _leaf_symbols(rules_list[i+2]))
    end

    variable_declarations = [:(
        $(esc(var_name)) = LogicalSymbol($(esc(Symbol))($(string(var_name))))
    ) for var_name ∈ variables_list]

    quote
        $(variable_declarations...)
        $(esc(var)) = Set{InferenceRule}(
            [$(inference_expressions...)]
        )
    end
end


"""
    A ⊢ B

Provability operator used exclusively in calculus definitions. A ⊢ B means that B can be proven using A as the premise.
"""
⊢ = LogicalOperation((a, b) -> true, :⊢, 2, false, false)

"""
    PropositionalCalculus

Default calculus definition for zeroth-order (propositional) logic.
"""
@logical_calculus PropositionalCalculus begin
    "Modus Ponens", (
        p → q,
        p
    ), q,
    "Modus Tollens", (
        p → q,
        ¬q
    ), ¬p,
    "Associative Conjunction", (
        (p ∧ q) ∧ r
    ), p ∧ (q ∧ r),
    "Associative Disjunction", (
        (p ∨ q) ∨ r
    ), p ∨ (q ∨ r),
    "Commutative Conjunction", (
        p ∧ q
    ), q ∧ p,
    "Commutative Disjunction", (
        p ∨ q
    ), q ∨ p,
    "Law of Biconditional Propositions", (
        p → q,
        q → p
    ), p ⟷ q,
    "Exportation", (
        (p ∧ q) → r
    ), p → (q → r),
    "Transposition", (
        p → q
    ), ¬q → ¬p,
    "Hypothetical Syllogism", (
        p → q,
        q → r
    ), p → r,
    "Material Implication", (
        p → q
    ), ¬p ∨ q,
    "Distributive Conjunction", (
        (p ∨ q) ∧ r
    ), (p ∧ r) ∨ (q ∧ r),
    "Distributive Disjunction", (
        (p ∧ q) ∨ r
    ), (p ∨ r) ∧ (q ∨ r),
    "Absorption", (
        p → q
    ), p → (p ∧ q),
    "Disjunctive Syllogism", (
        p ∨ q,
        ¬p
    ), q,
    "Addition", (
        p
    ), p ∨ q,
    "Simplification", (
        p ∧ q
    ), p,
    "Conjunction", (
        p,
        q
    ), p ∧ q,
    "Double Negation Introduction", (
        p
    ), ¬¬p,
    "Double Negation Elimination", (
        ¬¬p
    ), p,
    "Disjunctive Simplification", (
        p ∨ p
    ), p,
    "Resolution", (
        p ∨ q,
        ¬p ∨ r
    ), q ∨ r,
    "Disjunction Elimination", (
        p → q,
        r → q,
        p ∨ r
    ), q
end

@logical_calculus ExtendedPropositionalCalculus begin
    # Rules for negations
    "Negation Introduction", (
        ϕ ⊢ ψ,
        ϕ ⊢ ¬ψ
    ), ¬ϕ,
    "Negation Elimination", (
        ¬ϕ ⊢ ψ,
        ¬ϕ ⊢ ¬ψ
    ), ϕ,
    "Principle of Explosion", (
        ϕ,
       ¬ϕ,
    ),  ψ,
    "Double Negation Elimination", (
        ¬¬ϕ
    ), ϕ,
    "Double Negation Introduction", (
        ϕ
    ), ¬¬ϕ,
    
    # Rules for conditionals
    "Deduction Theorem", (
        ϕ ⊢ ψ
    ), ϕ → ψ,
    "Modus Ponens", (
        ϕ → ψ,
        ϕ
    ), ψ,
    "Modus Tollens", (
        ϕ → ψ,
        ¬ψ
    ), ¬ϕ,
    
    # Rules for conjunctions
    "Adjunction", (
        ϕ,
        ψ
    ), ϕ ∧ ψ,
    "Simplification (Left)", (
        ϕ ∧ ψ
    ), ϕ,
    "Simplification (Right)", (
        ϕ ∧ ψ
    ), ψ,
    
    # Rules for disjunctions
    "Addition", (
        ϕ
    ), ϕ ∨ ψ,
    "Case Analysis", (
        ϕ → χ,
        ψ → χ,
        ϕ ∨ ψ
    ), χ,
    "Disjunctive Syllogism (Right)", (
        ϕ ∨ ψ,
        ¬ϕ
    ), ψ,
    "Disjunctive Syllogism (Left)", (
        ϕ ∨ ψ,
        ¬ψ
    ), ϕ,
    "Constructive Dilemma", (
        ϕ → χ,
        ψ → ξ,
        ϕ ∨ ψ
    ), χ ∨ ξ,

    # Rules for biconditionals
    "Biconditional Introduction", (
        ϕ → ψ,
        ψ → ϕ
    ), ϕ ⟷ ψ,
    "Biconditional Elimination (Asserted Left)", (
        ϕ ⟷ ψ,
        ϕ
    ), ψ,
    "Biconditional Elimination (Asserted Right)", (
        ϕ ⟷ ψ,
        ψ
    ), ϕ,
    "Biconditional Elimination (Negated Left)", (
        ϕ ⟷ ψ,
        ¬ϕ
    ), ¬ψ,
    "Biconditional Elimination (Negated Left)", (
        ϕ ⟷ ψ,
        ¬ψ
    ), ¬ϕ,
    "Biconditional Elimination (Asserted Disjunction)", (
        ϕ ⟷ ψ,
        ϕ ∨ ψ
    ), ϕ ∧ ψ,
    "Biconditional Elimination (Asserted Disjunction)", (
        ϕ ⟷ ψ,
        ¬ϕ ∨ ¬ψ
    ), ¬ϕ ∧ ¬ψ
end
