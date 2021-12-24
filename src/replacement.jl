export matches, replace, find_matches, find_matches!, evaluate

function reconstruct_replacement(replacement_expr::AbstractExpression, replacements::Dict{LogicalSymbol, AbstractExpression})
    if istree(replacement_expr)
        rr = reconstruct_replacement.(arguments(replacement_expr), Iterators.repeat([replacements], length(arguments(replacement_expr))))
        return LogicalExpression(Vector{AbstractExpression}(rr), operation(replacement_expr))
    end

    return replacements[replacement_expr]
end

function Base.replace(expr::AbstractExpression, rule::Pair{T, U}) where {T <: AbstractExpression, U <: AbstractExpression}
    replacements = find_matches(expr, rule.first)
    if length(keys(replacements)) == 0
        return expr
    end

    reconstruct_replacement(rule.second, replacements)
end

matches(expr::AbstractExpression, pattern::AbstractExpression) = length(keys(find_matches(expr, pattern))) > 0

function find_matches(expr::AbstractExpression, pattern::AbstractExpression)
    matches = Dict{LogicalSymbol, AbstractExpression}()
    find_matches!(expr, pattern, matches)

    matches
end
function find_matches!(expr::AbstractExpression, pattern::AbstractExpression, matches::Dict{LogicalSymbol, AbstractExpression})
    if istree(pattern)
        if !istree(expr) || operation(pattern) != operation(expr)
            return false
        end

        return all(find_matches!.(arguments(expr), arguments(pattern), Iterators.repeat([matches], length(arguments(expr)))))
    end

    matches[pattern] = expr
    true
end


# simplification schemes
function repeated_chain_simplify(expr::AbstractExpression, rules::Vector{Pair{AbstractExpression, AbstractExpression}})
    modified_expression = expr

    i = 1
    while i <= length(rules)
        rule = rules[i]
        replacement_expression = replace(modified_expression, rule)
        i += 1
        if modified_expression != replacement_expression
            modified_expression = replacement_expression
            i = 1
        end
    end

    modified_expression
end

evaluate(sym::LogicalSymbol, values::Dict{LogicalSymbol, Bool}) = values[sym]
evaluate(expr::LogicalExpression, values::Dict{LogicalSymbol, Bool}) = operation(expr)(evaluate.(arguments(expr), Iterators.repeat([values], length(arguments(expr)))))
