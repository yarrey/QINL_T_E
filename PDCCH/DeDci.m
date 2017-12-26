%hPDSCHConfiguration PDSCH configuration
%   [PDSCH,TRBLKLEN] = hPDSCHConfiguration(ENB,DCI,RNTI) 
%   decodes the physical downlink shared channel configuration PDSCH and
%   transport block length TRBLKLEN from received downlink control
%   information message DCI, eNodeB configuration ENB and radio network
%   temporary identifier RNTI.

%   Copyright 2010-2013 The MathWorks, Inc.


function [pdsch] = DeDci(enb,dci,RNTI)
    pdsch.DCIFormat = dci.DCIFormat;
    pdsch.RNTI = RNTI;
    pdsch.PRBSet = lteDCIResourceAllocation(enb, dci);
%     pdsch.RV = dci.RV;
    N_prb = length(pdsch.PRBSet);   
    pdsch.NLayers = enb.CellRefP; 
    
    pdsch.ok = 0;
    
%     if (enb.CellRefP==1)
%         pdsch.TxScheme = 'Port0';
%     else
%         pdsch.TxScheme = 'TxDiversity';
%     end  
    
    if ismember(RNTI,[65534,65535])     
        pdsch.Modulation = {'QPSK'};
        pdsch.TxScheme = 'TxDiversity';
        if (strcmp(dci.DCIFormat,'Format1A')==1)
            pdsch.RV = dci.RV;
            I_mcs = dci.ModCoding;
            tbsIndication = mod(dci.TPCPUCCH,2);
            if (tbsIndication)
                NPRB1A = 3;
            else
                NPRB1A = 2;
            end
            I_tbs = I_mcs;
            pdsch.trblklen = lteTBS(NPRB1A, I_tbs);
            pdsch.ok = 1;
        elseif (strcmp(dci.DCIFormat,'Format1C')==1)
            
            I_mcs = dci.ModCoding;
            I_tbs = I_mcs;             
            pdsch.trblklen = TBS1C(I_tbs);
            pdsch.RV = 0;
%             k = mod(floor(enb.NFrame/2), 4);
%             RVK = mod(ceil(3/2*k), 4);
%             pdsch.RV = RVK; 
            pdsch.ok = 1;
        else 
            pdsch.ok = 0;
        end
    else
        if ismember(dci.DCIFormat,['Format2','Format2A','Format2B','Format2C','Format2D'])
%             pdsch.TxScheme = 'SpatialMux';
%             pdsch.TxScheme = 'CDD';
            

            if exist('dci.SwapFlag','var')
                pdsch.SwapFlag = dci.SwapFlag;
            end
                
                
            CodeWords = 0;
            
            if ~( dci.ModCoding1 == 0 && dci.RV1 == 1 )
                
                CodeWords = CodeWords + 1;
                
                pdsch.RV = dci.RV1;
                I_mcs1 = dci.ModCoding1;
                if I_mcs1 <= 9 
                    I_tbs = I_mcs1;
                    pdsch.Modulation = {'QPSK'};
                elseif I_mcs1 <= 16
                    I_tbs = I_mcs1-1;
                    pdsch.Modulation = {'16QAM'};            
                elseif I_mcs1 <= 28
                    I_tbs = I_mcs1-2;
                    pdsch.Modulation = {'64QAM'};            
                end
                if(enb.NSubframe==1 || enb.NSubframe==6)
                    RB_len_special = N_prb  * 3 / 4;
                    pdsch.trblklen = lteTBS(RB_len_special ,I_tbs);
                else
                    pdsch.trblklen = lteTBS(N_prb, I_tbs);
                end  
                pdsch.ok = 1;
            end
            
            if ~( dci.ModCoding2 == 0 && dci.RV2 == 1 )
                
                CodeWords = CodeWords + 1;
                
                pdsch.RV2 = dci.RV2;
                I_mcs2 = dci.ModCoding1;
                if I_mcs2 <= 9 
                    I_tbs = I_mcs2;
                    pdsch.Modulation2 = {'QPSK'};
                elseif I_mcs2 <= 16
                    I_tbs = I_mcs2-1;
                    pdsch.Modulation2 = {'16QAM'};            
                elseif I_mcs2 <= 28
                    I_tbs = I_mcs2-2;
                    pdsch.Modulation2 = {'64QAM'};            
                end
                if(enb.NSubframe==1 || enb.NSubframe==6)
                    RB_len_special = N_prb  * 3 / 4;
                    pdsch.trblklen2 = lteTBS(RB_len_special ,I_tbs);
                else
                    pdsch.trblklen2 = lteTBS(N_prb, I_tbs);
                end  
                pdsch.ok = 1;
            end
            
            if CodeWords == 2
                pdsch.TxScheme = 'CDD';
            elseif CodeWords == 1
                pdsch.TxScheme = 'TxDiversity';
            end
            
            
        else
            pdsch.TxScheme = 'TxDiversity';
            I_mcs = dci.ModCoding;
            pdsch.RV = dci.RV;
            if I_mcs <= 9 
                I_tbs = I_mcs;
                pdsch.Modulation = {'QPSK'};
            elseif I_mcs <= 16
                I_tbs = I_mcs-1;
                pdsch.Modulation = {'16QAM'};            
            elseif I_mcs <= 28
                I_tbs = I_mcs-2;
                pdsch.Modulation = {'64QAM'};            
            end
            if(enb.NSubframe==1 || enb.NSubframe==6)
                RB_len_special = N_prb  * 3 / 4;
                pdsch.trblklen = lteTBS(RB_len_special ,I_tbs);
            else
                pdsch.trblklen = lteTBS(N_prb, I_tbs);
            end  
            pdsch.ok = 1;
        end
    end             
end

%TBS1C Transport block size from index
%   TBS = TBS1C(ITBS) is the transport block size from transport block size
%   index ITBS for the case of DCI Format 1C.

%   Copyright 2013 The MathWorks, Inc.

function tbs = TBS1C(itbs)

    tbss = [40 56 72 120 136 144 176 208 224 256 280 296 328 336 392 ...
        488 552 600 632 696 776 840 904 1000 1064 1128 1224 1288 1384 ...
        1480 1608 1736];

    tbs = tbss(itbs+1);

end
