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
function set_matching(pattern::ExtensionalSet, haystack::ExtensionalSet)
    
end
function set_matching(sym::LogicalSymbol, haystack::ExtensionalSet)
    
end
