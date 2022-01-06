flat_repeat(x, n) = Iterators.repeat([x], n)

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
