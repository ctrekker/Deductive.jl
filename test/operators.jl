macro test_binary_operator(op, vals)
    quote
        @test $(op)(false, false) == $(vals)[1]
        @test $(op)(true, false) == $(vals)[2]
        @test $(op)(false, true) == $(vals)[3]
        @test $(op)(true, true) == $(vals)[4]
    end
end


@testset "Binary Operators" begin
    @test ¬(true) == false
    @test ¬(false) == true

    exported_operators = [:¬, :→, :⟶, :⟹, :←, :⟵, :↔, :⟷, :⇔, :∨, :∧]
    @test all(isdefined.(repeat([PropositionalLogic], length(exported_operators)), exported_operators))

    @test_binary_operator ∨ (false, true, true, true)
    @test_binary_operator ∧ (false, false, false, true)

    @test_binary_operator → (true, false, true, true)
    @test_binary_operator ⟶ (true, false, true, true)
    @test_binary_operator ⟹ (true, false, true, true)

    @test_binary_operator ← (true, true, false, true)
    @test_binary_operator ⟵ (true, true, false, true)

    @test_binary_operator ↔ (true, false, false, true)
    @test_binary_operator ⟷ (true, false, false, true)
    @test_binary_operator ⇔ (true, false, false, true)
end
