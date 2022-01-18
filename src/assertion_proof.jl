# proof strategies:
#  direct
#  implication
#  contradiction

# "formalized" with given / goal table

export GivenGoal, given, goal


"""
    GivenGoal(given::Set{AbstractExpression}, goal::Set{AbstractExpression})

Initialize a structure representing a proof starting and ending point, with given and goal sets of expressions respectively. This
structure on its own isn't enough to conduct a proof, however. A proof requires both a `GivenGoal` and a logical calculus which
defines the allowed elementary operations on expressions. For example, if operating within propositional logic, see the 
PropositionalCalculus definition.
"""
struct GivenGoal
    given::Set{AbstractExpression}
    goal::Set{AbstractExpression}
end
GivenGoal(given::Vector{T}, goal::Vector{U}) where {T <: AbstractExpression, U <: AbstractExpression} = GivenGoal(Set(Vector{AbstractExpression}(given)), Set(Vector{AbstractExpression}(goal)))
given(gg::GivenGoal) = gg.given
goal(gg::GivenGoal) = gg.goal

function find_matches(gg::GivenGoal, rule::InferenceRule)
    matching_statements = Dict{AbstractExpression, Vector{AbstractExpression}}()

    for premise ∈ premises(rule)
        matching_statements[premise] = AbstractExpression[]

        for st ∈ given(gg)
            if matches(st, premise)
                push!(matching_statements[premise], st)
            end
        end
    end

    matching_statements
end

"""
    prove(gg::GivenGoal; calculus=PropositionalCalculus)

Prove a given-goal table using the specified logical calculus, which by default is [PropositionalCalculus](@ref).
"""
function prove(gg::GivenGoal; calculus=PropositionalCalculus)
    # naive iteration
    for rule ∈ calculus
        println(premises(rule) => conclusion(rule))
    end
end
