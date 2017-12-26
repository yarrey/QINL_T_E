function RS = GEN_RS(PCI,RBs,Ns,L)
    RS = zeros(1,RBs * 2);
    
    %generate CELL-RS sequence
    Cinit = 1024 * ((7 * (Ns + 1)) + L + 1) * (2 * PCI + 1) + 2 * PCI + 1;
    
    C = gen_pn_seq(Cinit);
    
    C_Pos = 1 - 2 * C;
    C_Pos = C_Pos / (2 ^ 0.5);
    
    RS_= C_Pos(1:2:440) + C_Pos(2:2:440) * 1i;
    RS(1,:) = RS_(110 + 1 - RBs:110 + 1 + RBs - 1);
end