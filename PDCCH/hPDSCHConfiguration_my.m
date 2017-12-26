%hPDSCHConfiguration PDSCH configuration
%   [PDSCH,TRBLKLEN] = hPDSCHConfiguration(ENB,DCI,RNTI) 
%   decodes the physical downlink shared channel configuration PDSCH and
%   transport block length TRBLKLEN from received downlink control
%   information message DCI, eNodeB configuration ENB and radio network
%   temporary identifier RNTI.

%   Copyright 2010-2013 The MathWorks, Inc.


function [pdsch,trblklen] = hPDSCHConfiguration_my(enb,dci,RNTI)

    % Set general PDSCH parameters
    pdsch.RNTI = RNTI;
    pdsch.PRBSet = lteDCIResourceAllocation(enb, dci);
    pdsch.NLayers = enb.CellRefP;  
    trblklen = 280;

    % Set DCI format specific parameters
    if (strcmp(dci.DCIFormat,'Format1A')==1)      
        % Calculate the transport block size
        tbsIndication = mod(dci.TPCPUCCH,2);
        if (tbsIndication)
            NPRB1A = 3;
        else
            NPRB1A = 2;
        end
        imcs = dci.ModCoding;
        
        if imcs <= 9 
            itbs = imcs;
        elseif imcs <= 16
            itbs = imcs-1;
        elseif imcs <= 28
            itbs = imcs-2;
        end
      
        riv = dci.Allocation.RIV;
        rbs = enb.NDLRB;
        
        RB_str = mod(riv,rbs);
        RB_len = ((riv - RB_str)/rbs) + 1;

        if(RNTI==65535 || RNTI==65534)
             trblklen = lteTBS(NPRB1A, imcs);
             pdsch.Modulation = {'QPSK'};
        else
            if(enb.NSubframe==1 || enb.NSubframe==6)
                RB_len_special = RB_len  * 3 / 4;
                trblklen = lteTBS(RB_len_special ,itbs);
            else 
                trblklen = lteTBS(RB_len ,itbs);
            end
            if(dci.ModCoding<=9)
               pdsch.Modulation = {'QPSK'};
            elseif(dci.ModCoding<=16)
               pdsch.Modulation = {'16QAM'};            
            else
               pdsch.Modulation = {'64QAM'};
            end
        end  
        pdsch.RV = dci.RV;
    end
    
    if (strcmp(dci.DCIFormat, 'Format1C')==1)  
        % Set PDSCH RV parameter
        if (pdsch.RNTI==65535)
            % Set the PDSCH RV as per TS36.321 Section 5.3.1 if a System
            % Information message type (RNTI==0xFFFF). In this case assume
            % SystemInformationBlockType1 message.
            k = mod(floor(enb.NFrame/2), 4);
            RVK = mod(ceil(3/2*k), 4);
            pdsch.RV = RVK;
        else
            pdsch.RV = 0;            
        end
        
        % Set PDSCH modulation
        if(dci.ModCoding<=9)
           pdsch.Modulation = {'QPSK'};
        elseif(dci.ModCoding<=16)
           pdsch.Modulation = {'16QAM'};            
        else
           pdsch.Modulation = {'64QAM'};
        end
        
        % Calculate the transport block size
        imcs = dci.ModCoding;
        if imcs <= 9 
            itbs = imcs;
        elseif imcs <= 16
            itbs = imcs-1;
        elseif imcs <= 28
            itbs = imcs-2;
        end
        trblklen = TBS1C(itbs);
    end             
    
    if (enb.CellRefP==1)
        pdsch.TxScheme = 'Port0';
    else
        pdsch.TxScheme = 'TxDiversity';
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
