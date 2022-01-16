function constrained_output_elimination(f_map::Dict{A, Set{B}}) where {A, B}
	copied_f_map = copy(f_map)
	constrained_output_elimination!(copied_f_map)
	copied_f_map
end

function constrained_output_elimination!(f_map::Dict{A, Set{B}}) where {A, B}
	f_pairs = collect(f_map)
	mapped_length = x->length(x.second)
	sort!(f_pairs; by=mapped_length)

	i = 1
	while i <= length(f_pairs)
		f_pair = f_pairs[i]
		potential_fully_connected = f_pairs[searchsorted(f_pairs, f_pair; by=mapped_length)]
		fully_connected = filter(potential_fully_connected) do p
			isequal(p.second, f_pair.second)			
		end

		if length(fully_connected) == mapped_length(f_pair)
			f_pair_remove_from = setdiff(f_pairs, fully_connected)
			for p ∈ f_pair_remove_from
				p_beforeremove = length(p.second)
				setdiff!(p.second, f_pair.second)
				if length(p.second) < p_beforeremove
					i = 1  # can possibly be changed to the lowest index with lowest length modified, but this is nontrivial to find (requires a search)
					sort!(f_pairs; by=mapped_length)
				end
			end
		elseif length(fully_connected) > mapped_length(f_pair)
			@warn "Contradiction in mapping. Ignoring..."
		end

		i += 1
	end
	
	nothing
end
