@testset "Rewrite Rules" begin
    a, b = LogicalSymbol.([:a, :b])


end

@testset "Propositional Proofs" begin
    a, b, c, d = LogicalSymbol.([:a, :b, :c, :d])

    # trivially true, since we assert any proposition as true when passed as a parameter of `tableau`
    @test tableau(a)
    @test tableau(b)
    @test tableau(¬a)
    @test tableau(a ∧ b)
    @test tableau(a ∨ b)
    @test tableau(a → b)
    @test tableau(a ⟷ b)
    
    # multiple premises, still trivially true
    @test tableau([a, b])
    @test tableau(a, b)  # alternate preferable syntax
    @test tableau(a → b, a, b)

    # some contradictory premises should yield false
    @test !tableau(a, ¬a)
    @test !tableau(a ∧ b, ¬a)
    @test !tableau(a → b, a, ¬b)
    @test !tableau(a ⟷ b, ¬a, b)
    @test !tableau(a ∧ b ∨ c, ¬c, ¬a)
    @test !tableau(a → b, b → c, c → d, a, ¬d)
end

@testset "Assertion Proofs" begin
    @testset "Rule Combinations" begin
        @symbols a b c d
        @symbols p q

        conjunction = rule_by_name(PropositionalCalculus, "Conjunction")
        premises1 = Set{AbstractExpression}([a, b])
        premises2 = Set{AbstractExpression}([a, b, c])
        premises3 = Set{AbstractExpression}([a, b, c, d])
        
        @test rule_combinations(conjunction, premises1) == Set([
            Deductive.SymbolMap(p => a, q => a),
            Deductive.SymbolMap(p => a, q => b),
            Deductive.SymbolMap(p => b, q => a),
            Deductive.SymbolMap(p => b, q => b),
        ])
        @test rule_combinations(conjunction, premises2) == Set([
            Deductive.SymbolMap(p => a, q => a),
            Deductive.SymbolMap(p => a, q => b),
            Deductive.SymbolMap(p => a, q => c),
            Deductive.SymbolMap(p => b, q => a),
            Deductive.SymbolMap(p => b, q => b),
            Deductive.SymbolMap(p => b, q => c),
            Deductive.SymbolMap(p => c, q => a),
            Deductive.SymbolMap(p => c, q => b),
            Deductive.SymbolMap(p => c, q => c)
        ])
        @test length(rule_combinations(conjunction, premises3)) == 16
        #  lol did u really think I'd write out all 16 combinations 🤣🤣🤣

        modus_ponens = rule_by_name(PropositionalCalculus, "Modus Ponens")
        premises4 = Set{AbstractExpression}([
            a → b,
            a
        ])
        premises5 = Set{AbstractExpression}([
            a → b,
            (a → b) → c
        ])

        @test rule_combinations(modus_ponens, premises4) == Set([
            Deductive.SymbolMap(p => a, q => b)
        ])
        @test rule_combinations(modus_ponens, premises5) == Set([
            Deductive.SymbolMap(p => a → b, q => c)
        ])

        double_negation = rule_by_name(PropositionalCalculus, "Double Negation Introduction")
        premises6 = Set{AbstractExpression}([
            a,
            b,
            a ∧ b
        ])

        @test rule_combinations(double_negation, premises6) == Set([
            Deductive.SymbolMap(p => a),
            Deductive.SymbolMap(p => b),
            Deductive.SymbolMap(p => a ∧ b)
        ])
    end
end

# @testset "Predicate Proofs" begin
#     a, b = LogicalSymbol.([:a, :b])
#     x, y, z = FreeVariable.([:x, :y, :z])
#     P, Q = Predicate.([:P, :Q])

#     # test cases taken from https://www.esf.kfi.zcu.cz/logika/opory/ia008/tableau_pred-sol.pdf

#     ex_a = Ā(x, P(x)) ⟷ ¬Ē(x, ¬P(x))
#     @test !tableau(¬ex_a)
    
#     ex_b = Ā(x, P(x) → Q(x)) → (Ā(x, P(x)) → Ā(x, Q(x)))
#     @test !tableau(¬ex_b)

#     ex_c = Ā(x, P(x) ∧ Q(x)) ⟷ (Ā(x, P(x)) ∧ Ā(x, Q(x)))
#     @test !tableau(¬ex_c)

#     # support for multiple free variables later...
#     # ex_d = Ē(y, Ā(x, P(x, y) ⟷ P(x, x))) → ¬Ā(x, Ē(y, Ā(z, P(z, y) ⟷ P(z, x))))
#     # @test !tableau(¬ex_d)
# end
