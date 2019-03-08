module compress

export naive_delta_code
function naive_delta_code(data; NEW_ENTRY=Int8(-128),
                           DIFF_MIN=Int8(-127),
                           DIFF_MAX=Int8(127),
                           Verbose=false)

    n_streams, n_samples = size(data)

    # Difference data along each row
    diff_data = diff(data, dims=2)


    # Preallocate output
    delta = Array{Int8, 2}(undef, n_streams, n_samples)
    new_entries = Dict()

    for r = 1:n_streams
        if verbose
            println("Encoding row ", r)
        end
        # Delta code!

        # First column
        delta[r, 1] = NEW_ENTRY
        new_entries[(r, 1)] = data[r, 1]

        # Remaining columns
        for c = 2:n_samples
            val = diff_data[r, c-1]
            if (val <= DIFF_MAX && val >= DIFF_MIN)
                delta[r, c] = Int8(val)
            else
                delta[r, c] = NEW_ENTRY
                new_entries[(r, c)] = val
            end
        end
    end
    return (delta, new_entries)
end

end #endmodule
