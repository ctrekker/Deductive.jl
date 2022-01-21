"""
    ProofLine(line::Int, statement::AbstractExpression, argument::A, references::Vector{ProofLine}) where {A}

Represents a single line in a step-by-step proof, made up by a statement, an argument, and a set of references necessary to
make the provided argument. A line number is also required to serve as a unique human-readable identifier for each line.
"""
struct ProofLine{A}
    linenum::Int
    statement::AbstractExpression
    argument::A
    references::Vector{ProofLine}
end
"""
    ProofLine(line::Int, statement::AbstractExpression, argument::A="N/A") where {A}

Creates a [`ProofLine`](@ref) without any references to other lines and without an argument. Implicitly this means in most proofs that
this line depends only on the previous one, but can also be taken to mean "is a conclusion of all statements above".
"""
function ProofLine(line::Int, statement::AbstractExpression, argument::A="N/A") where {A}
    ProofLine(line, statement, argument, ProofLine[])
end
"""
    ProofLine(line::Int, statement::AbstractExpression, argument::A, reference::ProofLine) where {A}

Convenience method. Creates a [`ProofLine`](@ref) with a single provided reference instead of a list of them.
"""
function ProofLine(line::Int, statement::AbstractExpression, argument::A, reference::ProofLine) where {A}
    ProofLine(line, statement, argument, [reference])
end
# in most cases this shouldn't get shown since we also override Base.show(::IO, ::Vector{ProofLine})
# put another way, this is the best we can print out a proof line without context from the proof itself
function Base.show(io::IO, line::ProofLine)
    print(io, line.linenum)
    print(io, "\t")
    print(io, replace(string(line.statement), "Deductive." => ""))
    print(io, "\t")
    print(io, line.argument)
    
    if length(line.references) > 0
        print(io, "\t")
        print(io, "(" * join([string(ref.linenum) for ref ∈ line.references], ", ") * ")")
    end
end

function find_proof_line_by_statement(proof::Vector{ProofLine}, statement::AbstractExpression)
    for line ∈ proof
        if isequal(line.statement, statement)
            return line
        end
    end

    nothing
end


function Base.show(io::IO, m::MIME"text/plain", proof::Vector{ProofLine})
    proof_table = DataFrame("Line Number" => Int[], "Statement" => String[], "Argument" => String[], "References" => String[])

    for line ∈ proof
        push!(proof_table, Dict(
            "Line Number" => line.linenum,
            "Statement" => replace(string(line.statement), "Deductive." => ""),
            "Argument" => line.argument,
            "References" => join([string(ref.linenum) for ref ∈ line.references], ", ")
        ))
    end

    # display_size=(-1, -1) forces pretty_table to print all rows and columns regardless of screen size
    pretty_table(io, proof_table; display_size=(-1, -1))
end
