import StatsBase


function n_order_hist(data, n)
    datalen = length(data)

    tuples = [Tuple(data[j] for j in i : i+n-1)
              for i in 1 : n : datalen-n+1]

    return StatsBase.countmap(tuples)
end

function compute_entropy(data; order=1)
    freqs = [v for v in values(n_order_hist(data, order))]
    return StatsBase.entropy(freqs / sum(freqs)) / order
end


# ---



function huffman_score_data(data, order, bits_per_val)
    return huffman_score_map(n_order_hist(data, order), order * bits_per_val)
end


function huffman_score_map(freqmap, codesize)
    freqs = sort(collect(values(freqmap)), rev=true)
    nbits = 0

    while (length(freqs) > 1)
        a = pop!(freqs)
        b = pop!(freqs)
        insert!(freqs, searchsortedfirst(freqs, a+b, rev=true), a+b)
        nbits += a+b
    end

    return (nbits + codesize * length(freqmap)) / freqs[1]
end
