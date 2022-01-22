"""
    OperatorIndexTable(roots::Set{Int}, operators::Dict{LogicalOperation, Vector{OperatorIndexTable}})

Structure for a operator table, which keeps a mapping from operators to their constituent argument subexpressions. Roots is a set
of identifiers which have been matched at this table level and operators is a dictionary mapping each logical operation to a list
of subtables corresponding directly to each of the operator's arguments.

Usually indexes aren't constructed directly through this constructor, but rather through helper functions like [`index`](@ref).
"""
mutable struct OperatorIndexTable <: AbstractDeductiveIndexTable
    roots::Set{Int}
    operators::Dict{LogicalOperation, Vector{OperatorIndexTable}}
end
OperatorMap = Dict{LogicalOperation, Vector{OperatorIndexTable}}
"""
    OperatorIndexTable()

Initializes an empty [`OperatorIndexTable`](@ref).
"""
OperatorIndexTable() = OperatorIndexTable(Set{Int}(), OperatorMap())
"""
    roots(t::OperatorIndexTable)

Gets the `roots` property from an [`OperatorIndexTable`](@ref).
"""
roots(t::OperatorIndexTable) = t.roots
"""
    operators(t::OperatorIndexTable)

Gets the `operators` property from an [`OperatorIndexTable`](@ref).
"""
operators(t::OperatorIndexTable) = t.operators

function add!(table::OperatorIndexTable, entry::Tuple{Int, LogicalSymbol})
    expr_id, sym = entry
    push!(roots(table), expr_id)
end
function add!(table::OperatorIndexTable, entry::Tuple{Int, LogicalExpression})
    expr_id, expr = entry
    expr_op, expr_args = operation(expr), arguments(expr)

    push!(roots(table), expr_id)

    if !haskey(operators(table), expr_op)
        operators(table)[expr_op] = [OperatorIndexTable() for _ ∈ 1:argument_count(expr_op)]
    end

    op_subtables = operators(table)[expr_op]
    for i ∈ 1:length(op_subtables)
        add!(op_subtables[i], (expr_id, expr_args[i]))
    end
end

"""
    search(table::OperatorIndexTable, sym::LogicalSymbol)

Perform a trivial search in an operator table for a symbol. Since logical symbols are expression tree roots,
this search will immediately return the roots of the particular `OperatorIndexTable`.
"""
search(table::OperatorIndexTable, ::LogicalSymbol) = roots(table)
"""
    search(table::OperatorIndexTable, operator_pattern::LogicalExpression)

Search for an operator pattern in a [`OperatorIndexTable`](@ref).

!!! note
    There's an important distinction between "expression pattern" and "operator pattern". An expression pattern matches both 
    operator and symbol structure, while an operator pattern only matches an operator structure. Take the expression
    `(a ∧ b) ∧ c` for instance. The pattern `a ∧ a`, when interpreted as an expression pattern, would _not_ match, while
    when interpreted as an operator pattern it _would_ match.

"""
function search(table::OperatorIndexTable, operator_pattern::LogicalExpression)
    expr_op, expr_args = operation(operator_pattern), arguments(operator_pattern)
    if !haskey(operators(table), expr_op)
        return Set{Int}()
    end
    op_subtables = operators(table)[expr_op]
    return reduce(∩, [search(op_subtables[i], expr_args[i]) for i ∈ 1:length(op_subtables)])
end

function index(expressions::Set{AbstractExpression})
    root_table = OperatorIndexTable()
    idx = Index(root_table, Dict{Int, AbstractExpression}())

    for expression ∈ expressions
        add!(idx, expression)
    end

    idx
end
index(expressions::Vector{AbstractExpression}) = index(Set{AbstractExpression}(expressions))
