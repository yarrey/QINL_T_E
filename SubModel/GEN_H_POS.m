function [ H_Pos_RS,H_POS_nRS ] = GEN_H_POS( PCI,RBstart,RBlen )
% GEN_H_POS 
% QYL
% lte Ä£ÐÍ
% 20171208
%   [ H_Pos_RS,H_POS_nRS ] = GEN_H_POS( PCI,RBstart,RBlen )
    H_Pos_RS = zeros(2,RBlen * 4);
    H_POS_nRS = zeros(2,RBlen * 6);
    
    vp0 = 0;
%     vp1 = 3;    
    v_shift   = mod(PCI,6);    
    rs_shift0 = mod((vp0 + v_shift),6);
%     rs_shift1 = mod((vp1 + v_shift),6);
 
    if(rs_shift0 == 0)
		dpos_0 = 1;
		dpos_1 = 2;
    elseif(rs_shift0 == 1)
		dpos_0 = 0;
		dpos_1 = 2;
    elseif(rs_shift0 == 2)
		dpos_0 = 0;
		dpos_1 = 1;
    elseif(rs_shift0 == 3)
		dpos_0 = 1;
		dpos_1 = 2;
    elseif(rs_shift0 == 4)
		dpos_0 = 0;
		dpos_1 = 2;
    elseif(rs_shift0 == 5)
		dpos_0 = 0;
		dpos_1 = 1;
    end
    
    H_Pos_RS(1,:) = dpos_0+RBstart*12:3:dpos_0+RBstart*12+RBlen*12-1-dpos_0;
    H_Pos_RS(2,:) = dpos_1+RBstart*12:3:dpos_1+RBstart*12+RBlen*12-1-dpos_1;
    
    H_Pos_RS = H_Pos_RS +1;
    
    H_POS_nRS(1,:) = 1+RBstart*12:2:RBstart*12+RBlen*12;
    H_POS_nRS(2,:) = 2+RBstart*12:2:RBstart*12+RBlen*12;   

end

