@testset "Rewrite Rules" begin
    a, b = LogicalSymbol.([:a, :b])


end

@testset "Propositional Proofs" begin
    a, b, c, d = LogicalSymbol.([:a, :b, :c, :d])

    # trivially true, since we assert any proposition as true when passed as a parameter of `prove`
    @test prove(a)
    @test prove(b)
    @test prove(¬a)
    @test prove(a ∧ b)
    @test prove(a ∨ b)
    @test prove(a → b)
    @test prove(a ← b)
    @test prove(a ⟷ b)
    
    # multiple premises, still trivially true
    @test prove([a, b])
    @test prove(a, b)  # alternate preferable syntax
    @test prove(a → b, a, b)

    # some contradictory premises should yield false
    @test !prove(a, ¬a)
    @test !prove(a ∧ b, ¬a)
    @test !prove(a → b, a, ¬b)
    @test !prove(a ⟷ b, ¬a, b)
    @test !prove(a ∧ b ∨ c, ¬c, ¬a)
    @test !prove(a → b, b → c, c → d, a, ¬d)
end

@testset "Predicate Proofs" begin
    a, b = LogicalSymbol.([:a, :b])
    x, y, z = FreeVariable.([:x, :y, :z])
    P, Q = Predicate.([:P, :Q])

    # test cases taken from https://www.esf.kfi.zcu.cz/logika/opory/ia008/tableau_pred-sol.pdf

    ex_a = Ā(x, P(x)) ⟷ ¬Ē(x, ¬P(x))
    @test !prove(¬ex_a)
    
    ex_b = Ā(x, P(x) → Q(x)) → (Ā(x, P(x)) → Ā(x, Q(x)))
    @test !prove(¬ex_b)

    ex_c = Ā(x, P(x) ∧ Q(x)) ⟷ (Ā(x, P(x)) ∧ Ā(x, Q(x)))
    @test !prove(¬ex_c)

    # support for multiple free variables later...
    # ex_d = Ē(y, Ā(x, P(x, y) ⟷ P(x, x))) → ¬Ā(x, Ē(y, Ā(z, P(z, y) ⟷ P(z, x))))
    # @test !prove(¬ex_d)
end
