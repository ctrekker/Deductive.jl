export ¬, ∧, ∨, →, ⟷
export LogicalSymbol, istree, isnode, metadata, variables, operation, operations, arguments, left, right, isassociative, iscommutative, @symbols, @unique_symbols
export isunary, isbinary


abstract type AbstractExpression end

struct LogicalSymbol <: AbstractExpression
    name::Symbol
    metadata::Any
end
LogicalSymbol(name::Symbol) = LogicalSymbol(name, nothing)
istree(::LogicalSymbol) = false
isnode(::LogicalSymbol) = true
metadata(sym::LogicalSymbol) = sym.metadata
variables(sym::LogicalSymbol) = Set{LogicalSymbol}(LogicalSymbol[sym])
operations(::LogicalSymbol) = Set{LogicalOperation}([])
arguments(::LogicalSymbol) = AbstractExpression[]
Base.show(io::IO, sym::LogicalSymbol) = print(io, string(sym.name))
Base.hash(sym::LogicalSymbol, h::UInt) = hash(sym.name, hash(sym.metadata, h))
Base.:(==)(sym1::LogicalSymbol, sym2::LogicalSymbol) = sym1.name == sym2.name && isequal(metadata(sym1), metadata(sym2))
Base.isless(sym1::LogicalSymbol, sym2::LogicalSymbol) = Base.isless(sym1.name, sym2.name)


macro symbols(syms...)
    definitions = [:(
        $(esc(sym)) = LogicalSymbol($(esc(Symbol))($(string(sym))))
    ) for sym ∈ syms]
    quote
        $(definitions...)
        nothing
    end
end


_unique_index = 1
macro unique_symbols(syms...)
    global _unique_index

    unique_names = [Symbol("u" * subscript_number(_unique_index + i)) for i ∈ 0:(length(syms) - 1)]
    definitions = [:(
        $(esc(sym)) = LogicalSymbol($(esc(Symbol))($(string(unique_name))))
    ) for (sym, unique_name) ∈ zip(syms, unique_names)]

    _unique_index += length(syms)

    quote
        $(definitions...)
        nothing
    end
end


struct LogicalOperation
    bool_fn::Function
    name::Symbol
    argument_count::Int
    associative::Bool
    commutative::Bool
end
LogicalOperation(bool_fn::Function, name::Symbol, argument_count::Int) = LogicalOperation(bool_fn, name, argument_count, false, false)
isunary(op::LogicalOperation) = op.argument_count == 1
isbinary(op::LogicalOperation) = op.argument_count == 2
isassociative(op::LogicalOperation) = op.associative
iscommutative(op::LogicalOperation) = op.commutative
Base.show(io::IO, op::LogicalOperation) = print(io, string(op.name))
Base.hash(op::LogicalOperation, h::UInt) = hash(op.name, hash(op.argument_count, hash(op.associative, hash(op.commutative, h))))
function Base.:(==)(op1::LogicalOperation, op2::LogicalOperation)
    op1.name == op2.name && op1.argument_count == op2.argument_count && isassociative(op1) == isassociative(op2) && iscommutative(op1) == iscommutative(op2)
end

function (op::LogicalOperation)(args::AbstractExpression...)
    if length(args) != op.argument_count
        throw(ErrorException("Invalid argument count $(length(args)). Expected $(op.argument_count) arguments."))
    end
    return LogicalExpression(AbstractExpression[args...], op)
end
(op::LogicalOperation)(args::Bool...) = op.bool_fn(args...)
(op::LogicalOperation)(args::BitVector) = op.bool_fn(args...)

struct LogicalExpression <: AbstractExpression
    arguments::Vector{AbstractExpression}
    operation::LogicalOperation
    # these sets are the reason we make expressions immutable
    variables::Set{LogicalSymbol}
    operations::Set{LogicalOperation}

    function LogicalExpression(arguments::Vector{AbstractExpression}, operation::LogicalOperation)
        new(arguments, operation, reduce(∪, variables.(arguments)), reduce(∪, operations.(arguments)) ∪ Set([operation]))
    end
end
istree(::LogicalExpression) = true
isnode(::LogicalExpression) = false
operation(expr::LogicalExpression) = expr.operation
arguments(expr::LogicalExpression) = expr.arguments
metadata(::LogicalExpression) = nothing
variables(expr::LogicalExpression) = expr.variables
operations(expr::LogicalExpression) = expr.operations
left(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[1] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
right(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[2] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
isassociative(expr::LogicalExpression) = length(operations(expr)) == 1 && isassociative(operation(expr))
iscommutative(expr::LogicalExpression) = length(operations(expr)) == 1 && iscommutative(operation(expr))
Base.hash(expr::LogicalExpression, h::UInt) = hash(expr.arguments, hash(expr.operation, h))
Base.:(==)(expr1::LogicalExpression, expr2::LogicalExpression) = operation(expr1) == operation(expr2) && all(arguments(expr1) .== arguments(expr2))
function set_argument(expr::LogicalExpression, index::Int, new_argument::AbstractExpression)
    expr.arguments[index] = new_argument
    expr.variables = reduce(∪, variables.(arguments(expr)))
    expr
end


function Base.show(io::IO, expr::LogicalExpression)
    showparens(expr) = (expr isa LogicalExpression) && !isunary(expr.operation)

    if isunary(expr.operation)
        arg = first(arguments(expr))
        show(io, expr.operation)
        if showparens(arg)
            print(io, "(")
        end
        print(io, arg)
        if showparens(arg)
            print(io, ")")
        end
    elseif isbinary(operation(expr))
        args = expr.arguments

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
