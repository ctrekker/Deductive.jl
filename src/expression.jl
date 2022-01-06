export ¬, ∧, ∨, →, ⟷
export LogicalSymbol, istree, isnode, metadata, variables, operation, operations, arguments, parents, left, right, isassociative, iscommutative
export isunary, isbinary


abstract type AbstractExpression end

struct LogicalSymbol <: AbstractExpression
    name::Symbol
    metadata::Any
end
LogicalSymbol(name::Symbol) = LogicalSymbol(name, nothing)
istree(::LogicalSymbol) = false
isnode(::LogicalSymbol) = true
name(sym::LogicalSymbol) = sym.name
metadata(sym::LogicalSymbol) = sym.metadata
variables(sym::LogicalSymbol) = Set{LogicalSymbol}(LogicalSymbol[sym])
operations(::LogicalSymbol) = Set{LogicalOperation}([])
arguments(::LogicalSymbol) = AbstractExpression[]
Base.show(io::IO, sym::LogicalSymbol) = print(io, string(sym.name))
Base.hash(sym::LogicalSymbol, h::UInt) = hash(sym.name, hash(sym.metadata, h))
Base.:(==)(sym1::LogicalSymbol, sym2::LogicalSymbol) = sym1.name == sym2.name && isequal(metadata(sym1), metadata(sym2))
Base.isless(sym1::LogicalSymbol, sym2::LogicalSymbol) = Base.isless(sym1.name, sym2.name)

# fake copy methods since symbols are immutable
Base.copy(sym::LogicalSymbol) = sym
Base.deepcopy(sym::LogicalSymbol) = LogicalSymbol(name(sym), deepcopy(metadata(sym)))


struct LogicalOperation
    bool_fn::Function
    name::Symbol
    argument_count::Int
    associative::Bool
    commutative::Bool
end
argument_count(op::LogicalOperation) = op.argument_count
isunary(op::LogicalOperation) = argument_count(op) == 1
isbinary(op::LogicalOperation) = argument_count(op) == 2
isassociative(op::LogicalOperation) = op.associative
iscommutative(op::LogicalOperation) = op.commutative
Base.show(io::IO, op::LogicalOperation) = print(io, string(op.name))
Base.hash(op::LogicalOperation, h::UInt) = hash(op.name, hash(argument_count(op), hash(op.associative, hash(op.commutative, h))))
function Base.:(==)(op1::LogicalOperation, op2::LogicalOperation)
    op1.name == op2.name && argument_count(op1) == argument_count(op2) && isassociative(op1) == isassociative(op2) && iscommutative(op1) == iscommutative(op2)
end

function (op::LogicalOperation)(args::AbstractExpression...)
    if length(args) != argument_count(op)
        throw(ErrorException("Invalid argument count $(length(args)). Expected $(argument_count(op)) arguments."))
    end
    return LogicalExpression(AbstractExpression[args...], op)
end
(op::LogicalOperation)(args::Bool...) = op.bool_fn(args...)
(op::LogicalOperation)(args::BitVector) = op.bool_fn(args...)


recursivevariables(args::Vector{AbstractExpression}) = reduce(∪, variables.(args))
recursiveoperations(args::Vector{AbstractExpression}, rootop::LogicalOperation) = reduce(∪, operations.(args)) ∪ Set([rootop])
mutable struct LogicalExpression <: AbstractExpression
    arguments::Vector{AbstractExpression}
    operation::LogicalOperation

    parents::Set{LogicalExpression}

    cached_variables::Set{LogicalSymbol}
    cached_operations::Set{LogicalOperation}
    cached_variables_valid::Bool
    cached_operations_valid::Bool

    function LogicalExpression(arguments::Vector{AbstractExpression}, operation::LogicalOperation)
        expr = new(arguments, operation, Set{LogicalExpression}(), recursivevariables(arguments), recursiveoperations(arguments, operation), true, true)
        for arg ∈ arguments
            if arg isa LogicalExpression
                push!(parents(arg), expr)
            end
        end
        expr
    end
end
istree(::LogicalExpression) = true
isnode(::LogicalExpression) = false
operation(expr::LogicalExpression) = getfield(expr, :operation)
arguments(expr::LogicalExpression) = getfield(expr, :arguments)
parents(expr::LogicalExpression) = getfield(expr, :parents)
metadata(::LogicalExpression) = nothing
function variables(expr::LogicalExpression)
    if !getfield(expr, :cached_variables_valid)
        setfield!(expr, :cached_variables, recursivevariables(arguments(expr)))
        expr.cached_variables_valid = true
    end
    getfield(expr, :cached_variables)
end
function operations(expr::LogicalExpression)
    if !getfield(expr, :cached_operations_valid)
        setfield!(expr, :cached_operations, recursiveoperations(arguments(expr), operation(expr)))
        expr.cached_operations_valid = true
    end
    getfield(expr, :cached_operations)
end
left(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[1] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
right(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[2] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
isassociative(expr::LogicalExpression) = length(operations(expr)) == 1 && isassociative(operation(expr))
iscommutative(expr::LogicalExpression) = length(operations(expr)) == 1 && iscommutative(operation(expr))
Base.hash(expr::LogicalExpression, h::UInt) = hash(arguments(expr), hash(operation(expr), h))
Base.:(==)(expr1::LogicalExpression, expr2::LogicalExpression) = operation(expr1) == operation(expr2) && all(arguments(expr1) .== arguments(expr2))

# copy methods
Base.copy(expr::LogicalExpression) = LogicalExpression(Vector{AbstractExpression}(arguments(expr)), operation(expr))
Base.deepcopy(expr::LogicalExpression) = LogicalExpression(Vector{AbstractExpression}(deepcopy.(arguments(expr))), operation(expr))

# mutability methods
function Base.setproperty!(expr::LogicalExpression, name::Symbol, x)
    if name == :arguments
        setfield!(expr, name, x)
        expr.cached_variables_valid = false
    elseif name == :operation
        @assert argument_count(operation(expr)) == argument_count(x) "cannot assign operation with $(argument_count(x)) arguments to an expression with $(argument_count(operation(expr)))"
        setfield!(expr, name, x)
        expr.cached_operations_valid = false
    elseif name == :cached_variables_valid || name == :cached_operations_valid
        setfield!(expr, name, x)
        if !x  # cache invalidation, so propagate the invalidation up the expression tree
            for parent ∈ parents(expr)
                setproperty!(parent, name, x)
            end
        end
    elseif name == :cached_variables || name == :cached_operations
        throw(ErrorException("type LogicalExpression has protected field `$(name)`"))
    else
        throw(ErrorException("type LogicalExpression has no field `$(name)`"))
    end
end
function Base.getproperty(expr::LogicalExpression, name::Symbol)
    if name == :arguments
        return FakeVector(expr, name, getfield(expr, name))
    end

    throw(ErrorException("use method `$(name)(my_expr)` instead"))
end
# see utils.jl#FakeVector
function setvectorindex!(expr::LogicalExpression, name::Symbol, x, index::Int)
    if name == :arguments
        getfield(expr, :arguments)[index] = x
        expr.cached_variables_valid = false
    else
        @warn "unexpected `setvectorindex!` call for field `$(name)`"
    end
end
# this method is probably not optimized but it doesn't matter since expressions usually have two or fewer arguments, and this method
# will hardly ever be used regardless
function setvectorindex!(expr::LogicalExpression, name::Symbol, x, index::Union{UnitRange{Int}, StepRange{Int, Int}})
    li = 1  # linear index, to account for StepRange
    for i ∈ index
        setvectorindex!(expr, name, x[li], i)
        li += 1
    end
end

function set_argument(expr::LogicalExpression, index::Int, new_argument::AbstractExpression)
    expr.arguments[index] = new_argument
    expr.variables = reduce(∪, variables.(arguments(expr)))
    expr
end


function Base.show(io::IO, expr::LogicalExpression)
    showparens(expr) = (expr isa LogicalExpression) && !isunary(operation(expr))

    if isunary(operation(expr))
        arg = first(arguments(expr))
        show(io, operation(expr))
        if showparens(arg)
            print(io, "(")
        end
        print(io, arg)
        if showparens(arg)
            print(io, ")")
        end
    elseif isbinary(operation(expr))
        args = arguments(expr)

        if showparens(args[1])
            print(io, "(")
        end
        show(io, arguments(expr)[1])
        if showparens(args[1])
            print(io, ")")
        end

        print(io, " ")
        show(io, operation(expr))
        print(io, " ")

        if showparens(args[2])
            print(io, "(")
        end
        show(io, arguments(expr)[2])
        if showparens(args[2])
            print(io, ")")
        end
    end
end


# ASSOCIATION
associative_ordering(sym::LogicalSymbol) = [sym]
associative_ordering(expr::LogicalExpression) = reduce(vcat, associative_ordering.(arguments(expr)))

isequal_associative(sym1::LogicalSymbol, sym2::LogicalSymbol) = isequal(sym1, sym2)
function isequal_associative(expr1::LogicalExpression, expr2::LogicalExpression)
    length(operations(expr1)) == 1 && operations(expr1) == operations(expr2) && associative_ordering(expr1) == associative_ordering(expr2)
end
isequal_associative(::AbstractExpression, ::AbstractExpression) = false

_associative_tree_count_cache = Dict()
function associative_tree_count(nodes::Int)
    if nodes == 0
        return 1
    end
    if nodes == 1
        return 1
    end

    if haskey(_associative_tree_count_cache, nodes)
        return _associative_tree_count_cache[nodes]
    end

    agg = 0
    for i ∈ 0:(nodes - 1)
        agg += associative_tree_count(nodes - i - 1) * associative_tree_count(i)
    end

    _associative_tree_count_cache[nodes] = agg

    agg
end


# OPERATORS
# unary operator
const ¬ = LogicalOperation(x -> !x, :¬, 1, false, false)

# binary operators
const ∧ = LogicalOperation((x, y) -> x && y, :∧, 2, true, true)
const ∨ = LogicalOperation((x, y) -> x || y, :∨, 2, true, true)
const → = LogicalOperation((x, y) -> (¬x ∨ y), :→, 2, false, false)
const ⟷ = LogicalOperation((x, y) -> (x ∧ y) ∨ (¬x ∧ ¬y), :⟷, 2, true, true)
