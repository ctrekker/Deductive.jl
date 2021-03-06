export classify_matches, set_matches, set_symbol_matches

# set equality is checked using a linear time tree isomorphism algorithm
#  https://logic.pdmi.ras.ru/~smal/files/smal_jass08.pdf


function lexicographic_sort!(strings::Vector{String})
    # TODO: implement linear time string sort from https://doc.lagout.org/science/0_Computer%20Science/2_Algorithms/The%20Design%20and%20Analysis%20of%20Computer%20Algorithms%20%5BAho,%20Hopcroft%20&%20Ullman%201974-01-11%5D.pdf page 90

    sort!(strings)
end

get_canonical_name(sym::LogicalSymbol) = "_"
function get_canonical_name(node::ExtensionalSet)
    if node == ∅
        return "10"
    end
    subnames = [get_canonical_name(child) for child ∈ elements(node)]
    lexicographic_sort!(subnames)
    string("1", join(subnames), "0")
end




# SET MATCHING
@enum MatchClassification EXACT_MATCH PARTIAL_MATCH NO_MATCHES
function classify_matches(matches::Dict{LogicalSymbol, Set{AbstractExpression}})
    match_lengths = length.(collect(values(matches)))
    if any(match_lengths .== 0)
        return NO_MATCHES
    end
    if all(match_lengths .== 1)
        return EXACT_MATCH
    end
    return PARTIAL_MATCH
end
function classify_matches(pattern::ExtensionalSet, haystack::ExtensionalSet)
    classify_matches(set_matches(pattern, haystack))
end

function reduce_matches!(unreduced_matches::Dict)
    # TODO: consider this scenario:
    # a = [1, 2]
    # b = [1, 2]
    # c = [1, 2, 3]
    # We cannot make any conclusions about a or b, but we _can_ conclude that c must not be either 1 or 2, considering
    # if it was the problem would become unsatisfiable between a and b. This kind of higher-order logical resolution
    # probably will require a neat algorithm of its own, which constitutes this problem as another issue (#21).

    continue_running = true

    completed_symbols = Set{AbstractExpression}()
    while continue_running
        continue_running = false
        for (sym, matches) ∈ unreduced_matches
            if length(matches) == 1 && sym ∉ completed_symbols
                ideal_match = first(matches)
                push!(completed_symbols, sym)
                # this could be simplified with a "graph inversion" but usually dictionary sizes are low so this doesn't cost too much
                # NOTE TO FUTURE ME: graph inversion might also be a clever way to solve #21 as well...
                for (sym2, matches2) ∈ unreduced_matches
                    if sym == sym2
                        continue
                    end
                    if ideal_match ∈ matches2
                        delete!(matches2, ideal_match)
                    end
                end

                continue_running = true
            end
        end
    end

    unreduced_matches  # but now its reduced from the while loop :)
end

# TODO: Move these elsewhere or switch fully to ExtensionalSet from Set
ES = Union{ExtensionalSet, Set}
elements(s::Set) = s
cardinality(s::Set) = length(s)
variables(s::Set) = cardinality(s) > 0 ? reduce(∪, variables.(collect(s))) : Set{LogicalSymbol}()

# TODO: fix the method signatures to be less messy
#  1. Reverse pattern and haystack to match up with other matching algorithm signatures
#  2. Make sure type specificity is as tight as possible to prevent contradictory type combinations from being valid inputs
function set_matches(pattern::ES, haystack::ES; reduce=true, strict=true)
    matching_subpatterns = Dict(sub => Set{AbstractExpression}() for sub ∈ elements(pattern))

    if strict && cardinality(pattern) != cardinality(haystack)
        return Dict()
    end

    if pattern == ∅ && haystack == ∅
        return Dict(pattern => haystack)
    end

    for subpattern ∈ elements(pattern)
        submatches = [haystack_el => set_matches(subpattern, haystack_el) for haystack_el ∈ elements(haystack)]
        matching_elements = map(x -> x.first, filter(x -> length(x.second) > 0, submatches))
        for matching_el ∈ matching_elements
            push!(matching_subpatterns[subpattern], matching_el)
        end
    end


    # PHYSICAL ROOT MATCHING
    # if ∅ has matches, remove ∅ from other potential matched symbols
    if haskey(matching_subpatterns, ∅) && length(matching_subpatterns[∅]) > 0
        for (subpatt, opts) ∈ matching_subpatterns
            if ∅ ∈ opts && subpatt != ∅
                deleteat!(opts, findall(x->x==∅, opts))
            end
        end
    end
    # END PHYSICAL ROOT MATCHING


    # we can perform naive simplification
    if any(length.(collect(values(matching_subpatterns))) .== 1)
        reduce_matches!(matching_subpatterns)
    end
    
    if reduce
        constrained_output_elimination!(matching_subpatterns)
    end

    matching_subpatterns
end
set_matches(sym::LogicalSymbol, haystack::Union{ES, AbstractExpression}; reduce=false) = Dict(sym => Set([haystack]))
# TODO: think about generalizing set_matches such that it integrates with `find_matches` since they fundamentally do something similar
function set_matches(pattern::LogicalExpression, haystack::AbstractExpression)
    expr_matches = Dict{LogicalSymbol, AbstractExpression}()
    if find_matches!(haystack, pattern, expr_matches)
        return Dict(k => Set([v]) for (k, v) ∈ expr_matches)
    end
    Dict()
end

function set_symbol_matches(pattern::Union{ES, LogicalSymbol}, haystack::ES; symbol_matches=nothing, reduce=true, strict=true)
    if isnothing(symbol_matches)
        symbol_matches = Dict{LogicalSymbol, Set{AbstractExpression}}(sym => Set{AbstractExpression}() for sym ∈ variables(pattern))
    end

    current_set_matches = set_matches(pattern, haystack; reduce=false)
    for (expr, matches) ∈ current_set_matches
        if expr isa LogicalSymbol
            union!(symbol_matches[expr], Set(matches))
        else
            set_symbol_matches.(flat_repeat(expr, length(matches)), matches; symbol_matches, reduce=false, strict=strict)
        end
    end

    if reduce
        constrained_output_elimination!(symbol_matches)
    end

    symbol_matches
end
function set_symbol_matches(pattern::LogicalExpression, haystack::AbstractExpression; symbol_matches=nothing, kwargs...)
    my_matches = set_matches(pattern, haystack)
    for (sym, matches) ∈ my_matches
        union!(symbol_matches[sym], matches)
    end
end
