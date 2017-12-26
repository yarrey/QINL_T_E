function [ DATAOUT ] = ChannelEqualizationSM( CFG , DATA , Channel_H , varargin)
% ChannelEqualizationSM 
% QYL 20171225
% 
% CFG.NCellID = 412; %cellID
% CFG.CFI = 1; %CFI
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

%% 
    
    if nargin == 4 
        UU = varargin{1};
%         U1 = varargin{1}(2,:);
    end

    RS_POS_0 = GEN_RS_POS(CFG.NCellID,CFG.NDLRB,0);
    RS_POS_4 = GEN_RS_POS(CFG.NCellID,CFG.NDLRB,1);
    
    RE_Pos_SM_1 = zeros(1,length(CFG.PRBSet)*12);
    for i = 1:1:length(CFG.PRBSet)
        RE_Pos_SM_1((i-1)*12+1:i*12) = CFG.PRBSet(i)*12+1:1:CFG.PRBSet(i)*12+12;
    end
    
    
%     RB_START = CFG.PRBSet(1);
%     RB_LEN   = CFG.PRBSet(end) - RB_START + 1;   
%     
%     
%     RE_Pos_SM_1 = RB_START*12+1:1:RB_START*12+RB_LEN*12;
    RE_Pos_SM_2 = RE_Pos_SM_1;
    RE_Pos_SM_2(ismember(RE_Pos_SM_2,RS_POS_0)) = [];
    RE_Pos_SM_2(ismember(RE_Pos_SM_2,RS_POS_4)) = [];
    
    RE_Pos_SM_3 = RE_Pos_SM_1;
    SS_POS = (CFG.NDLRB/2-3)*12+1 : 1 : (CFG.NDLRB/2+3)*12 ;
    RE_Pos_SM_3(ismember(RE_Pos_SM_3,SS_POS)) = [];
    
    RE_Pos_TD_1 = [ RE_Pos_SM_1(1:2:end) ; RE_Pos_SM_1(2:2:end) ];
    RE_Pos_TD_2 = [ RE_Pos_SM_2(1:2:end) ; RE_Pos_SM_2(2:2:end) ];
    
    
    U = 1/sqrt(2) * [1 1;1 exp((-1i * 2 * pi) / 2)];
    C1 = 1/sqrt(2) *[1 0;0 1];
    LayerSymbolsCounter = 0;
    
    
    if ismember(CFG.NSubframe ,[1,6])
        SymbolEnd   = 9; 
    else
        SymbolEnd   = 14; 
    end
    SymbolIndex = CFG.CFI+1:1:SymbolEnd;
%     if CFG.NSubframe == 0
%         SymbolIndex(ismember(SymbolIndex,[7,8,9,10])) = [];
%     end
    
    X = cell(SymbolEnd-CFG.CFI,1);
% if strcmpi(CFG.TxScheme , 'SpatialMux')
if strcmpi(CFG.TxScheme , 'CDD')
    for SymbolNumber = SymbolIndex 
        
        if ismember(SymbolNumber,3) && ismember(CFG.NSubframe ,[1,6])
            RE_POS = RE_Pos_SM_3;
        elseif ismember(SymbolNumber,14) && ismember(CFG.NSubframe ,5)
            RE_POS = RE_Pos_SM_3;
        elseif ismember(SymbolNumber,[9,10,11,14]) && ismember(CFG.NSubframe ,0)
            RE_POS = RE_Pos_SM_3;
        elseif ismember(SymbolNumber,8) && ismember(CFG.NSubframe ,0)
            RE_POS = RE_Pos_SM_2;
            RE_POS(ismember(RE_POS,SS_POS))=[];
        elseif ismember(SymbolNumber,[1,5,8,12])
            RE_POS = RE_Pos_SM_2;
        else
            RE_POS = RE_Pos_SM_1;
        end
       
        
        H_00 = (Channel_H(RE_POS,1));
        H_10 = (Channel_H(RE_POS,2));
        H_01 = (Channel_H(RE_POS,3));
        H_11 = (Channel_H(RE_POS,4));
        
%         H_00 = H_00 ./ mean(abs(H_00));
%         H_10 = H_10 ./ mean(abs(H_10));
%         H_01 = H_01 ./ mean(abs(H_01));
%         H_11 = H_11 ./ mean(abs(H_11));
                   
        R_0 = DATA.data0(RE_POS,SymbolNumber);
        R_1 = DATA.data1(RE_POS,SymbolNumber);
        
%         R_0 = R_0 ./ mean(abs(R_0));
%         R_1 = R_1 ./ mean(abs(R_1));
        if CFG.IRC_flag ==1
            U_0 =  UU(:,:,floor((RE_POS-1)./12)+1) ;
%         U_1 =  U1(RE_POS) ;
        end
        
        X_r = zeros(2,length(RE_POS));
        for i = 1:1:length(RE_POS)
            H = [H_00(i),H_10(i);H_01(i),H_11(i)];
            D = [1 0;0 exp((-1i * 2 * pi * LayerSymbolsCounter) / 2)];
            R = [R_0(i);R_1(i)];
            
            H_R = H * C1 * D * U;
            
            if CFG.IRC_flag ==1
                
                R_uu = U_0([1,3],[2,4],i);
%                 UU = [ U_0(i) ;
%                       U_1(i) ];
%                 R_uu = UU * UU';
                
%                 R_uu = [U_0(i)*conj(U_0(i)) ,  U_0(i)*conj(U_1(i)) ;
%                         U_1(i)*conj(U_0(i)) ,  U_1(i)*conj(U_1(i)) ];

%                 R_hh = [H_00(i)*conj(H_00(i))+H_10(i)*conj(H_10(i)) ,  H_00(i)*conj(H_01(i))+H_10(i)*conj(H_11(i))  ;
%                         H_01(i)*conj(H_00(i))+H_11(i)*conj(H_10(i)) ,  H_01(i)*conj(H_01(i))+H_11(i)*conj(H_11(i))  ];
                    
                R_hh = H_R * H_R';
                    
                    
                H_w =  H_R' * (R_uu + R_hh)^-1 ;
                X_r(:,i) = H_w * R;
            else
                X_r(:,i) = H_R^-1 * R;
            end                       
            
            LayerSymbolsCounter = LayerSymbolsCounter+1;
        end
        X{SymbolNumber-CFG.CFI} = X_r;
    end     
    
elseif strcmpi(CFG.TxScheme ,'TxDiversity')
     for SymbolNumber = SymbolIndex
        if ismember(SymbolNumber,3) && ismember(CFG.NSubframe ,[1,6])
            RE_Pos_TD_3 = [ RE_Pos_SM_3(1:2:end) ; RE_Pos_SM_3(2:2:end) ];
            RE_POS = RE_Pos_TD_3;
        elseif ismember(SymbolNumber,14) && ismember(CFG.NSubframe ,5)
            RE_Pos_TD_3 = [ RE_Pos_SM_3(1:2:end) ; RE_Pos_SM_3(2:2:end) ];
            RE_POS = RE_Pos_TD_3;
        elseif ismember(SymbolNumber,[9,10,11,14]) && ismember(CFG.NSubframe ,0)
            RE_Pos_TD_3 = [ RE_Pos_SM_3(1:2:end) ; RE_Pos_SM_3(2:2:end) ];
            RE_POS = RE_Pos_TD_3;
        elseif ismember(SymbolNumber,8) && ismember(CFG.NSubframe ,0)
            RE_POS = RE_Pos_TD_2;
            RE_POS(ismember(RE_POS,SS_POS))=[];
            RE_POS = reshape(RE_POS,2,[]);
        elseif ismember(SymbolNumber,[1,5,8,12])
            RE_POS = RE_Pos_TD_2;
        else
            RE_POS = RE_Pos_TD_1;
        end
        
        H_00 = (Channel_H(RE_POS(1,:),1) + Channel_H(RE_POS(2,:),1))/2;
        H_10 = (Channel_H(RE_POS(2,:),2) + Channel_H(RE_POS(1,:),2))/2;
        H_01 = (Channel_H(RE_POS(1,:),3) + Channel_H(RE_POS(2,:),3))/2;
        H_11 = (Channel_H(RE_POS(2,:),4) + Channel_H(RE_POS(1,:),4))/2;        
        
%         H_00 = H_00 ./ mean(abs(H_00));
%         H_10 = H_10 ./ mean(abs(H_10));
%         H_01 = H_01 ./ mean(abs(H_01));
%         H_11 = H_11 ./ mean(abs(H_11));
       
        R_00 = DATA.data0(RE_POS(1,:),SymbolNumber);
        R_10 = DATA.data0(RE_POS(2,:),SymbolNumber);
        R_01 = DATA.data1(RE_POS(1,:),SymbolNumber);
        R_11 = DATA.data1(RE_POS(2,:),SymbolNumber);
               
%         R_00 = R_00 ./ mean(abs(R_00));
%         R_10 = R_10 ./ mean(abs(R_10));
%         R_01 = R_01 ./ mean(abs(R_01));
%         R_11 = R_11 ./ mean(abs(R_11));       
        H_ABSSUM = abs(H_00).^2 + abs(H_10).^2 + abs(H_01).^2 + abs(H_11).^2;
        RR = ([R_00,conj(R_10),R_01,conj(R_11)]).';
        X_r = zeros(1,length(H_00)*2);
        if CFG.IRC_flag ==1
            U_0 =  UU(:,:,floor((RE_POS(1,:)-1)./12)+1) ;
%         U_1 = ( U1(RE_POS(1,:)) + U1(RE_POS(2,:)) )./ 2;
        end
        
        for n = 1:1:length(H_00)
            HH = [H_00(n) ,-H_10(n) ; conj(H_10(n)) , conj(H_00(n)) ; H_01(n) , -H_11(n) ; conj(H_11(n)) , conj(H_01(n))];
            
            if CFG.IRC_flag ==1
                
%                 U = [ U_0(n) , 0 ;
%                       0 ,  conj(U_0(n));
%                       U_1(n) , 0 ;
%                       0 ,  conj(U_1(n)) ];
%                 R_uu = U * U';
                R_uu = U_0(:,:,n);
                
%                 R_uu = [U_0(n)*conj(U_0(n)) , 0 , U_0(n)*conj(U_1(n)) , 0;
%                         0 , U_0(n)*conj(U_0(n)) , 0 , U_1(n)*conj(U_0(n));
%                         U_1(n)*conj(U_0(n)) , 0 , U_1(n)*conj(U_1(n))  ,0;
%                         0 , U_0(n)*conj(U_1(n)) , 0 , U_1(n)*conj(U_1(n))];

%                 R_hh = [H_00(n)*conj(H_00(n))+H_10(n)*conj(H_10(n)) , 0 , H_00(n)*conj(H_01(n))+H_10(n)*conj(H_11(n)) , H_00(n)*H_11(n)-H_01(n)*H_10(n) ;
%                         0 , H_00(n)*conj(H_00(n))+H_10(n)*conj(H_10(n)) , conj(H_01(n))*conj(H_10(n))-conj(H_00(n))*conj(H_11(n)) , H_01(n)*conj(H_00(n))+H_11(n)*conj(H_10(n)) ;
%                         H_01(n)*conj(H_00(n))+H_11(n)*conj(H_10(n)) , H_01(n)*H_10(n)-H_00(n)*H_11(n) , H_01(n)*conj(H_01(n))+H_11(n)*conj(H_11(n)) , 0;
%                         conj(H_00(n))*conj(H_11(n))-conj(H_01(n))*conj(H_10(n)) , H_00(n)*conj(H_01(n))+H_10(n)*conj(H_11(n)) , 0 , H_01(n)*conj(H_01(n))+H_11(n)*conj(H_11(n)) ];
                
                R_hh = HH * HH';
                    
                W_H =  HH' * (R_uu + R_hh)^-1 ;
            else                  
                W_H = HH'./ H_ABSSUM(n) ;        
            end
            X_r(n*2-1) = W_H(1,:) * RR(:,n);
            X_r(n*2)   = conj(W_H(2,:) * RR(:,n));
        end
                
        X{SymbolNumber-CFG.CFI} = X_r;
    end     
end
DATAOUT = [X{1:1:end}];
end

