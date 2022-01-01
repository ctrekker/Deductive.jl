export ExtensionalSet, IntensionalSet, settuple, orderedpair, cardinality, ∅, 𝔻


abstract type MathematicalSet <: AbstractExpression end
@symbols ϕ


struct ExtensionalSet{T} <: MathematicalSet
    elements::Set{T}
end
ExtensionalSet(elements::Vector{T}) where {T} = ExtensionalSet(Set{T}(elements))
ExtensionalSet(elements::Tuple{Vararg{T}}) where {T} = ExtensionalSet(Set{T}([elements...]))
elements(es::ExtensionalSet) = es.elements
Base.length(es::ExtensionalSet) = length(elements(es))
Base.isempty(es::ExtensionalSet) = Base.isempty(elements(es))
Base.hash(es::ExtensionalSet, h::UInt) = hash(elements(es), h)
Base.:(==)(es1::ExtensionalSet, es2::ExtensionalSet) = elements(es1) == elements(es2)
cardinality(es::ExtensionalSet) = length(es)

# expression methods
variables(::ExtensionalSet) = Set{LogicalSymbol}()
operations(::ExtensionalSet) = Set{LogicalOperation}()

function Base.show(io::IO, es::ExtensionalSet)
    if isempty(es)
        print(io, "∅")
        return
    end

    print(io, "{")
    i = 1
    for el ∈ elements(es)
        print(io, el)
        if i < cardinality(es)
            print(io, ", ")
        end
        i += 1
    end
    print(io, "}")
end

orderedpair(a, b) = ExtensionalSet([ExtensionalSet([a]), ExtensionalSet([a, b])])
function settuple(a...)
    a = [a...]
    if length(a) == 0
        return ∅
    end
    x = settuple(a[1:end-1]...)
    ExtensionalSet([ExtensionalSet([x]), ExtensionalSet([x, a[end]])])
end


struct IntensionalSet <: MathematicalSet
    transform::AbstractExpression
    supersets::Set{LogicalExpression}
    rule::AbstractExpression

    function IntensionalSet(transform::AbstractExpression, supersets::Set{LogicalExpression}, rule::AbstractExpression)
        # todo: build out nested type system
        function checksettype(s)
            if operation(s) != set_in
                return false
            end
            if typeof(left(s)) != LogicalSymbol
                return false
            end
            if !(typeof(right(s)) <: MathematicalSet)
                return false
            end
            return true
        end

        if any(checksettype.(supersets))
            throw(ErrorException("All supersets must take form α ∈ A, where α is a `LogicalSymbol` and A is a `MathematicalSet`"))
        end
        new(transform, supersets, rule)
    end
end
IntensionalSet(transform::AbstractExpression, supersets::Set{LogicalExpression}) = IntensionalSet(transform, supersets, ϕ ∨ ¬ϕ)
IntensionalSet(transform::AbstractExpression, supersets::Vector{LogicalExpression}) = IntensionalSet(transform, Set{LogicalExpression}(supersets))
IntensionalSet(transform::AbstractExpression, supersets::Tuple{Vararg{LogicalExpression}}) = IntensionalSet(transform, [supersets...])
transform(is::IntensionalSet) = is.transform
rule(is::IntensionalSet) = is.rule

# expression methods
variables(is::IntensionalSet) = variables(rule(is))
operations(is::IntensionalSet) = operations(rule(is))

function Base.show(io::IO, is::IntensionalSet)
    print(io, "{")
    print(io, transform(is))
    print(io, " | ")
    print(io, rule(is))
    print(io, "}")
end


∅ = ExtensionalSet(Set([]))
𝔻 = IntensionalSet(ϕ, ¬(ϕ ∈ ∅))


# special definitions
# natural numbers:
#  ℕ = ...
