export ∈, ×

set_in = LogicalOperation((a, b)->false, :∈, 2, false, false)
∈(x, S::MathematicalSet) = LogicalExpression(AbstractExpression[x, S], set_in)
# ×(A::ExtensionalSet{U}, B::ExtensionalSet{V}) where {U, V} = ExtensionalSet(vec([Tuple{U, V}((x, y)) for x ∈ elements(A), y ∈ elements(B)]))
function ×(A::MathematicalSet, B::MathematicalSet)
    @unique_symbols a b
    IntensionalSet(orderedpair(a, b), (a ∈ A) ∧ (b ∈ B))
end
function ×(x, A::MathematicalSet)
    @unique_symbols a
    IntensionalSet(orderedpair(x, a), a ∈ A)
end
function ×(A::MathematicalSet, x)
    @unique_symbols a
    IntensionalSet(orderedpair(a, x), a ∈ A)
end
