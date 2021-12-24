@testset "Expression Manipulation" begin
    a, b, c = LogicalSymbol.([:a, :b, :c])
    x, y, z = LogicalSymbol.([:x, :y, :z])

    @testset "Evaluation" begin
        st1 = a ∧ b        
        @test evaluate(st1, Dict(a => true, b => true))
        @test !evaluate(st1, Dict(a => true, b => false))
        @test !evaluate(st1, Dict(a => false, b => false))

        st2 = (a ∧ b) → c
        @test evaluate(st2, Dict(a => true, b => true, c => true))
        @test evaluate(st2, Dict(a => false, b => true, c => true))
        @test evaluate(st2, Dict(a => false, b => false, c => true))
        @test !evaluate(st2, Dict(a => true, b => true, c => false))
    end

    @testset "Matching" begin
        st1 = a ∧ ¬b
        @test matches(st1, x)
        @test matches(st1, x ∧ y)
        @test !matches(st1, x ∨ y)
        @test !matches(st1, ¬x ∧ y)
        @test matches(st1, x ∧ ¬y)

        st2 = a → (b ∨ ¬c)
        @test matches(st2, x)
        @test matches(st2, x → y)
        @test matches(st2, x → (y ∨ z))
        @test matches(st2, x → (y ∨ ¬z))
        @test !matches(st2, ¬x)
        @test !matches(st2, ¬x → y)
        @test !matches(st2, x → ¬y)
        @test !matches(st2, x → (y ∧ z))
        
        st3 = (a ∧ b) ∨ (a ∧ b)
        @test matches(st3, x)
        @test matches(st3, x ∨ x)
        @test matches(st3, x ∨ y)
        @test matches(st3, (x ∧ y) ∨ (x ∧ y))
        @test !matches(st3, (x ∧ y) ∨ (y ∧ x))
        @test !matches(st3, ¬x)
    end

    # TODO: Rename this from replace to something more relevant to rule application
    @testset "Replacement" begin
        @test isequal(replace(a, x => ¬x), ¬a)
        @test isequal(replace(a ∧ b, x => ¬x), ¬(a ∧ b))
        @test isequal(replace(a ∧ a, (x ∧ x) => x), a)
        @test isequal(replace(a → b, (x → y) => (¬x ∨ y)), ¬a ∨ b)
        @test isequal(replace(a → ¬b, (x → y) => (¬x ∨ y)), ¬a ∨ ¬b)
        @test isequal(replace(¬(a ∨ b) ∨ ¬(a ∧ b), (¬x ∨ ¬y) => ¬(x ∧ y)), ¬((a ∨ b) ∧ (a ∧ b)))
    end
end
