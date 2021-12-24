macro test_binary_operator(op, vals)
    quote
        @test $(op)(false, false) == $(vals)[1]
        @test $(op)(true, false) == $(vals)[2]
        @test $(op)(false, true) == $(vals)[3]
        @test $(op)(true, true) == $(vals)[4]
    end
end


@testset "Expressions" begin
    @testset "Built-in Operators" begin
        @test isdefined(Deductive, :¬)
        @test isdefined(Deductive, :∧)
        @test isdefined(Deductive, :∨)
        @test isdefined(Deductive, :→)
        @test isdefined(Deductive, :⟷)

        
        @test ¬(true) == false
        @test ¬(false) == true
    
        @test_binary_operator ∨ (false, true, true, true)
        @test_binary_operator ∧ (false, false, false, true)
    
        @test_binary_operator → (true, false, true, true)
        @test_binary_operator ⟷ (true, false, false, true)
    end

    @testset "LogicalSymbol Core" begin
        @test (LogicalSymbol <: Deductive.AbstractExpression)

        a = LogicalSymbol(:a)

        my_metadata = "AbCdEfG"
        with_metadata = LogicalSymbol(:b, my_metadata)
        
        # conversion to julia symbol
        @test Symbol(a) == :a
        @test Symbol(with_metadata) == :b

        # tree / node tools
        @test !istree(a)
        @test isnode(a)
        @test !istree(with_metadata)
        @test isnode(with_metadata)

        # metadata getters
        @test isnothing(metadata(a))
        @test !isnothing(metadata(with_metadata))
        @test metadata(with_metadata) == my_metadata

        # constituent variables
        @test length(variables(a)) == 1
        @test first(variables(a)) === a
        @test length(variables(with_metadata)) == 1
        @test first(variables(with_metadata)) == with_metadata

        # symbol comparison
        @test isequal(a, a)
        @test isequal(with_metadata, with_metadata)
        @test isequal(a, LogicalSymbol(:a))
        @test isequal(with_metadata, LogicalSymbol(:b, my_metadata))
        @test !isequal(a, LogicalSymbol(:b))
        @test !isequal(with_metadata, LogicalSymbol(:b))
        @test !isequal(a, LogicalSymbol(:a, 0))
        @test !isequal(a, LogicalSymbol(:a, (nothing,)))
    end

    @testset "LogicalOperation Core" begin
        neg_op = Deductive.LogicalOperation(x -> !x, :¬, 1)
        and_op = Deductive.LogicalOperation(:∧, 2) do x, y
            x && y
        end
        ternary_op = Deductive.LogicalOperation(:Δ, 3) do x, y, z
            x && y && z
        end

        # operation names
        @test Symbol(neg_op) == :¬
        @test Symbol(and_op) == :∧
        @test Symbol(ternary_op) == :Δ

        # isunary and isbinary tests
        @test isunary(neg_op)
        @test !isbinary(neg_op)
        @test !isunary(and_op)
        @test isbinary(and_op)
        @test !isunary(ternary_op)
        @test !isbinary(ternary_op)

        # equality checking
        # two operators are equal if their names and arguments are the same
        @test isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :¬, 1))
        @test !isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :¬, 2))
        @test !isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :-, 1))
        @test isequal(neg_op, Deductive.LogicalOperation((x) -> x, :¬, 1))

        # material operation
        @test neg_op(false)
        @test !neg_op(true)
        @test and_op(true, true)
        @test !and_op(true, false)
        @test ternary_op(true, true, true)
        @test !ternary_op(false, true, true)
        @test !ternary_op(true, false, true)
        @test !ternary_op(true, true, false)
        @test ternary_op(BitVector((1, 1, 1)))
        @test !ternary_op(BitVector((1, 0, 1)))
    end

    @testset "LogicalExpression Core" begin
        @test (Deductive.LogicalExpression <: Deductive.AbstractExpression)
        
        a, b, c = LogicalSymbol.([:a, :b, :c])
        st = a ∧ b

        @test st isa Deductive.LogicalExpression
        @test istree(st)
        @test !isnode(st)
        @test operation(st) === ∧
        @test all(arguments(st) .== (a, b))
        @test isnothing(metadata(st))

        # equality checking
        @test isequal(st, st)
        @test isequal(st, a ∧ b)
        @test isequal(a ∧ b, a ∧ b)
        @test !isequal(a ∧ b, a ∨ b)
        @test !isequal(¬a, ¬¬a)
        @test !isequal((a ∧ b) ∧ c, a ∧ (b ∧ c))
        @test !isequal(a ∧ b, b ∧ a)
        @test !isequal(a ∧ b, a ∧ c)

        # variables tree
        @test variables(¬a) == Set([a])
        @test variables(¬¬a) == Set([a])
        @test variables(a ∧ b) == Set([a, b])
        @test variables(¬(a ∨ b)) == Set([a, b])
        @test variables(¬(a ∨ b) → a) == Set([a, b])
        @test variables(¬(a ∨ b) → c) == Set([a, b, c])
    end
end
