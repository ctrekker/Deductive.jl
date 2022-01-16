export ×, ⊂

# pure operators
set_in = LogicalOperation((a, b)->set_includes(a, b), :∈, 2, false, false)
Base.:(∈)(x, S::MathematicalSet) = LogicalExpression(AbstractExpression[x, S], set_in)
Base.:(∉)(x, S::MathematicalSet) = ¬(x ∈ S)
# subset operator
⊂ = LogicalOperation((a, b)->false, :⊂, 2)

# ×
function ×(A::MathematicalSet, B::MathematicalSet)
    @unique_symbols a b
    IntensionalSet(orderedpair(a, b), (a ∈ A, b ∈ B))
end
function ×(x, A::MathematicalSet)
    @unique_symbols a
    IntensionalSet(orderedpair(x, a), a ∈ A)
end
function ×(A::MathematicalSet, x)
    @unique_symbols a
    IntensionalSet(orderedpair(a, x), a ∈ A)
end

# ∪
function Base.:(∪)(A::MathematicalSet, B::MathematicalSet)
    @unique_symbols a
    IntensionalSet(a, (a ∈ A) ∨ (a ∈ B))
end

# ∩
function Base.:(∩)(A::MathematicalSet, B::MathematicalSet)
    @unique_symbols a
    IntensionalSet(a, (a ∈ A) ∧ (a ∈ B))
end

# \ (set difference)
function Base.:(\)(A::MathematicalSet, B::MathematicalSet)
    @unique_symbols a
    IntensionalSet(a, (a ∈ A) ∧ (a ∉ B))
end
