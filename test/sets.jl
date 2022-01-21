@testset "Sets" begin
    ES = ExtensionalSet  # TODO: Come up with better syntax for defining extensional sets

    @testset "Set Matching" begin
        @symbols x y z

        p1 = ES([x])
        p2 = ES([x, ES([y])])
        p3 = ES([x, y])

        A = ES([∅])
        B = ES([∅, ES([∅])])
        C = ES([∅, ES([∅, ES([∅])])])

        # test the trival pattern
        @test first(set_symbol_matches(x, A)[x]) == A
        @test first(set_symbol_matches(x, B)[x]) == B
        @test first(set_symbol_matches(x, C)[x]) == C

        @test first(set_symbol_matches(p1, A)[x]) == ∅
        @test classify_matches(set_symbol_matches(p1, B)) == Deductive.NO_MATCHES
        @test classify_matches(set_symbol_matches(p1, C)) == Deductive.NO_MATCHES

        m1A, m1B = set_symbol_matches(p2, B), set_symbol_matches(p2, C)
        @test first(m1A[x]) == ∅
        @test first(m1A[y]) == ∅
        @test classify_matches(m1B) == Deductive.NO_MATCHES

        m2A, m2B = set_symbol_matches(p3, A), set_symbol_matches(p3, B)
        @test classify_matches(m2A) == Deductive.NO_MATCHES
        @test classify_matches(m2B) == Deductive.PARTIAL_MATCH
        @test length(m2B[x]) == 2
        @test length(m2B[y]) == 2
    end

    @testset "Mixed Set Matching" begin
        # distinguished from test cases above by the mixing of set logic and logical expressions
        #   ends up being used in proof algorithms
        @symbols a b c x y z
        pattern = Set([x, x → y])  # modus ponens without the conclusion :)
        # premises1 = Set([a, a → b])

        # @test set_matches(pattern, premises1; strict=false)
        # TODO: actually write these tests lol
    end
end
