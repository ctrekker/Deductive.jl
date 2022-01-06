export prove_inclusion, set_includes


# TODO: check es for LogicalSymbols
evaluate(es::ExtensionalSet, ::Dict{LogicalSymbol, Bool}) = es
evaluate(is::IntensionalSet, ::Dict{LogicalSymbol, Bool}) = is

set_includes(es::ExtensionalSet{T}, sub::T) where {T} = sub ∈ elements(es)
function set_includes(sub::T, is::IntensionalSet) where {T <: AbstractExpression}
    pattern_matches = Dict{LogicalSymbol, AbstractExpression}()
    if !find_matches!(sub, transform(is), pattern_matches)
        return false
    end

    @info pattern_matches
    # evaluate(rule(is), pattern_matches)
end


function prove_inclusion(expr::LogicalExpression, substitution::Pair{LogicalSymbol, T}) where {T}
    target_set = right(expr)

    if operation(expr) != set_in || !(target_set isa MathematicalSet) || !(left(expr) isa LogicalSymbol)
        throw(ErrorException("Expression is not a set inclusion statement"))
    end

    if left(expr) != substitution.first
        throw(ErrorException("Substituted symbol and inclusion symbol are different ($(left(expr)) ≠ $(substitution.first))"))
    end

    
    set_includes(target_set, substitution.second)
end
