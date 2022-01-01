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
    rule::AbstractExpression
end
IntensionalSet(transform::AbstractExpression, rules::Vector{LogicalExpression}) = IntensionalSet(transform, reduce(∧, rules))
IntensionalSet(transform::AbstractExpression, rules::Set{LogicalExpression}) = IntensionalSet(transform, [rules...])
IntensionalSet(transform::AbstractExpression, rules::Tuple{Vararg{LogicalExpression}}) = IntensionalSet(transform, [rules...])
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
