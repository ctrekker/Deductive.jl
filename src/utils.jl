flat_repeat(x, n) = Iterators.repeat([x], n)

function subscript_number(n::Int)
    sub_dict = Dict(
        '0' => '₀',
        '1' => '₁',
        '2' => '₂',
        '3' => '₃',
        '4' => '₄',
        '5' => '₅',
        '6' => '₆',
        '7' => '₇',
        '8' => '₈',
        '9' => '₉'
    )
    str_n = string(n)
    join([sub_dict[c] for c ∈ str_n])
end

truncate(arr::Vector, maxlen::Int) = arr[1:min(maxlen, length(arr))]
