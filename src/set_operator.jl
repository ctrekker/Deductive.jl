export ∈, ×, ⊂

# pure operators
set_in = LogicalOperation((a, b)->false, :∈, 2, false, false)
∈(x, S::MathematicalSet) = LogicalExpression(AbstractExpression[x, S], set_in)
∉(x, S::MathematicalSet) = ¬(x ∈ S)
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

# subset operator
# subset_op = LogicalOperation((a, b)->false, :⊆, 2)
# ⊆(A::MathematicalSet, B::MathematicalSet) = LogicalExpression(AbstractExpression[A, B], subset_op)
