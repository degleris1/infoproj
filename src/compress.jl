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

function bit_to_int(arr::Union{BitArray, BitVector})
    @assert(length(arr) <= 64) # won't work for sizes > 64 bit ints!
    reversed = arr.chunks[1]
    return revbits(reversed)
end

# Taken from:
# https://discourse.julialang.org/t/covert-bitarray-to-int64/9193/2
function revbits(z::UInt64)
    z = (((z & 0xaaaaaaaaaaaaaaaa) >>  1) | ((z & 0x5555555555555555) <<  1))
    z = (((z & 0xcccccccccccccccc) >>  2) | ((z & 0x3333333333333333) <<  2))
    z = (((z & 0xf0f0f0f0f0f0f0f0) >>  4) | ((z & 0x0f0f0f0f0f0f0f0f) <<  4))
    z = (((z & 0xff00ff00ff00ff00) >>  8) | ((z & 0x00ff00ff00ff00ff) <<  8))
    z = (((z & 0xffff0000ffff0000) >> 16) | ((z & 0x0000ffff0000ffff) << 16))
    z = (((z & 0xffffffff00000000) >> 32) | ((z & 0x00000000ffffffff) << 32))
    return z
end

end #endmodule
