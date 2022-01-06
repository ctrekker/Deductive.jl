export ∅, 𝔻, NaturalNumber, @natural

@symbols ϕ
∅ = ExtensionalSet(Set([]))
𝔻 = IntensionalSet(ϕ, ¬(ϕ ∈ ∅))


# von Neumann ordinals
function NaturalNumber(x::Int)
    if x == 0
        return ∅
    end

    ExtensionalSet([NaturalNumber(n) for n ∈ 0:(x-1)])
end

macro natural(assignment)
    @assert assignment.head == :(=) "Operator must be the assignment operator (=)"
    quote
        $(esc(assignment.args[1])) = NaturalNumber($(assignment.args[2]))
    end
end

# special definitions
# natural numbers:
#  ℕ = ...
