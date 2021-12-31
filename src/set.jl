export ExtensionalSet, IntensionalSet, settuple, cardinality, ∅


abstract type MathematicalSet <: AbstractExpression end


struct ExtensionalSet{T} <: MathematicalSet
    elements::Set{T}
end
ExtensionalSet(elements::Vector{T}) where {T} = ExtensionalSet(Set{T}(elements))
ExtensionalSet(elements::Tuple{Vararg{T}}) where {T} = ExtensionalSet(Set{T}([elements...]))
elements(es::ExtensionalSet) = es.elements
Base.length(es::ExtensionalSet) = length(elements(es))
Base.isempty(es::ExtensionalSet) = Base.isempty(elements(es))
cardinality(es::ExtensionalSet) = length(es)
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
function settuple(a...)
    a = [a...]
    if length(a) == 0
        return ∅
    end
    x = settuple(a[1:end-1]...)
    ExtensionalSet([ExtensionalSet([x]), ExtensionalSet([x, a[end]])])
end


struct IntensionalSet <: MathematicalSet
    transform::Function
    rule::AbstractExpression
end

∅ = ExtensionalSet(Set([]))
