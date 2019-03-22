module compress
import RawArray
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

function compress_pipeline(data, folder::AbstractString, nbits=8)
    """
    Run the delta coding compression pipeline and store all
    resulting files in `folder`. Call bzip2 on the resulting folder.
    """
    mkdir(folder)
    delta_path = string(folder, "/", "deltas")
    outlier_path = string(folder, "/", "outliers")

    (delta, outliers, meta) = compress.naive_delta_code(data; nbits=nbits)
    RawArray.rawrite(delta, delta_path, compress=true)
    write_dictionary(outlier_path, outliers)

    for file in readdir(folder)
        filepath = string(folder, "/", file)
        run(`bzip2 -k -7 $filepath`)
    end
end

function naive_delta_code(data; nbits=8, verbose=false)
    # Flatten data
    n_streams, n_samples = size(data)

    stream = reshape(permutedims(data, (2, 1)), n_streams*n_samples)
    len_str = length(stream)
    
    # Difference data along each row
    diff_str = diff(stream)

    # Setup output
    delta = BitArray(undef, nbits*len_str)
    outliers = Dict(1 => stream[1])
    meta = Meta(nbits, (n_streams, n_samples))
    

    diff_min, diff_max = get_bin_size(nbits)
    count = 0
    for i = 2:len_str
        val = stream[i] - stream[i-1]
        if (verbose && i % 100_000_000 == 0)
            println("100 million values encoded")
        end

        if (val <= diff_max && val >= diff_min)
            # Small delta
            bit_rep = int_to_bit(val, diff_min, nbits)
            delta[count+1 : count+nbits] = bit_rep
            count += nbits

        else
            # Big delta
            outliers[i] = stream[i]
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

    # Reshape row-wise
    data = reshape(out, T, N)
    data = permutedims(data, (2, 1))
    return data
end

function write_dictionary(path::AbstractString, outliers::Dict)
"""
We don't want to write the dictionary to disk directly because
storing the hash table is unnecessary overhead.
Instead, we'll write the dictionary to disk as 2 separate arrays, 
one with the list of indexes, and the other with the corresponding values.
This trades search time for storage space.
"""
inds = UInt32.([keys(outliers)...])
vals = Int16.([outliers[key] for key in keys(outliers)])
inds_path = string(path, "_inds.raw")
vals_path = string(path, "_vals.raw")
RawArray.rawrite(inds, inds_path, compress=true)
RawArray.rawrite(vals, vals_path, compress=true)
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
