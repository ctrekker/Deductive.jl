export prove_implication

p, q = LogicalSymbol.([:p, :q])
default_replacement_rules = [
    ¬(p ∧ q) => ¬p ∨ ¬q,
    ¬p ∨ ¬q => ¬(p ∧ q),
    ¬(p ∨ q) => ¬p ∧ ¬q,
    ¬p ∧ ¬q => ¬(p ∨ q),
    ¬¬p => p,
    p => ¬¬p,
    # p → q => ¬p ∨ q,
    # ¬(p → q) => p ∧ ¬q,
    # p ⟷ q => (p ∧ q) ∨ (¬p ∧ ¬q),
    # ¬(p ⟷ q) => (p ∧ ¬q) ∨ (¬p ∧ q),
]

struct RuleApplication
    rule::Pair{AbstractExpression, AbstractExpression}
    expression::AbstractExpression
end
expression(ra::RuleApplication) = ra.expression

function prove_implication(imp_expr::LogicalExpression)
    if operation(imp_expr) != →
        throw(ErrorException("Single argument `prove_implication` requires that the provided expression is an implication (→)"))
    end

    prove_implication(left(imp_expr), right(imp_expr))
end
function prove_implication(left::AbstractExpression, right::AbstractExpression; replacement_rules=default_replacement_rules)
    visited_expressions = Set{AbstractExpression}([left])
    expression_queue = [left]
    while length(expression_queue) > 0
        @info visited_expressions
        current_expression = first(expression_queue)
        if current_expression == right
            return true
        end
        deleteat!(expression_queue, 1)

        for rr ∈ replacement_rules
            replaced_expression = recursivereplace(current_expression, rr)
            if replaced_expression != current_expression && replaced_expression ∉ visited_expressions
                push!(expression_queue, replaced_expression)
                push!(visited_expressions, replaced_expression)
            end
        end
    end

    false
end
