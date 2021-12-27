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

matches(expr::AbstractExpression, pattern::AbstractExpression) = find_matches!(expr, pattern, Dict{LogicalSymbol, AbstractExpression}())

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

    if haskey(matches, pattern)
        return isequal(matches[pattern], expr)
    else
        matches[pattern] = expr
    end
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



# Association
"""
    recursive_handedness(expr::AbstractExpression, compare_symbol::LogicalSymbol, base_symbol::LogicalSymbol)

Returns the handedness (left or right for binary operators) of the comparison symbol relative to the base symbol in a given expression.
A symbol can also be "ambidextrous" if an instance of it can be found on both the left and the right.
"""
function recursive_handedness(expr::AbstractExpression, compare_symbol::LogicalSymbol, base_symbol::LogicalSymbol)
    both_symbols_set = Set([compare_symbol, base_symbol])
    left_variables = variables(left(expr))
    right_variables = variables(right(expr))

    left_side = if both_symbols_set ⊆ left_variables
        recursive_handedness(left(expr), compare_symbol, base_symbol)
    end
    right_side = if both_symbols_set ⊆ right_variables
        recursive_handedness(right(expr), compare_symbol, base_symbol)
    end

    if !isnothing(left_side) && !isnothing(right_side)
        return :ambidextrous
    end
    if !isnothing(left_side)
        return left_side
    end
    if !isnothing(right_side)
        return right_side
    end

    if compare_symbol ∈ left_variables && compare_symbol ∈ right_variables
        return :ambidextrous
    end
    if compare_symbol ∈ left_variables
        return :left
    end
    if compare_symbol ∈ right_variables
        return :right
    end
end

_isleft(x) = x == 1
_isright(x) = x == 2
_opposite_direction(x) = _isleft(x) ? 2 : 1
function associative_step(expr::AbstractExpression, leaf::AbstractExpression, direction)
    leaf_path = locate_expression(expr, leaf)

    descension_expr = nothing
    for i ∈ (length(leaf_path)):-1:1
        if leaf_path[i] != direction
            subpath = leaf_path[1:(i-1)]
            descension_expr = select_by_path(expr, subpath)
            break
        end
    end

    if isnothing(descension_expr)
        return expr
    end

    downwards_direction = _opposite_direction(direction)
    current_node = arguments(descension_expr)[direction]
    while istree(current_node)
        current_node = arguments(current_node)[downwards_direction]
    end
    
    @info current_node
end
