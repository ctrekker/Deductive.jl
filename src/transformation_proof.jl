export prove_implication


function equivalence_rule(rule::Pair{U, V}) where {U <: AbstractExpression, V <: AbstractExpression}
    [
        rule,
        rule.second => rule.first
    ]
end

p, q = LogicalSymbol.([:p, :q])
default_replacement_rules = collect(Iterators.flatten([
    # material implication
    equivalence_rule(p → q => ¬p ∨ q),
    # material equivalence
    equivalence_rule(p ⟷ q => (p ∧ q) ∨ (¬p ∧ ¬q)),
    # demorgan's laws
    equivalence_rule(¬(p ∧ q) => ¬p ∨ ¬q),
    equivalence_rule(¬(p ∨ q) => ¬p ∧ ¬q),
    # double negation
    equivalence_rule(¬¬p => p),
]))

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
    expression_queue = AbstractExpression[left]
    while length(expression_queue) > 0
        current_expression = first(expression_queue)
        if current_expression == right
            return true
        end
        deleteat!(expression_queue, 1)

        for rr ∈ replacement_rules
            # @info replacement_metarules rr.first hash.(keys(replacement_metarules)) |> first hash(rr.first)
            replaced_expression = recursivereplace(current_expression, rr)
            has_redundant_negations = recursivematches(replaced_expression, ¬¬¬p)
            if replaced_expression != current_expression && !has_redundant_negations && replaced_expression ∉ visited_expressions
                push!(expression_queue, replaced_expression)
                push!(visited_expressions, replaced_expression)
            end
        end
    end

    false
end
