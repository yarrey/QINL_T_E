function [ DATAOUT ] = ChannelEqualization( CFG , DATA , Channel_H )
% ChannelEqualization 
% QYL 20171208
% 
% CFG.NCellID = 412; %cellID
% CFG.RB_START = 32;
% CFG.RB_LEN   = 36;
% CFG.ChannelEstimationSymbol = [0,4,7,11]; %参与信道估计的符号
% CFG.ZERO_PADING_COUNT = 32; %时域降噪置零长度
% DATA.data0 ; %复数数据 1200*14
% DATA.data1 ; %复数数据 1200*14
% Channel_H ; %复数数据 1200*4
% 
% DATAOUT ; %复数数据
% 
% [ DATAOUT ] = ChannelEqualization( CFG ,  DATA , Channel_H )
% 

%% eNB.PRBSet
    RB_START = CFG.PRBSet(1);
    RB_LEN   = CFG.PRBSet(end) - RB_START + 1;

    [H_Pos_RS ,H_POS_nRS] = GEN_H_POS(CFG.NCellID,RB_START,RB_LEN);
    [~ ,H_POS_nRS_1] = GEN_H_POS(CFG.NCellID,RB_START,47-RB_START);
    [~ ,H_POS_nRS_2] = GEN_H_POS(CFG.NCellID,53,RB_START+RB_LEN-53);
    H_POS_nRS_3 = [H_POS_nRS_1,H_POS_nRS_2];
    
    data_type_a = zeros(1,length(H_Pos_RS)*2);
    data_type_b = zeros(1,length(H_POS_nRS)*2);   
    data_type_c = zeros(1,length(H_POS_nRS_3)*2);
    
    data_ofdm_fs_ts_H = {data_type_a;data_type_b;data_type_b;data_type_b;data_type_a;data_type_b;data_type_b;data_type_a;data_type_b;data_type_b;data_type_b;data_type_a;data_type_b;data_type_b};

    % 含RS

    H_00 = (Channel_H(H_Pos_RS(1,:),1) + Channel_H(H_Pos_RS(2,:),1))/2;
    H_10 = (Channel_H(H_Pos_RS(2,:),2) + Channel_H(H_Pos_RS(1,:),2))/2;
    H_01 = (Channel_H(H_Pos_RS(1,:),3) + Channel_H(H_Pos_RS(2,:),3))/2;
    H_11 = (Channel_H(H_Pos_RS(2,:),4) + Channel_H(H_Pos_RS(1,:),4))/2;


    H_ABSSUM = abs(H_00).^2 + abs(H_10).^2 + abs(H_01).^2 + abs(H_11).^2;
    for i = [1,5,8,12]
        R_00 = DATA.data0(H_Pos_RS(1,:),i);
        R_10 = DATA.data0(H_Pos_RS(2,:),i);
        R_01 = DATA.data1(H_Pos_RS(1,:),i);
        R_11 = DATA.data1(H_Pos_RS(2,:),i);

        RR = ([R_00,conj(R_10),R_01,conj(R_11)]).';

        for n = 1:1:length(H_00)
            HH = [H_00(n) ,-H_10(n) ; conj(H_10(n)) , conj(H_00(n)) ; H_01(n) , -H_11(n) ; conj(H_11(n)) , conj(H_01(n))];
            W_H = HH'./ H_ABSSUM(n) ;
            data_ofdm_fs_ts_H{i}(n*2-1) = W_H(1,:) * RR(:,n);
            data_ofdm_fs_ts_H{i}(n*2)   = conj(W_H(2,:) * RR(:,n));
        end
    end


    % 不含RS

    H_00 = (Channel_H(H_POS_nRS(1,:),1) + Channel_H(H_POS_nRS(2,:),1))/2;
    H_10 = (Channel_H(H_POS_nRS(2,:),2) + Channel_H(H_POS_nRS(1,:),2))/2;
    H_01 = (Channel_H(H_POS_nRS(1,:),3) + Channel_H(H_POS_nRS(2,:),3))/2;
    H_11 = (Channel_H(H_POS_nRS(2,:),4) + Channel_H(H_POS_nRS(1,:),4))/2;

    H_ABSSUM = abs(H_00).^2 + abs(H_10).^2 + abs(H_01).^2 + abs(H_11).^2;
    for i = [2,3,4,6,7,9,10,11,13,14]
        R_00 = DATA.data0(H_POS_nRS(1,:),i);
        R_10 = DATA.data0(H_POS_nRS(2,:),i);
        R_01 = DATA.data1(H_POS_nRS(1,:),i);
        R_11 = DATA.data1(H_POS_nRS(2,:),i);

        RR = ([R_00,conj(R_10),R_01,conj(R_11)]).';
        for n = 1:1:length(H_00)
            HH = [H_00(n) ,-H_10(n) ; conj(H_10(n)) , conj(H_00(n)) ; H_01(n) , -H_11(n) ; conj(H_11(n)) , conj(H_01(n))];
            W_H = HH'./ H_ABSSUM(n) ;
            data_ofdm_fs_ts_H{i}(n*2-1) = W_H(1,:) * RR(:,n);
            data_ofdm_fs_ts_H{i}(n*2)   = conj(W_H(2,:) * RR(:,n));
        end
    end

    % 特殊

%     H_00 = (Channel_H(H_POS_nRS_3(1,:),1) + Channel_H(H_POS_nRS_3(2,:),1))/2;
%     H_10 = (Channel_H(H_POS_nRS_3(2,:),2) + Channel_H(H_POS_nRS_3(1,:),2))/2;
%     H_01 = (Channel_H(H_POS_nRS_3(1,:),3) + Channel_H(H_POS_nRS_3(2,:),3))/2;
%     H_11 = (Channel_H(H_POS_nRS_3(2,:),4) + Channel_H(H_POS_nRS_3(1,:),4))/2;
% 
%     H_ABSSUM = abs(H_00).^2 + abs(H_10).^2 + abs(H_01).^2 + abs(H_11).^2;
%     for i = 3
%         R_00 = DATA.data0(H_POS_nRS_3(1,:),i);
%         R_10 = DATA.data0(H_POS_nRS_3(2,:),i);
%         R_01 = DATA.data1(H_POS_nRS_3(1,:),i);
%         R_11 = DATA.data1(H_POS_nRS_3(2,:),i);
% 
%         RR = ([R_00,conj(R_10),R_01,conj(R_11)]).';
%         for n = 1:1:length(H_00)
%             HH = [H_00(n) ,-H_10(n) ; conj(H_10(n)) , conj(H_00(n)) ; H_01(n) , -H_11(n) ; conj(H_11(n)) , conj(H_01(n))];
%             W_H = HH'./ H_ABSSUM(n) ;
%             data_ofdm_fs_ts_H{i}(n*2-1) = W_H(1,:) * RR(:,n);
%             data_ofdm_fs_ts_H{i}(n*2)   = conj(W_H(2,:) * RR(:,n));
%         end
%     end

    DATAOUT = [data_ofdm_fs_ts_H{3:1:14}];
end

