using PropositionalLogic

a, b = LogicalSymbol.([:a, :b])
st = a ∧ b ∧ ¬a
@info prove(st)
