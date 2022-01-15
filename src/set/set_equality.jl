export classify_matches, set_matches

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
function classify_matches(matches::Dict{LogicalSymbol, Vector{AbstractExpression}})
    match_lengths = length.(collect(values(matches)))
    if any(match_lengths .== 0)
        return NO_MATCHES
    end
    if all(match_lengths .== 1)
        return EXACT_MATCH
    end
    return PARTIAL_MATCH
end
function set_matches(pattern::ExtensionalSet, haystack::ExtensionalSet)
    unreduced_matches = set_matches_unreduced(pattern, haystack)

    # TODO: consider this scenario:
    # a = [1, 2]
    # b = [1, 2]
    # c = [1, 2, 3]
    # We cannot make any conclusions about a or b, but we _can_ conclude that c must not be either 1 or 2, considering
    # if it was the problem would become unsatisfiable between a and b. This kind of higher-order logical resolution
    # probably will require a neat algorithm of its own, which constitutes this problem as another issue (#21).

    continue_running = true

    completed_symbols = Set{LogicalSymbol}()
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
                        deleteat!(unreduced_matches[sym2], findall(x->x==ideal_match, unreduced_matches[sym2]))
                    end
                end

                continue_running = true
            end
        end
    end

    unreduced_matches  # but now its reduced from the while loop :)
end
function set_matches_unreduced(pattern::ExtensionalSet, haystack::ExtensionalSet)
    matching_leaves = Dict{LogicalSymbol, Vector{AbstractExpression}}(sym => [] for sym ∈ variables(pattern))
    set_matches_unreduced!(pattern, haystack; matching_leaves)
    matching_leaves
end
# NOTE: This function's `matching_symbols` kwarg REQUIRES all variables(pattern) to be defined as [] initially!!!
function set_matches_unreduced!(pattern::ExtensionalSet, haystack::ExtensionalSet; matching_leaves)
    matching_subpatterns = Dict(sub => [] for sub ∈ elements(pattern))

    if cardinality(pattern) != cardinality(haystack)
        return Dict()
    end

    if pattern == ∅ && haystack == ∅
        return Dict(pattern => haystack)
    end

    for subpattern ∈ elements(pattern)
        submatches = [haystack_el => set_matches_unreduced!(subpattern, haystack_el; matching_leaves) for haystack_el ∈ elements(haystack)]
        matching_elements = map(x -> x.first, filter(x -> length(x.second) > 0, submatches))
        for matching_el ∈ matching_elements
            push!(matching_subpatterns[subpattern], matching_el)
        end
    end

    # if ∅ has matches, remove ∅ from other potential matched symbols
    if haskey(matching_subpatterns, ∅) && length(matching_subpatterns[∅]) > 0
        for (subpatt, opts) ∈ matching_subpatterns
            if ∅ ∈ opts && subpatt != ∅
                deleteat!(opts, findall(x->x==∅, opts))
            end
        end
    end

    # remove the associated physical match from potential variable options
    if any((x->(x isa ExtensionalSet)).(collect(keys(matching_subpatterns))))
        for (subpatt, opts) ∈ matching_subpatterns
            if subpatt isa LogicalSymbol
                physical_matches = filter(x->(x isa ExtensionalSet), collect(keys(matching_subpatterns)))
                deleteat!(matching_leaves[subpatt], findall(x->(x ∈ physical_matches), matching_leaves[subpatt]))
            end
        end
    end

    @info matching_subpatterns

    matching_subpatterns
end
function set_matches_unreduced!(sym::LogicalSymbol, haystack::ExtensionalSet; matching_leaves)
    push!(matching_leaves[sym], haystack)
    Dict(sym => haystack)
end
