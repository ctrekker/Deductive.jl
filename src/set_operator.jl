export ×

×(A::ExtensionalSet{U}, B::ExtensionalSet{V}) where {U, V} = ExtensionalSet(vec([Tuple{U, V}((x, y)) for x ∈ elements(A), y ∈ elements(B)]))
×(A::IntensionalSet, B::IntensionalSet) = IntensionalSet(settuple(a, b), (a ∈ A) ∧ (b ∈ B))
