@testset "Rewrite Rules" begin
    a, b = LogicalSymbol.([:a, :b])


end

@testset "Tableau Proofs" begin
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
