using Latexify

@latexrecipe function f(sym::LogicalSymbol)
    return name(sym)
end

@latexrecipe function f(op::LogicalOperation)
    return name(op)
end

@latexrecipe function f(expr::LogicalExpression)
    env --> :eq

    opname = name(operation(expr))
    if isunary(operation(expr))
        return "$(opname)($(first(arguments(expr))))"
    end
    if isbinary(operation(expr))
        return "$(arguments(expr)[1]) $(opname) $(arguments(expr)[2])"
    end
end
