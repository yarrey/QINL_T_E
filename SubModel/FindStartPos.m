function [ REAL_POS ] = FindStartPos( eNB )
%FINDSTARTPOS 此处显示有关此函数的摘要
%   此处显示详细说明

%% 基本参数
PCI = eNB.NCellID;
RBs = eNB.NDLRB;
NSF = 0; %子帧号

RS_0 = GEN_RS(PCI,RBs,NSF * 2 + 0,0);
RS_4 = GEN_RS(PCI,RBs,NSF * 2 + 0,4);
RS_7 = GEN_RS(PCI,RBs,NSF * 2 + 1,0);
RS_b = GEN_RS(PCI,RBs,NSF * 2 + 1,4);

RS_POS_0 = GEN_RS_POS(PCI,RBs,0);
RS_POS_4 = GEN_RS_POS(PCI,RBs,1);

%% 扫帧头

SP_MAX = 307200;
% START_POS = 112838 - 160 + 307200*NF + 30720*NSF;
START_POS = 0;
pos_en_0 = zeros(1,SP_MAX);
pos_en_1 = zeros(1,SP_MAX);
%扫帧头
for n = 1 : 1 : SP_MAX    
    DATA_POS = START_POS+n :1 : START_POS+n+2048-1;
    data = eNB.Source.data0(DATA_POS);

    %解OFDM    
    data_fft_r = fft(data,2048);
    data_ofdm = [data_fft_r(2048-600+1:2048);data_fft_r(2:601)];

    %RS相关
    rs_en_r = conj(RS_0) * data_ofdm(RS_POS_0);
    pos_en_0(n) = abs(rs_en_r)^2;
    
    rs_en_r = conj(RS_0) * data_ofdm(RS_POS_4);
    pos_en_1(n) = abs(rs_en_r)^2;    
end

pos_en_sum = pos_en_0 + pos_en_1;
[~,REAL_POS] = max(pos_en_sum);




end

