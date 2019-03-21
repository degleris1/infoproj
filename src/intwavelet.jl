


function int_haar_transform(signal)
    siglen = length(signal)

    # Catch base 2 error
    if (round(log2(siglen)) != log2(siglen))
        print("Need signal with length = 2^n")
        return
    end

    # Base case
    if (siglen == 1)
        return signal
    end

    # Recursive case
    out = zeros(siglen)
    
    # Step 1: break up into odd and even
    sigo = signal[1:2:end]
    sige = signal[2:2:end]

    # Step 2: generate differences
    diffs = sigo - sige
    out[1:Int(siglen/2)] = diffs

    # Step 3: generate and transform remainder (RECURSE)
    resid = sigo + round.(diffs / 2)
    out[Int(siglen/2+1):siglen] = int_haar_transform(resid)

    return Int.(out)
end


function inv_int_haar_transform(signal)
    siglen = length(signal)

    # Catch base 2 error
    if (round(log2(siglen)) != log2(siglen))
        print("Need signal with length = 2^n")
        return
    end

    out = zeros(siglen)
    
    # Base case
    if (siglen == 2)
        diff = signal[1]
        resid = signal[2]

        sigo = resid - round(diff / 2)
        sige = sigo - diff

        out[1] = sigo
        out[2] = sige
        
    # Recursive case
    else
        diff = signal[1:Int(siglen/2)]
        resid = inv_int_haar_transform(signal[Int(siglen/2+1):siglen])
    

        sigo = resid - round.(diff / 2)
        sige = sigo - diff

        out[1:2:end] = sigo
        out[2:2:end] = sige

    end
        
        
    return Int.(out)
end
