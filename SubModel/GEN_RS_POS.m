function RS_POS = GEN_RS_POS(PCI,RBs,TxAnt)
    RS_POS = zeros(1,RBs * 2);
    
    vp0 = 0;
    vp1 = 3;
    
    v_shift   = mod(PCI,6);
    
    rs_shift0 = mod((vp0 + v_shift),6);
    rs_shift1 = mod((vp1 + v_shift),6);
    
    rs_pos_0 = rs_shift0:6:(RBs * 12 - 1);
    rs_pos_1 = rs_shift1:6:(RBs * 12 - 1);
    
    rs_pos_0 = rs_pos_0 + 1;
    rs_pos_1 = rs_pos_1 + 1;
    
    rs_pos_0 = reshape(rs_pos_0,1,RBs * 2);
    rs_pos_1 = reshape(rs_pos_1,1,RBs * 2);
    
    if(TxAnt == 0)
        RS_POS = rs_pos_0;
    else
        RS_POS = rs_pos_1;
    end
end