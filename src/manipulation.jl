export matches, recursivematches, replace, find_matches, find_matches!, evaluate, associative_ordering, isequal_associative

function reconstruct_replacement(replacement_expr::AbstractExpression, replacements::Dict{LogicalSymbol, AbstractExpression})
    if istree(replacement_expr)
        rr = reconstruct_replacement.(arguments(replacement_expr), flat_repeat(replacements, length(arguments(replacement_expr))))
        return LogicalExpression(Vector{AbstractExpression}(rr), operation(replacement_expr))
    end

    return replacements[replacement_expr]
end

function Base.replace(expr::AbstractExpression, rule::Pair{T, U}) where {T <: AbstractExpression, U <: AbstractExpression}
    replacements = Dict{LogicalSymbol, AbstractExpression}()
    if !find_matches!(expr, rule.first, replacements)
        return expr
    end

    reconstruct_replacement(rule.second, replacements)
end

function recursivereplace(expr::AbstractExpression, rule::Pair{T, U}) where {T <: AbstractExpression, U <: AbstractExpression}
    replaced_expr = replace(expr, rule)
    if replaced_expr == expr && istree(replaced_expr)
        new_args = Vector{AbstractExpression}(recursivereplace.(arguments(expr), flat_repeat(rule, length(arguments(expr)))))
        if any(new_args .!= arguments(expr))
            return LogicalExpression(new_args, operation(expr))
        end
    end

    return replaced_expr
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
    elseif pattern isa ExtensionalSet
        if !(expr isa ExtensionalSet) || cardinality(expr) != cardinality(pattern)
            return false
        end

        # return all(find_matches!.())
    end

    if haskey(matches, pattern)
        return isequal(matches[pattern], expr)
    else
        matches[pattern] = expr
    end
    true
end

function recursivematches(expr::AbstractExpression, pattern::AbstractExpression)
    if matches(expr, pattern)
        return true
    end
    return any(recursivematches.(arguments(expr), flat_repeat(pattern, length(arguments(expr)))))
end

substitute(sym::LogicalSymbol, symbol_values::Dict{LogicalSymbol, AbstractExpression}) = haskey(symbol_values, sym) ? symbol_values[sym] : sym
function substitute(expr::LogicalExpression, symbol_values::Dict{LogicalSymbol, AbstractExpression})
    return LogicalExpression(Vector{AbstractExpression}(substitute.(arguments(expr), flat_repeat(symbol_values, length(arguments(expr))))), operation(expr))
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
evaluate(expr::LogicalExpression, values::Dict{LogicalSymbol, Bool}=Dict{LogicalSymbol, Bool}()) = operation(expr).bool_fn((evaluate.(arguments(expr), Iterators.repeat([values], length(arguments(expr)))))...)



# Association
_isleft(x) = x == 1
_isright(x) = x == 2
_opposite_direction(x) = _isleft(x) ? 2 : 1
function associative_step(expr::AbstractExpression, leaf::AbstractExpression, direction)
    expr_copy = deepcopy(expr)
    associative_step!(expr_copy, leaf, direction)
end
function associative_step!(expr::AbstractExpression, leaf::AbstractExpression, direction)
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
    parent_node = descension_expr
    current_node = arguments(descension_expr)[direction]
    while istree(current_node)
        parent_node = current_node
        current_node = arguments(current_node)[downwards_direction]
    end

    associated_expr = LogicalExpression(_isleft(direction) ? AbstractExpression[current_node, leaf] : AbstractExpression[leaf, current_node], operation(expr))

    other_expr = select_by_path(expr, [leaf_path[1:end-1]..., _opposite_direction(leaf_path[end])])
    if !isequal(current_node, other_expr)
        
        t = select_by_path(expr, leaf_path[1:end-2])
        set_argument(parent_node, downwards_direction, associated_expr)
        if length(leaf_path[1:end-2]) == 0
            return arguments(expr)[direction]
        end
        set_argument(t, downwards_direction, other_expr)
    end
    @info expr

    expr
end
