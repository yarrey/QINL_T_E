function [ DATAOUT ] = DeICI( CFG , DATA , varargin )
% DeICI 
% QYL 20171208
% 
% CFG.DeICI = 2; %邻区数量 
% CFG.DeICI_PCI = [411,413]; %邻区pci
% CFG.DeICI_Symbol = [4,7]; %符号位
% DATA.data0 ; %复数数据 1200*14
% DATA.data1 ; %复数数据 1200*14
% Channel_H1 ; %复数数据 1200*4
% 
% DATAOUT ; %与DATA相同
% 
% [ DATAOUT ] = DeICI( CFG , DATA , Channel_H1 , Channel_H2 ... )
% 

%%
    if CFG.DeICI == 0
        DATAOUT = DATA;
    else
        DATA_R = DATA;
        for i = 1:1:CFG.DeICI
            RS_0 = GEN_RS(CFG.DeICI_PCI(i),CFG.NDLRB,CFG.NSubframe * 2 + 0,0);
            RS_4 = GEN_RS(CFG.DeICI_PCI(i),CFG.NDLRB,CFG.NSubframe * 2 + 0,4);
            RS_7 = GEN_RS(CFG.DeICI_PCI(i),CFG.NDLRB,CFG.NSubframe * 2 + 1,0);
            RS_b = GEN_RS(CFG.DeICI_PCI(i),CFG.NDLRB,CFG.NSubframe * 2 + 1,4);

            RS_POS_0 = GEN_RS_POS(CFG.DeICI_PCI(i),CFG.NDLRB,0);
            RS_POS_4 = GEN_RS_POS(CFG.DeICI_PCI(i),CFG.NDLRB,1);
            
            if ismember(0,CFG.DeICI_Symbol)
                DATA_R.data0(RS_POS_0,1)  = DATA_R.data0(RS_POS_0,1)  - varargin{i}(RS_POS_0,1) .* RS_0.';
                DATA_R.data0(RS_POS_4,1)  = DATA_R.data0(RS_POS_4,1)  - varargin{i}(RS_POS_4,2) .* RS_0.';
                DATA_R.data1(RS_POS_0,1)  = DATA_R.data1(RS_POS_0,1)  - varargin{i}(RS_POS_0,3) .* RS_0.';
                DATA_R.data1(RS_POS_4,1)  = DATA_R.data1(RS_POS_4,1)  - varargin{i}(RS_POS_4,4) .* RS_0.';
            end
            if ismember(4,CFG.DeICI_Symbol)
                DATA_R.data0(RS_POS_4,5)  = DATA_R.data0(RS_POS_4,5) - varargin{i}(RS_POS_4,1) .* RS_4.';
                DATA_R.data0(RS_POS_0,5)  = DATA_R.data0(RS_POS_0,5) - varargin{i}(RS_POS_0,2) .* RS_4.';
                DATA_R.data1(RS_POS_4,5)  = DATA_R.data1(RS_POS_4,5) - varargin{i}(RS_POS_4,3) .* RS_4.';
                DATA_R.data1(RS_POS_0,5)  = DATA_R.data1(RS_POS_0,5) - varargin{i}(RS_POS_0,4) .* RS_4.';
            end
            if ismember(7,CFG.DeICI_Symbol)
                DATA_R.data0(RS_POS_0,8)  = DATA_R.data0(RS_POS_0,8) - varargin{i}(RS_POS_0,1) .* RS_7.';
                DATA_R.data0(RS_POS_4,8)  = DATA_R.data0(RS_POS_4,8) - varargin{i}(RS_POS_4,2) .* RS_7.';
                DATA_R.data1(RS_POS_0,8)  = DATA_R.data1(RS_POS_0,8) - varargin{i}(RS_POS_0,3) .* RS_7.';
                DATA_R.data1(RS_POS_4,8)  = DATA_R.data1(RS_POS_4,8) - varargin{i}(RS_POS_4,4) .* RS_7.';
            end
            if ismember(11,CFG.DeICI_Symbol)
                DATA_R.data0(RS_POS_4,12) = DATA_R.data0(RS_POS_4,12) - varargin{i}(RS_POS_4,1) .* RS_b.';
                DATA_R.data0(RS_POS_0,12) = DATA_R.data0(RS_POS_0,12) - varargin{i}(RS_POS_0,2) .* RS_b.';  
                DATA_R.data1(RS_POS_4,12) = DATA_R.data1(RS_POS_4,12) - varargin{i}(RS_POS_4,3) .* RS_b.';
                DATA_R.data1(RS_POS_0,12) = DATA_R.data1(RS_POS_0,12) - varargin{i}(RS_POS_0,4) .* RS_b.';
            end
        end
        DATAOUT = DATA_R;    
    end
end

