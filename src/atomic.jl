export ⊼, atomize

"""
    a ⊼ b

Not AND operator (NAND for short). The NAND operator is a functionally complete boolean operator, meaning all other boolean
operations can be expressed with only NAND operations.
"""
⊼ = LogicalOperation((x, y) -> !(x && y), :⊼, 2, true, true)

"""
    atomize(expr::AbstractExpression)

Converts an expression into its directly converted NAND-only form.
"""
# Reduce an expression to its atomic form using the NAND operation
function atomize(expr::LogicalExpression)
    parts = atomize.(arguments(expr))
    expr_op = operation(expr)
    
    if expr_op == ¬
        return parts[1] ⊼ parts[1]
    elseif expr_op == ∧
        return atomize(¬(parts[1] ⊼ parts[2]))
    elseif expr_op == ∨
        return atomize(¬parts[1] ⊼ ¬parts[2])
    elseif expr_op == →
        return atomize(¬parts[1] ∨ parts[2])
    elseif expr_op == ⟷
        return atomize((parts[1] ∧ parts[2]) ∨ (¬parts[1] ∧ ¬parts[2]))
    elseif expr_op == ⊼
        return atomize(parts[1]) ⊼ atomize(parts[2])
    end

    throw(ErrorException("Expression contains unsupported atomic operator $(expr_op)"))
end
atomize(s::LogicalSymbol) = s
