export ¬, ∧, ∨, →, ⟷
export LogicalSymbol, istree, isnode, name, metadata, variables, operation, operations, arguments, parents, left, right, isassociative, iscommutative
export isunary, isbinary, argument_count
export @symbols, @unique_symbols


"""
    AbstractExpression

The abstract type which all expression trees are built from.
"""
abstract type AbstractExpression end

"""
    LogicalSymbol(name::Symbol, metadata::Any=nothing)

Represent a logical symbolically with a provided name. By default the attached metadata is set to `nothing`.
"""
struct LogicalSymbol <: AbstractExpression
    name::Symbol
    metadata::Any
end
LogicalSymbol(name::Symbol) = LogicalSymbol(name, nothing)
"""
    name(sym::LogicalSymbol)

The name of the symbol provided at instantiation. Equivalent to `symbol(sym)`.
"""
name(sym::LogicalSymbol) = sym.name
"""
    metadata(sym::LogicalSymbol)

The metadata of the symbol provided at instantiation, if any. Returns `nothing` if none was provided.
"""
metadata(sym::LogicalSymbol) = sym.metadata

Base.show(io::IO, sym::LogicalSymbol) = print(io, string(sym.name))
Base.hash(sym::LogicalSymbol, h::UInt) = hash(sym.name, hash(sym.metadata, h))
Base.:(==)(sym1::LogicalSymbol, sym2::LogicalSymbol) = sym1.name == sym2.name && isequal(metadata(sym1), metadata(sym2))
Base.isless(sym1::LogicalSymbol, sym2::LogicalSymbol) = Base.isless(sym1.name, sym2.name)

# fake copy methods since symbols are immutable
Base.copy(sym::LogicalSymbol) = sym
Base.deepcopy(sym::LogicalSymbol) = LogicalSymbol(name(sym), deepcopy(metadata(sym)))

# convenience macros
"""
Define any number of [`LogicalSymbols`](@ref Deductive.LogicalSymbol) with the names provided.

# Examples
```julia-repl
julia> @symbols a  # defines symbol `a` in the current scope

julia> @symbols b c d  # defines symbols `a`, `b`, and `c`

julia> @symbols α β γ  # defines symbols `α`, `β`, and `γ`
```
"""
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


"""
    LogicalOperation(bool_fn::Function, name::Symbol, argument_count::Int, associative::Bool, commutative::Bool)

Defines a logical operator which can be used to form expressions with. Usually you don't need to define your own
operators, just use the ones built-in to the package if possible.
"""
struct LogicalOperation
    bool_fn::Function
    name::Symbol
    argument_count::Int
    associative::Bool
    commutative::Bool
end
LogicalOperation(bool_fn::Function, name::Symbol, argument_count::Int) = LogicalOperation(bool_fn, name, argument_count, false, false)
name(op::LogicalOperation) = op.name
"""
    argument_count(op::LogicalOperation)

The number of arguments which the given operation expects to receive.
"""
argument_count(op::LogicalOperation) = op.argument_count
"""
    isunary(op::LogicalOperation)

True if the given operation only receives one argument, false otherwise.
"""
isunary(op::LogicalOperation) = argument_count(op) == 1
"""
    isbinary(op::LogicalOperation)

True if the given operation receives two arguments, false otherwise.
"""
isbinary(op::LogicalOperation) = argument_count(op) == 2
"""
    isassociative(op::LogicalOperation)
    
True if the given operation is associative, false otherwise.
"""
isassociative(op::LogicalOperation) = op.associative
"""
    iscommutative(op::LogicalOperation)

True if the given operation is commutative, false otherwise.
"""
iscommutative(op::LogicalOperation) = op.commutative
Base.show(io::IO, op::LogicalOperation) = print(io, string(op.name))
Base.hash(op::LogicalOperation, h::UInt) = hash(op.name, hash(argument_count(op), hash(op.associative, hash(op.commutative, h))))
function Base.:(==)(op1::LogicalOperation, op2::LogicalOperation)
    op1.name == op2.name && argument_count(op1) == argument_count(op2) && isassociative(op1) == isassociative(op2) && iscommutative(op1) == iscommutative(op2)
end

"""
    (op::LogicalOperation)(args::AbstractExpression...)

This function is the foundation of expression building, as it allows instances of `LogicalOperations` to be treated as real
Julia functions. When called this function returns a `LogicalExpression` representing the application of the given operator
on the provided arguments.
"""
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
"""
    LogicalExpression(arguments::Vector{AbstractExpression}, operation::LogicalOperation)

Constructs an expression with given arguments and logical operation. Please refrain from using this syntax, instead using
the "operators as functions" syntax, where a `LogicalOperation` instance can be called to produce a `LogicalExpression`.
"""
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
        add_to_parents!(expr)
        expr
    end
end
"""
    operation(expr::LogicalExpression)

The operation which is performed on the arguments of the given `LogicalExpression`.
"""
operation(expr::LogicalExpression) = getfield(expr, :operation)
"""
    parents(expr::LogicalExpression)

The parent expressions of a given subexpression. If an expression is never used within another, it will have no parents.
In most expressions there will only be one parent, but it is possible for an expression assigned to a variable to have
multiple parents by using it as a "named subexpression".
"""
parents(expr::LogicalExpression) = getfield(expr, :parents)

"""
    add_to_parents!(expr::LogicalExpression)

Adds an expression to the `parents` set of all its arguments. For internal use only.
"""
add_to_parents!(expr::LogicalExpression) = add_to_parents!(expr, arguments(expr))
function add_to_parents!(expr::LogicalExpression, relevant_args::Vector{AbstractExpression})
    for arg ∈ relevant_args
        if arg isa LogicalExpression
            push!(parents(arg), expr)
        end
    end
end

"""
    remove_from_parents!(expr::LogicalExpression)

Removes an expression from the `parents` set of all its arguments. For internal use only.
"""
remove_from_parents!(expr::LogicalExpression) = remove_from_parents!(expr, arguments(expr))
function remove_from_parents!(expr::LogicalExpression, relevant_args::Vector{AbstractExpression})
    for arg ∈ relevant_args
        if arg isa LogicalExpression
            delete!(parents(arg), expr)
        end
    end
end
metadata(::LogicalExpression) = nothing
"""
    left(expr::LogicalExpression)

If the expression is binary, this method returns the left-hand operand.
"""
left(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[1] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
"""
    right(expr::LogicalExpression)

If the expression is binary, this method returns the right-hand operand.
"""
right(expr::LogicalExpression) = isbinary(operation(expr)) ? arguments(expr)[2] : throw(ErrorException("Operation $(operation(expr)) is not binary"))
"""
    isassociative(expr::LogicalExpression)

Checks if the entire expression is associative based on the associative property of its constituent operations.
"""
isassociative(expr::LogicalExpression) = length(operations(expr)) == 1 && isassociative(operation(expr))
"""
    iscommutative(expr::LogicalExpression)

Checks if the entire expression is commutative based on the commutative property of its constituent operations.
"""
iscommutative(expr::LogicalExpression) = length(operations(expr)) == 1 && iscommutative(operation(expr))
Base.hash(expr::LogicalExpression, h::UInt) = hash(arguments(expr), hash(operation(expr), h))
Base.:(==)(expr1::LogicalExpression, expr2::LogicalExpression) = operation(expr1) == operation(expr2) && all(arguments(expr1) .== arguments(expr2))

# copy methods
Base.copy(expr::LogicalExpression) = LogicalExpression(Vector{AbstractExpression}(arguments(expr)), operation(expr))
Base.deepcopy(expr::LogicalExpression) = LogicalExpression(Vector{AbstractExpression}(deepcopy.(arguments(expr))), operation(expr))

# mutability methods
function Base.setproperty!(expr::LogicalExpression, name::Symbol, x)
    if name == :arguments
        remove_from_parents!(expr)
        setfield!(expr, name, x)
        add_to_parents!(expr)
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
        remove_from_parents!(expr, arguments(expr)[index:index])
        getfield(expr, :arguments)[index] = x
        add_to_parents!(expr, arguments(expr)[index:index])
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


# Standard AbstractExpression interface methods
"""
    istree(expr::T) where {T <: AbstractExpression}

Returns true when `expr` is a `LogicalExpression` and false otherwise.
"""
istree(::LogicalSymbol) = false
istree(::LogicalExpression) = true

"""
    isnode(expr::T) where {T <: AbstractExpression}

Returns true when `expr` is a `LogicalSymbol` and false otherwise.
"""
isnode(::LogicalSymbol) = true
isnode(::LogicalExpression) = false

"""
    variables(expr::T) where {T <: AbstractExpression}

Returns variables present in an entire expression tree. When the first argument is a `LogicalSymbol`, this is singleton
set containing only the provided `LogicalSymbol`. When the argument is a `LogicalExpression`, this is a set containing the union
of all the variables present in each argument.
"""
variables(sym::LogicalSymbol) = Set{LogicalSymbol}(LogicalSymbol[sym])
function variables(expr::LogicalExpression)
    if !getfield(expr, :cached_variables_valid)
        setfield!(expr, :cached_variables, recursivevariables(arguments(expr)))
        expr.cached_variables_valid = true
    end
    getfield(expr, :cached_variables)
end

"""
    operations(expr::T) where {T <: AbstractExpression}

Returns the operations present in an entire expression tree. When given a `LogicalSymbol`, this is an empty set, whereas 
when given a `LogicalExpression`, this is a set containing the expression's own `LogicalOperation` and the operations set
of each of its arguments.
"""
operations(::LogicalSymbol) = Set{LogicalOperation}([])
function operations(expr::LogicalExpression)
    if !getfield(expr, :cached_operations_valid)
        setfield!(expr, :cached_operations, recursiveoperations(arguments(expr), operation(expr)))
        expr.cached_operations_valid = true
    end
    getfield(expr, :cached_operations)
end

"""
    arguments(expr::T) where {T <: AbstractExpression}

Returns the arguments which an `AbstractExpression` contains. `LogicalSymbols` contain no arguments and `LogicalExpressions`
can contain any number of arguments.
"""
arguments(::LogicalSymbol) = AbstractExpression[]
arguments(expr::LogicalExpression) = getfield(expr, :arguments)


# ASSOCIATION (perhaps move this elsewhere eventually?)
"""
    associative_ordering(expr::LogicalExpression)

Descends the expression tree with a left-side-first depth first search. Each symbol encountered is added to a list in
the order it appears in this search and is returned by this function.
"""
associative_ordering(expr::LogicalExpression) = reduce(vcat, associative_ordering.(arguments(expr)))
associative_ordering(sym::LogicalSymbol) = [sym]

"""
    isequal_associative(expr1::LogicalExpression, expr2::LogicalExpression)

Checks whether an expression is equal with another ignoring the associative ordering of each expression.
"""
function isequal_associative(expr1::LogicalExpression, expr2::LogicalExpression)
    length(operations(expr1)) == 1 && isassociative(first(operations(expr1))) && operations(expr1) == operations(expr2) && associative_ordering(expr1) == associative_ordering(expr2)
end
isequal_associative(sym1::LogicalSymbol, sym2::LogicalSymbol) = isequal(sym1, sym2)
isequal_associative(::AbstractExpression, ::AbstractExpression) = false

_associative_tree_count_cache = Dict()
"""
    associative_tree_count(nodes::Int)

Function which calculates how many ways to arrange parenthesis in an expression there are with a given node count.
"""
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
"""
    ¬(x)

Logical negation operator, typed with `\\neg`. Boolean equivalent is the `!` operator.
"""
const ¬ = LogicalOperation(x -> !x, :¬, 1, false, false)

# binary operators
"""
    x ∧ y

Logical conjunction operator, typed with `\\wedge`. Boolean equivalent is the `&&` operator.
"""
const ∧ = LogicalOperation((x, y) -> x && y, :∧, 2, true, true)
"""
    x ∨ y

Logical disjunction operator, typed with `\\vee`. Boolean equivalent is the `||` operator.
"""
const ∨ = LogicalOperation((x, y) -> x || y, :∨, 2, true, true)
"""
    x → y

Logical implication operator, typed with `\\rightarrow`.
"""
const → = LogicalOperation((x, y) -> (¬x ∨ y), :→, 2, false, false)
"""
    x ⟷ y

Logical equivalence operator, typed with `\\longleftrightarrow`.
"""
const ⟷ = LogicalOperation((x, y) -> (x ∧ y) ∨ (¬x ∧ ¬y), :⟷, 2, true, true)
