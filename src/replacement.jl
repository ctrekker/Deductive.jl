export matches, replace, find_matches, find_matches!

function reconstruct_replacement(replacement_expr::AbstractExpression, replacements::Dict{LogicalSymbol, AbstractExpression})
    if istree(replacement_expr)
        return LogicalExpression(reconstruct_replacement.(arguments(replacement_expr), Iterators.repeat([replacements], length(arguments(replacement_expr)))), operation(replacement_expr))
    end

    return replacements[replacement_expr]
end

function Base.replace(expr::AbstractExpression, rule::Pair{T, T}) where {T <: AbstractExpression}
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
