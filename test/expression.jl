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

        # constituent symbols (always none)
        @test isempty(operations(a))
        @test isempty(operations(with_metadata))

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
        neg_op = Deductive.LogicalOperation(x -> !x, :¬, 1, false, false)
        and_op = Deductive.LogicalOperation(:∧, 2, true, true) do x, y
            x && y
        end
        ternary_op = Deductive.LogicalOperation(:Δ, 3, true, true) do x, y, z
            x && y && z
        end

        @testset "Operation Names" begin
            @test Symbol(neg_op) == :¬
            @test Symbol(and_op) == :∧
            @test Symbol(ternary_op) == :Δ
        end

        @testset "isunary and isbinary" begin
            @test isunary(neg_op)
            @test !isbinary(neg_op)
            @test !isunary(and_op)
            @test isbinary(and_op)
            @test !isunary(ternary_op)
            @test !isbinary(ternary_op)
        end

        @testset "Equality Checking" begin
            # two operators are equal if their names, arguments, and associative / commutative properties are the same
            @test isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :¬, 1, false, false))
            @test !isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :¬, 2, false, false))
            @test !isequal(neg_op, Deductive.LogicalOperation((x) -> !x, :-, 1, false, false))
            @test isequal(neg_op, Deductive.LogicalOperation((x) -> x, :¬, 1, false, false))
            @test !isequal(neg_op, Deductive.LogicalOperation((x) -> x, :¬, 1, true, false))
            @test !isequal(neg_op, Deductive.LogicalOperation((x) -> x, :¬, 1, false, true))
        end

        @testset "Material Operation" begin
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
        
        @testset "isassociative and iscommutative" begin
            # isassociative for builtins
            @test isassociative(∧)
            @test isassociative(∨)
            @test isassociative(⟷)
            @test !isassociative(¬)
            @test !isassociative(→)

            # iscommutative for builtins
            @test iscommutative(∧)
            @test iscommutative(∨)
            @test iscommutative(⟷)
            @test !iscommutative(¬)
            @test !iscommutative(→)
        end
    end

    @testset "LogicalExpression Core" begin
        @test (Deductive.LogicalExpression <: Deductive.AbstractExpression)
        
        a, b, c, d = LogicalSymbol.([:a, :b, :c, :d])
        st = a ∧ b

        @testset "Basics" begin
            @test st isa Deductive.LogicalExpression
            @test istree(st)
            @test !isnode(st)
            @test operation(st) === ∧
            @test all(arguments(st) .== (a, b))
            @test isnothing(metadata(st))
        end

        @testset "Equality Checking" begin
            @test isequal(st, st)
            @test isequal(st, a ∧ b)
            @test isequal(a ∧ b, a ∧ b)
            @test !isequal(a ∧ b, a ∨ b)
            @test !isequal(¬a, ¬¬a)
            @test !isequal((a ∧ b) ∧ c, a ∧ (b ∧ c))
            @test !isequal(a ∧ b, b ∧ a)
            @test !isequal(a ∧ b, a ∧ c)
        end

        @testset "Variables Tree" begin
            @test variables(¬a) == Set([a])
            @test variables(¬¬a) == Set([a])
            @test variables(a ∧ b) == Set([a, b])
            @test variables(¬(a ∨ b)) == Set([a, b])
            @test variables(¬(a ∨ b) → a) == Set([a, b])
            @test variables(¬(a ∨ b) → c) == Set([a, b, c])
        end

        @testset "Operations Tree" begin
            @test operations(¬a) == Set([¬])
            @test operations(¬¬a) == Set([¬])
            @test operations(a ∧ b) == Set([∧])
            @test operations(a ∧ ¬b) == Set([∧, ¬])
            @test operations(a ∧ ¬(b ∨ c)) == Set([∧, ∨, ¬])
            @test operations(¬(a ∨ b) → a) == Set([∨, ¬, →])
        end

        @testset "Binary Operator Methods" begin
            @test left(a ∧ b) == a
            @test right(a ∧ b) == b
            @test left((a ∧ b) ∨ (b ∧ c)) == (a ∧ b)
            @test right((a ∧ b) ∨ (b ∧ c)) == (b ∧ c)
        end


        @testset "Associative Expressions" begin
            @test isassociative(a ∧ b)
            @test isassociative(a ∨ b)
            @test isassociative(a ∨ b ∨ c)
            @test isassociative(a ⟷ b ⟷ c)
            @test !isassociative(¬a)
            @test !isassociative(a → b)
            @test !isassociative(a → b → c)
        end

        @testset "Commutative Expressions" begin
            @test iscommutative(a ∧ b)
            @test iscommutative(a ∨ b)
            @test iscommutative(a ∨ b ∨ c)
            @test iscommutative(a ⟷ b ⟷ c)
            @test !iscommutative(¬a)
            @test !iscommutative(a → b)
            @test !iscommutative(a → b → c)
        end

        @testset "Associative Orderings" begin
            @test associative_ordering(a) == [a]
            @test associative_ordering(b) == [b]
            @test associative_ordering(a ∧ b) == [a, b]
            @test associative_ordering(b ∧ a) == [b, a]
            @test associative_ordering(¬b ∧ a) == [b, a]
            @test associative_ordering((¬b ∨ c) ∧ a) == [b, c, a]
            @test associative_ordering((¬a ∨ (b ∨ c)) ∧ d) == [a, b, c, d]
        end
        
        @testset "Associative Equality" begin
            @test isequal_associative(a, a)
            @test isequal_associative(b, b)
            @test !isequal_associative(a, b)
            @test isequal_associative(a ∧ b, a ∧ b)
            @test !isequal_associative(a ∧ b, b ∧ a)
            @test !isequal_associative(a ∧ b, a ∨ b)
            @test !isequal_associative(a ∧ ¬b, a ∧ ¬b)
        end

        @testset "Associative Tree Count" begin
            @test Deductive.associative_tree_count(0) == 1
            @test Deductive.associative_tree_count(1) == 1
            @test Deductive.associative_tree_count(2) == 2
            @test Deductive.associative_tree_count(3) == 5
            @test Deductive.associative_tree_count(4) == 14
            @test Deductive.associative_tree_count(5) == 42
            @test Deductive.associative_tree_count(6) == 132
        end


        # mutability tests
        @testset "Copy Expression" begin
            # Base.copy tests
            copied_st = copy(st)
            @test copied_st == st   # still the same expression
            @test copied_st !== st  # but not the same reference
            @test first(arguments(copied_st)) == first(arguments(copied_st))
            @test first(arguments(copied_st)) === first(arguments(copied_st))

            # Base.deepcopy tests
            st2 = (a ∧ b) ∧ c
            dc_st2 = deepcopy(st2)
            @test dc_st2 == st2
            @test dc_st2 !== st2
            @test first(arguments(dc_st2)) == first(arguments(st2))
            @test first(arguments(dc_st2)) !== first(arguments(st2))
            @test arguments(dc_st2)[2] == arguments(st2)[2]
            @test arguments(dc_st2)[2] === arguments(st2)[2]  # the second arg is a symbol so it shouldn't be copied
        end
    end
end
