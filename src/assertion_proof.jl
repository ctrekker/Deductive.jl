# proof strategies:
#  direct
#  implication
#  contradiction

# "formalized" with given / goal table

export GivenGoal, given, goal


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

function prove(gg::GivenGoal; calculus=PropositionalCalculus)
    # naive iteration
    for rule ∈ calculus
        println(find_matches(gg, rule))
    end
end
