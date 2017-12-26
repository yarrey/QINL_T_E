function pn_seq = gen_pn_seq(C_init)
    pn_seq = zeros(1,9999);
    x1 = zeros(1,99999);
    x2 = zeros(1,99999);
    
    %initial and generate x1
    x1(1) = 1;
    for n = 0:1:(length(x1) - 32)
        x1(n + 31 + 1) = mod((x1(n + 3 + 1) + x1(n + 1)),2);
    end    
    
    %initial and generate x2
    temp_str = dec2bin(C_init,31);
    for n = 0:1:30
        x2(n + 1) = str2num(temp_str(31 - n));
    end
    
    for n = 0:1:(length(x2) - 32)
        x2(n + 31 + 1) = mod((x2(n + 3 + 1) + x2(n + 2 + 1) + x2(n + 1 + 1) + x2(n + 1)),2);
    end
    
    %generate pn_seq
    Nc = 1600;
    for n = 0:1:9998
        pn_seq(n + 1) = mod((x1(Nc + n + 1) + x2(Nc + n + 1)),2);
    end
end