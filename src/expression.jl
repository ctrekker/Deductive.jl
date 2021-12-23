module Expression

export ¬, ∧, ∨, →, ⟷, LogicalSymbol


abstract type AbstractExpression end

struct LogicalSymbol <: AbstractExpression
    name::Symbol
end
istree(::LogicalSymbol) = false
isnode(::LogicalSymbol) = true
Base.show(io::IO, sym::LogicalSymbol) = print(io, string(sym.name))


struct LogicalOperation
    name::Symbol
    argument_count::Int
end
isunary(op::LogicalOperation) = op.argument_count == 1
isbinary(op::LogicalOperation) = op.argument_count == 2
Base.show(io::IO, op::LogicalOperation) = print(io, string(op.name))


function (op::LogicalOperation)(args...)
    if length(args) != op.argument_count
        throw(ErrorException("Invalid argument count $(length(args)). Expected $(op.argument_count) arguments."))
    end
    return LogicalExpression([args...], op)
end

struct LogicalExpression <: AbstractExpression
    arguments::Vector{AbstractExpression}
    operation::LogicalOperation
end
istree(::LogicalExpression) = true
isnode(::LogicalSymbol) = false
operation(expr::LogicalExpression) = expr.operation
arguments(expr::LogicalExpression) = expr.arguments

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
const ¬ = LogicalOperation(:¬, 1)

# binary operators
const ∧ = LogicalOperation(:∧, 2)
const ∨ = LogicalOperation(:∨, 2)
const → = LogicalOperation(:→, 2)
const ⟷ = LogicalOperation(:⟷, 2)


include("./replacement.jl")


end # module
