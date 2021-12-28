export ¬, ∧, ∨, →, ⟷
export LogicalSymbol, istree, isnode, metadata, variables, operation, arguments, left, right
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
Base.show(io::IO, sym::LogicalSymbol) = print(io, string(sym.name))
Base.:(==)(sym1::LogicalSymbol, sym2::LogicalSymbol) = sym1.name == sym2.name && isequal(metadata(sym1), metadata(sym2))
Base.isless(sym1::LogicalSymbol, sym2::LogicalSymbol) = Base.isless(sym1.name, sym2.name)


struct LogicalOperation
    bool_fn::Function
    name::Symbol
    argument_count::Int
end
isunary(op::LogicalOperation) = op.argument_count == 1
isbinary(op::LogicalOperation) = op.argument_count == 2
Base.show(io::IO, op::LogicalOperation) = print(io, string(op.name))
Base.:(==)(op1::LogicalOperation, op2::LogicalOperation) = op1.name == op2.name && op1.argument_count == op2.argument_count

function (op::LogicalOperation)(args::AbstractExpression...)
    if length(args) != op.argument_count
        throw(ErrorException("Invalid argument count $(length(args)). Expected $(op.argument_count) arguments."))
    end
    return LogicalExpression(AbstractExpression[args...], op)
end
(op::LogicalOperation)(args::Bool...) = op.bool_fn(args...)
(op::LogicalOperation)(args::BitVector) = op.bool_fn(args...)

mutable struct LogicalExpression <: AbstractExpression
    arguments::Vector{AbstractExpression}
    operation::LogicalOperation
    variables::Set{LogicalSymbol}  # this set is the reason we make expressions immutable

    function LogicalExpression(arguments::Vector{AbstractExpression}, operation::LogicalOperation)
        new(arguments, operation, reduce(∪, variables.(arguments)))
    end
end
istree(::LogicalExpression) = true
isnode(::LogicalExpression) = false
operation(expr::LogicalExpression) = expr.operation
arguments(expr::LogicalExpression) = expr.arguments
metadata(::LogicalExpression) = nothing
variables(expr::LogicalExpression) = expr.variables
left(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[1] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
right(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[2] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
Base.:(==)(expr1::LogicalExpression, expr2::LogicalExpression) = isequal(operation(expr1), operation(expr2)) && all(isequal.(arguments(expr1), arguments(expr2)))
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


# unary operator
const ¬ = LogicalOperation(x -> !x, :¬, 1)

# binary operators
const ∧ = LogicalOperation((x, y) -> x && y, :∧, 2)
const ∨ = LogicalOperation((x, y) -> x || y, :∨, 2)
const → = LogicalOperation((x, y) -> (¬x ∨ y), :→, 2)
const ⟷ = LogicalOperation((x, y) -> (x ∧ y) ∨ (¬x ∧ ¬y), :⟷, 2)
