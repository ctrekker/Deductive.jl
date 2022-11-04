export contains_expression

# SUBEXPRESSION SEARCH

# if haystack is a logical symbol, the kneedle must be equal to be a subexpression
"""
    contains_expression(haystack::AbstractExpression, kneedle::AbstractExpression)

Searches for a subexpression `kneedle` recursively within the `haystack` expression. Returns true if a match can be found
and false otherwise.
"""
contains_expression(haystack::LogicalSymbol, kneedle::AbstractExpression) = isequal(haystack, kneedle)

# TODO: come up with quicker subexpression algorithm for LogicalExpressions
# if kneedle is an expression, use a recursive equality check
function contains_expression(haystack::LogicalExpression, kneedle::LogicalExpression)
    if isequal(haystack, kneedle)
        return true
    end
    return any(contains_expression.(arguments(haystack), repeat([kneedle], length(arguments(haystack)))))
end

# if kneedle is a symbol, use the variables set to quickly check if its a subexpression
contains_expression(haystack::LogicalExpression, kneedle::LogicalSymbol) = kneedle ∈ variables(haystack)


# dfs for expression search; returns path to first found expression, otherwise empty vector
locate_expression(haystack::LogicalSymbol, kneedle::AbstractExpression) = []
function locate_expression(haystack::LogicalExpression, kneedle::AbstractExpression)
    i = 1
    for arg ∈ arguments(haystack)
        if isequal(arg, kneedle)
            return [i]
        end
        located = locate_expression(arg, kneedle)
        if length(located) > 0
            return [i, located...]
        end
        i += 1
    end
    return []
end


function select_by_path(expr::AbstractExpression, path::Vector{Int})
    if length(path) == 0
        return expr
    end
    return select_by_path(arguments(expr)[path[1]], path[2:end])
end
