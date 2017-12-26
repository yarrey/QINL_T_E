function [ DATA_SF ] = GetSubFrameSourceData( eNB  )
% GetSubFrameSourceData
% QYL 20171208
% 
% eNB.NCellID = 412; %cellID
% eNB.NDLRB = 100; %码块数量
% eNB.NFrame  = 37; %帧号
% eNB.NSubframe = 6; %子帧号
% eNB.StartPOS = 257818; %帧头位置
% eNB.SFPosOffsetCorrection = 0; %帧头纠正
% eNB.FrequencyOffsetCorrection = 0; %频偏纠正
% eNB.TimeOffsetCorrection = 0; %时偏纠正
% eNB.Fs = 30.72E6; %采样频率
% eNB.Source.data0 = data0; %复数数据
% eNB.Source.data1 = data1; %复数数据
% 
% DATA_SF ; %与eNB.Source相同
% 
% [ DATA_SF ] = GetSubFrameeNB.SourceData( eNB )
%  

%%
    RS_0 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 0,0);
    RS_4 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 0,4);
    RS_7 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 1,0);
    RS_b = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 1,4);

    RS_POS_0 = GEN_RS_POS(eNB.NCellID,eNB.NDLRB,0);
    RS_POS_4 = GEN_RS_POS(eNB.NCellID,eNB.NDLRB,1);

    %% SFPosOffsetCorrection
    START_POS = eNB.StartPOS - 160 + 307200*eNB.NFrame + 30720*eNB.NSubframe;
    if eNB.SFPosOffsetCorrection == 1 
        SP_MAX = 50;  
        pos_en = zeros(1,SP_MAX*2+1);
        %扫帧头
        for n = -SP_MAX : 1 : SP_MAX    
            DATA_POS = START_POS+n :1 : START_POS+n+30720-1;
            data1 = eNB.Source.data0(DATA_POS);
            data2 = eNB.Source.data1(DATA_POS);
            %解OFDM    
            data_ofdm1 = OFDM_Demodulation_Subframe(data1);
            data_ofdm2 = OFDM_Demodulation_Subframe(data2);
            %RS相关
            rs_en_r1 = conj(RS_0) * data_ofdm1(RS_POS_0,1);
            rs_en_r2 = conj(RS_0) * data_ofdm2(RS_POS_0,1);
            rs_en_r3 = conj(RS_0) * data_ofdm1(RS_POS_4,1);
            rs_en_r4 = conj(RS_0) * data_ofdm2(RS_POS_4,1);
            pos_en(n + SP_MAX + 1) = abs(rs_en_r1)^2 + abs(rs_en_r2)^2 + abs(rs_en_r3)^2 + abs(rs_en_r4)^2;
            pos_en_00(n + SP_MAX + 1) = abs(rs_en_r1)^2;
            pos_en_10(n + SP_MAX + 1) = abs(rs_en_r3)^2;
            pos_en_01(n + SP_MAX + 1) = abs(rs_en_r2)^2;
            pos_en_11(n + SP_MAX + 1) = abs(rs_en_r4)^2;
        end
        [~,REAL_POS_r] = max(pos_en);
        REAL_POS = REAL_POS_r - 1 - SP_MAX + START_POS;

    else
        REAL_POS = START_POS;
    end
    data_0 = eNB.Source.data0(REAL_POS:1:REAL_POS+30720-1);
    data_1 = eNB.Source.data1(REAL_POS:1:REAL_POS+30720-1);

    %% FrequencyOffsetCorrection


    if eNB.FrequencyOffsetCorrection == 1
        FS_MAX = 2000; %正负频偏范围
        rs_en = zeros(1,FS_MAX*2+1);
        T = 0:1:length(data_0)-1;
        Fs = eNB.Fs; %采样频率

        %获取频偏量
        for n = -FS_MAX : 1 : FS_MAX
            %加频偏
            F0 = n;
            data = data_0.' .* exp( 1i * 2 * pi * F0 * T / Fs );
            data = data.';

            %解OFDM    
            data_ofdm = OFDM_Demodulation_Subframe(data);

            %RS相关
            rs_en_r = conj(RS_0) * data_ofdm(RS_POS_0,1);
            rs_en(n + FS_MAX + 1) = abs(rs_en_r)^2;
        end

        [~,eNB_fs_r] = max(rs_en);
        F0 = eNB_fs_r - FS_MAX - 1;
        %加频偏
        data = data_0.' .* exp( 1i * 2 * pi * F0 * T / Fs );
        data_2_0 = data.';
        data = data_1.' .* exp( 1i * 2 * pi * F0 * T / Fs );
        data_2_1 = data.';
    else 
        data_2_0 = data_0;
        data_2_1 = data_1;
    end

    %解OFDM   
    data_ofdm_fs_0 = OFDM_Demodulation_Subframe(data_2_0);
    data_ofdm_fs_1 = OFDM_Demodulation_Subframe(data_2_1);

    %% 时偏纠正
    Fk = [-600:1:-1,1:1:600] .* 15E3; %1200个载波
    if eNB.TimeOffsetCorrection == 1
        data_out_0 = zeros(1200,14);
        data_out_1 = zeros(1200,14);

        TS_MAX = 20E-9; %正负时偏范围2ns
        TS_STEP = 5E-11; %步长0.05ns
        
        ts_en = zeros(1,TS_MAX/TS_STEP*2+1);

        %获取时偏量
        for n = -TS_MAX : TS_STEP : TS_MAX 
            %加时偏
            T0 = n;
            data = data_ofdm_fs_0(:,1);
            data = data.' .* exp( 1i * 2 * pi * Fk * T0 );
            data = data.';

            %RS相关
            ts_en_r = conj(RS_0) * data(RS_POS_0);
            ts_en(int32((n+TS_MAX)/TS_STEP + 1)) = abs(ts_en_r)^2;
        end

        [~,eNB_ts] = max(ts_en);
        T0 = ( eNB_ts - 1 ) * TS_STEP - TS_MAX;

    else
        T0 = 0;  
    end
    %加载时偏  
    for n = 1:1:14
        data = data_ofdm_fs_0(:,n);
        data = data.' .* exp( 1i * 2 * pi * Fk * T0 );
        data_out_0(:,n) = data.';

        data = data_ofdm_fs_1(:,n);
        data = data.' .* exp( 1i * 2 * pi * Fk * T0 );
        data_out_1(:,n) = data.';
    end

DATA_SF.data0 = data_out_0;
DATA_SF.data1 = data_out_1;
end

