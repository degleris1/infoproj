module compress
export naive_delta_code
export decompress
export Meta

mutable struct Meta
    nbits::Int
    dims::Tuple
    function Meta(nbits, dims)
        return new(nbits, dims)
    end
end

function naive_delta_code(data; nbits=8, verbose=false)
    # Flatten data
    n_streams, n_samples = size(data)

    stream = reshape(data, n_streams*n_samples)
    len_str = length(stream)
    
    # Difference data along each row
    diff_str = diff(stream)

    # Setup output
    delta = BitArray(undef, nbits*len_str)
    outliers = Dict(1 => stream[1])
    meta = Meta(nbits, (n_streams, n_samples))
    

    diff_min, diff_max = get_bin_size(nbits)
    count = 0
    for i = 1:len_str
        val = stream[i]
        if (verbose && i % 100_000_000 == 0)
            println("100 million rows encoded")
        end

        if (val <= diff_max && val >= diff_min)
            # Small delta
            bit_rep = int_to_bit(val, diff_min, nbits)
            delta[count+1 : count+nbits] = bit_rep
            count += nbits

        else
            # Big delta
            outliers[i+1] = val
        end
    end

    return delta[1:count], outliers, meta
end

function decompress(deltas::AbstractArray, outliers::Dict, meta::Meta; dtype=Int16)
    (N, T) = meta.dims
    nbits = meta.nbits
    diff_min, diff_max = get_bin_size(nbits)
    out = zeros(N*T)

    # Start should always be in the dictionary
    out[1] = outliers[1]

    bit_ind = 1
    for i in 2:N*T
        if haskey(outliers, i)
            out[i] = outliers[i]
        else
            diff = deltas[bit_ind:bit_ind+nbits-1]
            new_val = out[i-1] + bit_to_int(diff, diff_min)
            out[i] = new_val
            bit_ind += nbits
        end
    end

    # Reshape to matrix
    out = reshape(out, N, T)
    return out
end


"""
Get the minimum and maximum integer size for a given number of bits.
"""
function get_bin_size(nbits)
    diff_min = 0 - 2 ^ (nbits - 1)
    diff_max = 2 ^ (nbits - 1) - 1

    return Int16(diff_min), Int16(diff_max)
end


"""
Convert a string of ones and zeros to an array of booleans.
"""
function int_to_bit(val, diff_min, nbits)
    offset_val = val - diff_min
    binary_rep = bitstring(Int16(offset_val))

    return BitArray(c == '1' for c in binary_rep[16+1-nbits:16])
end

function bit_to_int(arr::Union{BitArray, BitVector}, diff_min; dtype=Int16)
    str = bitstring(arr)
    return parse(dtype, str; base=2) + diff_min
end

end #endmodule
