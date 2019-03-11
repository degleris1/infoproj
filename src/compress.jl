module compress
export naive_delta_code


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
    meta = Dict(
        :nbits => nbits,
        :dims => (n_streams, n_samples)
    )
    

    diff_min, diff_max = get_bin_size(nbits)
    count = 0
    for i = 1:len_str
        val = stream[i]
        if (verbose && i % 1_000_000 == 0)
            println("1 million rows encoded")
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

    return BitArray(c == '1' for c in binary_rep)
end

end #endmodule
