%% 说明
% QYL
% lte 模型
% 20171223
%% 初始化
clc;
close all;
clear all;
% clearvars;
addpath(genpath(pwd));



% for SimConfig = [46,116:1:125]
SimConfig = 125;
%% 源数据
DATANAME = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/source.mat',SimConfig);

% DATANAME = sprintf('./SourceData/source_%s.mat',SimConfig);
DATA = load (DATANAME);


%% 基本参数

eNB.Source = DATA;

% 与基站相关
eNB.NDLRB           = 100;
eNB.DuplexMode      = 'TDD';
eNB.CyclicPrefix    = 'Normal';
eNB.TDDConfig       = 2;
eNB.SSC             = 6;
eNB.CellRefP        = 2;
eNB.Fs              = 30.72E6; %采样频率

eNB.IRC_flag        = 0;
eNB.DeICI           = 0; %邻区数量 



eNB.EstimationVersion = 1;

if eNB.EstimationVersion == 1 
    filename1 = 'WINDOW_r';
elseif eNB.EstimationVersion == 2 
    filename1 = 'VCFR_r';
elseif eNB.EstimationVersion == 0 
    filename1 = 'OLD_r';
end

eNB.NCellID         = 123;

eNB.StartPOS        = FindStartPos( eNB );
% eNB.StartPOS        = 40890; %帧头位置

eNB.PDSCH.RNTI      = 65535;%RNTI


filename = sprintf('./LOG/%s_%d.log',filename1,SimConfig);
disp(filename);
disp(datetime('now'));
fid = fopen(filename,'w');


SubFrameTotal = floor((length(eNB.Source.data0) - eNB.StartPOS)/30720);
disp(SubFrameTotal);
%% 主程序
decode_ok = 0;
decode_fail = 0;

% for NFrame_r = 0:1:FrameTotal
    for NSubframe_r = 0:1:SubFrameTotal-1
        eNB_r                   = eNB;
        eNB_r.NFrame            = floor(NSubframe_r/10);
        eNB_r.NSubframe         = mod(NSubframe_r,10);
        
        if ismember(eNB_r.NSubframe ,[2,7])
%             fprintf(fid,'--------------------------------------------------------------\n');
            fprintf(fid,'NFrame : %d\n',eNB_r.NFrame);
            fprintf(fid,'NSubframe : %d\n',eNB_r.NSubframe);
            fprintf(fid,'Subframe for UL! \n');
%             fprintf(fid,'--------------------------------------------------------------\n');
            continue;
        end
        
        % GetSubFrameSourceData
        eNB_r.SFPosOffsetCorrection = 0; %帧头纠正
        eNB_r.FrequencyOffsetCorrection = 0; %频偏纠正
        eNB_r.TimeOffsetCorrection = 0; %时偏纠正
        % 子帧数据
        DATA_SF = GetSubFrameSourceData( eNB_r );
    
        % ChannelEstimation
        if ismember(eNB_r.NSubframe ,[1,6])
            eNB_r.ChannelEstimationSymbol   = [0,4,7]; %参与信道估计的符号
        else
            eNB_r.ChannelEstimationSymbol   = [0,4,7,11]; %参与信道估计的符号
        end
        eNB_r.ZERO_PADING_COUNT         = 32; %时域降噪长度
        
        % 主区信道估计
%         [Channel_H1,U1] = ChannelEstimationIRC( eNB_r , DATA_SF );
        [Channel_H,U] = ChannelEstimationIRC2( eNB_r , DATA_SF );
        %% PBCH
        rxsubframe = zeros(1200,14,2);
        rxsubframe(:,:,1) = DATA_SF.data0;
        rxsubframe(:,:,2) = DATA_SF.data1;

        hest = zeros(1200,14,2,2);
        hest(:,:,1,1) = Channel_H(:,1) * ones(1,14);
        hest(:,:,1,2) = Channel_H(:,2) * ones(1,14);
        hest(:,:,2,1) = Channel_H(:,3) * ones(1,14);
        hest(:,:,2,2) = Channel_H(:,4) * ones(1,14);
        
        if eNB_r.NSubframe == 0
            pbchIndices = ltePBCHIndices(eNB_r);
            [pbchRx, pbchHest] = lteExtractResources( pbchIndices, rxsubframe, hest);
            [bchBits, pbchSymbols, nfmod4, mib, CellRefP] = ltePBCHDecode( eNB_r, pbchRx, pbchHest, 0); 
            enb = lteMIB(mib, eNB_r); 
        end
        if ~exist('enb','var')
            eNB_r.PHICHDuration   = 'Normal';
            eNB_r.Ng              = 'One';
        else        
            
            eNB_r.NFrameSys       = enb.NFrame + nfmod4;
            eNB_r.PHICHDuration   = enb.PHICHDuration;
            eNB_r.Ng              = enb.Ng;
        end
        
        %% PCFICH
        pcfichIndices = ltePCFICHIndices(eNB_r);  % Get PCFICH indices
        
        [pcfichRx, pcfichHest] = lteExtractResources(pcfichIndices, rxsubframe, hest);
        cfiBits = ltePCFICHDecode(eNB_r, pcfichRx, pcfichHest , 0);

        eNB_r.CFI = lteCFIDecode(cfiBits); % Get CFI
        
        %% PDCCH

        pdcchIndices = ltePDCCHIndices(eNB_r); % Get PDCCH indices
        
%         phichIndices = ltePHICHIndices(eNB_r);  % Get PHICH indices
%         TT = ismember(pdcchIndices,phichIndices);
%         [I,J]=find(TT==1)
        
        
        [pdcchRx, pdcchHest] = lteExtractResources(pdcchIndices, rxsubframe, hest);

        [dciBits, pdcchSymbols] = ltePDCCHDecode(eNB_r, pdcchRx, pdcchHest, 0);


%         dciBits1 = load ('./QQQ_pdcch_descr_dat.txt');
%         dciBits1 = -dciBits1;
        
        pdcch.RNTI                       = eNB_r.PDSCH.RNTI;
%         pdcch.SearchSpace                = 'UESpecific';
        pdcch.EnableCarrierIndication    = 'Off';
        pdcch.EnableSRSRequest           = 'Off';
        pdcch.EnableMultipleCSIRequest   = 'Off';
        pdcch.NTxAnts                    = eNB_r.CellRefP;


        [rxDCI,rxDCIBits] = ltePDCCHSearch(eNB_r,pdcch,dciBits);
        
%         [rxDCI1,rxDCIBits1] = ltePDCCHSearch(eNB_r,pdcch,dciBits1);
        
        if isempty(rxDCI)
            pdcch.RNTI                       = 65534;
            [rxDCI,rxDCIBits] = ltePDCCHSearch(eNB_r,pdcch,dciBits);
        end
        
        
        if isempty(rxDCI) 
%             fprintf(fid,'--------------------------------------------------------------\n');
            fprintf(fid,'NFrame : %d\n',eNB_r.NFrame);
            fprintf(fid,'NFrameSys : %d\n',eNB_r.NFrameSys);
            fprintf(fid,'NSubframe : %d\n',eNB_r.NSubframe);
            fprintf(fid,'PDCCH Decode Fail ! \n');
%             fprintf(fid,'--------------------------------------------------------------\n');
            continue;
        elseif ismember(rxDCI{1, 1}.DCIFormat,['Format0','Format1','Format2','Format2C','Format2D','Format4'])
            fprintf(fid,'--------------------------------------------------------------\n');
            fprintf(fid,'NFrame : %d\n',eNB_r.NFrame);
            fprintf(fid,'NFrameSys : %d\n',eNB_r.NFrameSys);
            fprintf(fid,'NSubframe : %d\n',eNB_r.NSubframe);
            fprintf(fid,'>>> PDCCH Decode %s ! \n',rxDCI{1, 1}.DCIFormat);
            fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
            continue; 
        end


        pdsch = DeDci(eNB_r, rxDCI{1}, pdcch.RNTI);
        if pdsch.ok == 0
            fprintf(fid,'--------------------------------------------------------------\n');
            fprintf(fid,'NFrame : %d\n',eNB_r.NFrame);
            fprintf(fid,'NFrameSys : %d\n',eNB_r.NFrameSys);
            fprintf(fid,'NSubframe : %d\n',eNB_r.NSubframe);
            fprintf(fid,'DCIFormat : %s\n',pdsch.DCIFormat);
            fprintf(fid,'RNTI : %d\n',pdsch.RNTI);
            fprintf(fid,'>>> PDCCH Decode fail ! \n');
            fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
            continue;
        else
            eNB_r = cell2struct([struct2cell(eNB_r);struct2cell(pdsch)],[fieldnames(eNB_r);fieldnames(pdsch)]);
        end

%% PDSCH
         CFG1 =  eNB_r;
         CFG2 =  eNB_r;
        switch mod(eNB_r.NCellID,3)
            case 0
                CFG1.NCellID = eNB_r.NCellID + 1; %cellID
                CFG2.NCellID = eNB_r.NCellID + 2; %cellID
            case 1
                CFG1.NCellID = eNB_r.NCellID - 1; %cellID
                CFG2.NCellID = eNB_r.NCellID + 1; %cellID
            case 2
                CFG1.NCellID = eNB_r.NCellID - 1; %cellID
                CFG2.NCellID = eNB_r.NCellID - 2; %cellID
        end
        
        % 临区信道估计
%         CFG1.ChannelEstimationSymbol = [4,7]; %参与信道估计的符号
        CFG1.ZERO_PADING_COUNT = 16;
        [Channel_H1,~] = ChannelEstimationIRC2( CFG1 , DATA_SF );

        % 临区信道估计   
%         CFG2.ChannelEstimationSymbol = [4,7]; %参与信道估计的符号
        CFG2.ZERO_PADING_COUNT = 16;
        [Channel_H2,~] = ChannelEstimationIRC2( CFG2 , DATA_SF );
   
%         eNB_r.DeICI           = 2; %邻区数量 
        eNB_r.DeICI_PCI       = [CFG1.NCellID,CFG2.NCellID]; %邻区pci
        eNB_r.DeICI_Symbol    = [0,4,7,11]; %符号位
        
        % 临区干扰消除
        DATA_DeICI = DeICI( eNB_r , DATA_SF , Channel_H1 , Channel_H2);

        % 信道均衡
        DATAOUT = ChannelEqualizationSM( eNB_r , DATA_DeICI , Channel_H , U );
        


%% 解码

%         if strcmpi(eNB_r.TxScheme , 'SpatialMux')
        if strcmpi(eNB_r.TxScheme , 'CDD')              
            
            MeanPower_0 = sum(abs(DATAOUT(1,:)).^2)/length(DATAOUT(1,:));
            DATAOUT(1,:) = DATAOUT(1,:) ./ sqrt(MeanPower_0);
            MeanPower_1 = sum(abs(DATAOUT(2,:)).^2)/length(DATAOUT(2,:));
            DATAOUT(2,:) = DATAOUT(2,:) ./ sqrt(MeanPower_1);
            
            eNB_r1 = eNB_r;
            eNB_r2 = eNB_r;
            if exist('eNB_r.SwapFlag','var')
                if eNB_r.SwapFlag == 1
                    eNB_r1.Modulation   = eNB_r.Modulation2;
                    eNB_r1.trblklen     = eNB_r.trblklen2;
                    eNB_r1.RV           = eNB_r.RV2;
                else
                    eNB_r2.Modulation   = eNB_r.Modulation2;
                    eNB_r2.trblklen     = eNB_r.trblklen2;
                    eNB_r2.RV           = eNB_r.RV2;
                end
            else
                eNB_r2.Modulation   = eNB_r.Modulation2;
                eNB_r2.trblklen     = eNB_r.trblklen2;
                eNB_r2.RV           = eNB_r.RV2;
            end
            
            
            demodpdschSymb_0 = lteSymbolDemodulate(DATAOUT(1,:),eNB_r1.Modulation{1},'Soft'); 
            demodpdschSymb_1 = lteSymbolDemodulate(DATAOUT(2,:),eNB_r2.Modulation{1},'Soft'); 

            scramblingSeq_0 = ltePDSCHPRBS(eNB_r1,eNB_r1.RNTI,0,length(demodpdschSymb_0),'signed');
            dlschBits_0 = scramblingSeq_0.*demodpdschSymb_0;    
            scramblingSeq_1 = ltePDSCHPRBS(eNB_r2,eNB_r2.RNTI,1,length(demodpdschSymb_1),'signed');
            dlschBits_1 = scramblingSeq_1.*demodpdschSymb_1; 

            RateRecoverOUT_0 = lteRateRecoverTurbo(dlschBits_0,eNB_r1.trblklen,eNB_r1.RV,eNB_r1);
            RateRecoverOUT_1 = lteRateRecoverTurbo(dlschBits_1,eNB_r2.trblklen,eNB_r2.RV,eNB_r2);
            
            ERR0 = 1;
            ERR1 = 1;
            nturbodecits = 1;
            while ERR0 ~= 0 || ERR1 ~= 0 %&& ERR2 ~= 0
                TurboDecodeOUT_0 = lteTurboDecode(RateRecoverOUT_0,nturbodecits);
                TurboDecodeOUT_1 = lteTurboDecode(RateRecoverOUT_1,nturbodecits);
                if ERR1 ~= 0
                    [BLK1,ERR1] = lteCRCDecode(TurboDecodeOUT_1{1},'24A');
                    nturbodecits_1 = nturbodecits;
                end
                if ERR0 ~= 0
                    [BLK0,ERR0] = lteCRCDecode(TurboDecodeOUT_0{1},'24A');
                    nturbodecits_0 = nturbodecits;
                end
                nturbodecits=nturbodecits+1;
                if nturbodecits > 30
                    break;
                end
            end
        elseif strcmpi(eNB_r.TxScheme ,'TxDiversity')
            MeanPower = sum(abs(DATAOUT).^2)/length(DATAOUT);
            DATAOUT = DATAOUT ./ sqrt(MeanPower);
            
            demodpdschSymb = lteSymbolDemodulate(DATAOUT,eNB_r.Modulation{1},'Soft'); 

            scramblingSeq = ltePDSCHPRBS(eNB_r,eNB_r.RNTI,0,length(demodpdschSymb),'signed');
            dlschBits = demodpdschSymb.*scramblingSeq;    
    %         eNB_r.NLayers        =1;
            RateRecoverOUT = lteRateRecoverTurbo(dlschBits,eNB_r.trblklen,eNB_r.RV,eNB_r);
        
            ERR0 = 1;
            ERR1 = 1;
            ERR2 = 1;
            nturbodecits = 1;
            while ERR0 ~= 0 %&& ERR1 ~= 0 && ERR2 ~= 0
                TurboDecodeOUT = lteTurboDecode(RateRecoverOUT,nturbodecits);        
                switch length(TurboDecodeOUT)
                   case 1
                        [BLK0,ERR0] = lteCRCDecode(TurboDecodeOUT{1},'24A');
                        nturbodecits=nturbodecits+1;
                        if nturbodecits > 30
                            break;
                        end
                   case 2
                        if ERR1 ~= 0
                            [BLK1,ERR1] = lteCRCDecode(TurboDecodeOUT{1},'24B');
                            nturbodecits_1 = nturbodecits;
                        end
                        if ERR2 ~= 0
                            [BLK2,ERR2] = lteCRCDecode(TurboDecodeOUT{2},'24B');
                            nturbodecits_2 = nturbodecits;
                        end
                        [BLK0,ERR0] = lteCRCDecode([BLK1;BLK2],'24A');
                        nturbodecits=nturbodecits+1;
                        if nturbodecits > 30
                            break;
                        end
                end
            end   
        end
        
        if nturbodecits ~= 31 && sum(BLK0) ~= 0
            decode_ok = decode_ok+1;
        else
            decode_fail = decode_fail+1;
        end
        
        fprintf(fid,'--------------------------------------------------------------\n');
        fprintf(fid,'NFrame : %d\n',eNB_r.NFrame);
        fprintf(fid,'NFrameSys : %d\n',eNB_r.NFrameSys);
        fprintf(fid,'NSubframe : %d\n',eNB_r.NSubframe);
        fprintf(fid,'DCIFormat : %s\n',rxDCI{1, 1}.DCIFormat);       
        fprintf(fid,'DuplexMode : %s\n',eNB_r.DuplexMode);
        fprintf(fid,'TDDConfig : %d\n',eNB_r.TDDConfig);
        fprintf(fid,'NCellID : %d\n',eNB_r.NCellID);
        fprintf(fid,'CFI : %d\n',eNB_r.CFI);
        
        fprintf(fid,'RNTI : %d\n',eNB_r.RNTI);
        fprintf(fid,'PRBSet : %d\n',eNB_r.PRBSet(:));
        fprintf(fid,'NLayers : %d\n',eNB_r.NLayers); 
        
        
        
        if strcmpi(eNB_r.TxScheme , 'CDD')
            fprintf(fid,'Modulation1 : %s\n',eNB_r1.Modulation{1});
            fprintf(fid,'trblklen1 : %d\n',eNB_r1.trblklen);
            fprintf(fid,'RV1 : %d\n',eNB_r1.RV);
            
            fprintf(fid,'Modulation2 : %s\n',eNB_r2.Modulation{1});
            fprintf(fid,'trblklen2 : %d\n',eNB_r2.trblklen);
            fprintf(fid,'RV2 : %d\n',eNB_r2.RV);
        else
            fprintf(fid,'Modulation : %s\n',eNB_r.Modulation{1});
            fprintf(fid,'trblklen : %d\n',eNB_r.trblklen);
            fprintf(fid,'RV : %d\n',eNB_r.RV);
        end
        
        fprintf(fid,'TxScheme : %s\n',eNB_r.TxScheme);        
        fprintf(fid,'nturbodecits: %s\n',num2str(nturbodecits-1));
        fprintf(fid,'sum of BLK0: %d\n',sum(BLK0));
        fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
    end
% end

fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');

fprintf(fid,'decode_ok: %d \n',decode_ok);
fprintf(fid,'decode_fail: %d \n',decode_fail);

fprintf('decode_ok: %d \n',decode_ok);
fprintf('decode_fail: %d \n',decode_fail);

fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
fprintf(fid,'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
disp(datetime('now'));
fclose ('all');

% end