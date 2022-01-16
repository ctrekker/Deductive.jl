@testset "Common Algorithms" begin
    @testset "Constrained Output Elimination" begin
        constrained_output_elimination = Deductive.constrained_output_elimination

        # most of these test cases are stolen from the Pluto notebook linked in #21
        f1 = constrained_output_elimination(Dict(
            :a => Set([1]),
            :b => Set([1, 2])
        ))
        @test f1[:a] == Set([1])
        @test f1[:b] == Set([2])

        f2 = constrained_output_elimination(Dict(
            :a => Set([1]),
            :b => Set([2, 1]),
            :c => Set([2, 3])
        ))
        @test f2[:a] == Set([1])
        @test f2[:b] == Set([2])
        @test f2[:c] == Set([3])

        f3 = constrained_output_elimination(Dict(
            :a => Set([1]),
            :b => Set([1, 2, 3]),
            :c => Set([2, 3]),
            :d => Set([2, 3, 4]),
            :e => Set([4, 5])
        ))
        @test f3[:a] == Set([1])
        @test f3[:b] == Set([2, 3])
        @test f3[:c] == Set([2, 3])
        @test f3[:d] == Set([4])
        @test f3[:e] == Set([5])
    end
end
