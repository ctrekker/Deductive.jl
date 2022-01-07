"""
    flat_repeat(x, n)

Shortcut for `Iterators.repeat([x], n)`
"""
flat_repeat(x, n) = Iterators.repeat([x], n)

"""
    FakeVector{X, T}(creator::X, fieldname::Symbol, vec::Vector{T})

A utility structure which calls a function `setvectorindex!` when the `Base.setindex!` function is called on it. This
allows for some smart updating of expression trees when mutated.
"""
struct FakeVector{X, T}
    creator::X
    fieldname::Symbol
    vec::Vector{T}
end

function Base.getindex(fv::FakeVector{X, T}, i) where {X, T}
    throw(ErrorException("attempted to get index of `$(typeof(fv))`"))
end
function Base.setindex!(fv::FakeVector{X, T}, val, inds...) where {X, T}
    if length(inds) > 1
        @warn "indexes greater than length 1 (provided is length $(length(inds)) will be truncated to length 1"
    end
    setvectorindex!(fv.creator, fv.fieldname, val, first(inds))
end
