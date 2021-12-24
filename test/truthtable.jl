@testset "Truth Tables" begin
    a, b, c = LogicalSymbol.([:a, :b, :c])
    
    # a ∧ b  (a and b)
    st = a ∧ b
    and_tt = truthtable(st)
    @test all(and_tt[!, :a] .== [false, true, false, true])
    @test all(and_tt[!, :b] .== [false, false, true, true])
    @test all(and_tt[!, string(st)] .== [false, false, false, true])

    # b ∨ a  (b or a)
    st = b ∨ a
    or_tt = truthtable(st)
    @test all(or_tt[!, :b] .== [false, false, true, true])
    @test all(or_tt[!, :a] .== [false, true, false, true])
    @test all(or_tt[!, string(st)] .== [false, true, true, true])

    # material implication
    st = a → b
    mi_tt = truthtable(st)
    @test all(mi_tt[!, string(st)] .== [true, false, true, true])

    # slightly more complex statement
    st = (a → b) ∧ c
    mi_tt = truthtable(st)
    @test all(mi_tt[!, string(st)] .== [false, false, false, false, true, false, true, true])
end
