export search


abstract type AbstractDeductiveIndex end
abstract type AbstractDeductiveIndexTable end

"""
    Index(table::T, identifier_map::Dict{Int, E}) where {E, T}

Generic index container type which maps between index identifiers and associated values, as well as references the 
root table of the index. In a linear index the `table` field contains the only index table, but in recursive indices
this table is merely the root of the index where the search starts.
"""
mutable struct Index{E, T <: AbstractDeductiveIndexTable} <: AbstractDeductiveIndex
    table::T
    identifier_map::Dict{Int, E}
    current_id::Int

    Index(table::T, identifier_map::Dict{Int, E}) where {E, T} = new{E, T}(table, identifier_map, 1)
end
"""
    add!(idx::Index{E, T}, el::E) where {E, T}

Adds an element to an index, making it searchable.
"""
function add!(idx::Index{E, T}, el::E) where {E, T}
    el_id = idx.current_id
    idx.identifier_map[el_id] = el
    idx.current_id += 1
    add!(idx.table, (el_id, el))
end

"""
    search(idx::Index{E, T}, pattern::E) where {E, T}

Searches an index for a given pattern, which is not necessarily an exact match. This function merely passes the search call to
the root index table, so details with how pattern matching is handled will be clarified by the `search` function documentation
for a specific index table type.
"""
search(idx::Index{E, T}, pattern::E) where {E, T} = Set{E}([idx.identifier_map[id] for id ∈ search(idx.table, pattern)])
