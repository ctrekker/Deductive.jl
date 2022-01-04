export ⊼, atomize

⊼ = LogicalOperation((x, y) -> !(x && y), :⊼, 2, true, true)

# Reduce an expression to its atomic form using the NAND operation
atomize(s::LogicalSymbol) = s
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
