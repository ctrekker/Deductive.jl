@testset "Indexes" begin
    @testset "General Interface" begin
        @test isdefined(Deductive, :Index)
        # not sure what else should go here tbh. if anything is wrong the downstream tests will catch it
    end

    @testset "Expressions Index" begin
        @symbols a b c x

        exprs1 = Set{AbstractExpression}([
            a,
            b,
            c
        ])
        idx1 = Deductive.index(exprs1)
        @test idx1.current_id == 4
        @test length(keys(idx1.identifier_map)) == 3
        @test typeof(idx1.table) == Deductive.OperatorIndexTable
        @test length(search(idx1, x)) == 3
        @test search(idx1, x) == Set([a, b, c])
        @test length(search(idx1, x ∨ x)) == 0

        exprs2 = Set{AbstractExpression}([
            a ∧ b,
            b → a,
            c ∧ (a → b),
            a ⟷ b
        ])
        idx2 = Deductive.index(exprs2)
        @test idx2.current_id == 5
        @test length(keys(idx2.identifier_map)) == 4
        @test typeof(idx2.table) == Deductive.OperatorIndexTable
        @test length(search(idx2, x)) == 4
        @test length(search(idx2, x ∨ x)) == 0
        @test search(idx2, x ∧ x) == Set([a ∧ b, c ∧ (a → b)])
        @test search(idx2, x → x) == Set([b → a])
        @test search(idx2, x ⟷ x) == Set([a ⟷ b])
    end
end
