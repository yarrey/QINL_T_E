function [ Channel_H , U ] = ChannelEstimationIRC2( eNB , DATA )
% ChannelEstimationIRC2 
% QYL 20171222
% 
% eNB.PCI = 412; %cellID
% eNB.RBs = 100; %码块数量
% eNB.NSF = 6; %子帧号
% eNB.ChannelEstimationSymbol = [0,4,7,11]; %参与信道估计的符号
% eNB.ZERO_PADING_COUNT = 32;
% DATA.data0 ; %复数数据 1200*14
% DATA.data1 ; %复数数据 1200*14
% 
% Channel_H ; %复数数据 1200*4
% 
% [ Channel_H ] = ChannelEstimation( eNB , DATA )
% 

 %% 信道估计
    RS_0 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 0,0);
    RS_4 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 0,4);
    RS_7 = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 1,0);
    RS_b = GEN_RS(eNB.NCellID,eNB.NDLRB,eNB.NSubframe * 2 + 1,4);

    RS_POS_0 = GEN_RS_POS(eNB.NCellID,eNB.NDLRB,0);
    RS_POS_4 = GEN_RS_POS(eNB.NCellID,eNB.NDLRB,1);

    Channel_H_R = zeros(200,16);

    Channel_H_R(:,1) = DATA.data0(RS_POS_0,1) ./ RS_0.' ;
    Channel_H_R(:,2) = DATA.data0(RS_POS_4,5) ./ RS_4.' ;
    Channel_H_R(:,3) = DATA.data0(RS_POS_0,8) ./ RS_7.' ;
    Channel_H_R(:,4) = DATA.data0(RS_POS_4,12) ./ RS_b.' ;

    Channel_H_R(:,5) = DATA.data0(RS_POS_4,1) ./ RS_0.' ;
    Channel_H_R(:,6) = DATA.data0(RS_POS_0,5) ./ RS_4.' ;
    Channel_H_R(:,7) = DATA.data0(RS_POS_4,8) ./ RS_7.' ;
    Channel_H_R(:,8) = DATA.data0(RS_POS_0,12) ./ RS_b.' ;

    Channel_H_R(:,9) = DATA.data1(RS_POS_0,1) ./ RS_0.' ;
    Channel_H_R(:,10) = DATA.data1(RS_POS_4,5) ./ RS_4.' ;
    Channel_H_R(:,11) = DATA.data1(RS_POS_0,8) ./ RS_7.' ;
    Channel_H_R(:,12) = DATA.data1(RS_POS_4,12) ./ RS_b.' ;

    Channel_H_R(:,13) = DATA.data1(RS_POS_4,1) ./ RS_0.' ;
    Channel_H_R(:,14) = DATA.data1(RS_POS_0,5) ./ RS_4.' ;
    Channel_H_R(:,15) = DATA.data1(RS_POS_4,8) ./ RS_7.' ;
    Channel_H_R(:,16) = DATA.data1(RS_POS_0,12) ./ RS_b.' ;

    Channel_H_1 = zeros(400,4);
    Channel_H_Startpos = zeros(1,4);
    for i = 1:1:4  
        
        if ismember(0,eNB.ChannelEstimationSymbol) && ismember(7,eNB.ChannelEstimationSymbol)
            data_temp1 = ( Channel_H_R(:,i*4-3) + Channel_H_R(:,i*4-1) ) / 2;%0 7 符号
        elseif ismember(0,eNB.ChannelEstimationSymbol)
            data_temp1 = Channel_H_R(:,i*4-3) ;%0 符号
        elseif ismember(7,eNB.ChannelEstimationSymbol)
            data_temp1 = Channel_H_R(:,i*4-1) ;%7 符号
        else
            error('eNB.ChannelEstimationSymbol');
        end
    
            
        if ismember(4,eNB.ChannelEstimationSymbol) && ismember(11,eNB.ChannelEstimationSymbol)
            data_temp2 = ( Channel_H_R(:,i*4-2) + Channel_H_R(:,i*4) ) / 2;%4  11 符号
        elseif ismember(4,eNB.ChannelEstimationSymbol)
            data_temp2 = Channel_H_R(:,i*4-2) ;%4 符号
        elseif ismember(11,eNB.ChannelEstimationSymbol)
            data_temp2 = Channel_H_R(:,i*4) ;%11 符号
        else
            error('eNB.ChannelEstimationSymbol');
        end
            
        if mod(i,2) %1代表发射天线0
            if RS_POS_0(1) < RS_POS_4(1)            
                Channel_H_1(1:2:400,i) = data_temp1;
                Channel_H_1(2:2:400,i) = data_temp2; 
                Channel_H_Startpos(i)  = RS_POS_0(1);
            else
                Channel_H_1(1:2:400,i) = data_temp2;
                Channel_H_1(2:2:400,i) = data_temp1;
                Channel_H_Startpos(i)  = RS_POS_4(1);
            end
        else
            if RS_POS_4(1) < RS_POS_0(1)
                Channel_H_1(1:2:400,i) = data_temp1;
                Channel_H_1(2:2:400,i) = data_temp2;
                Channel_H_Startpos(i)  = RS_POS_4(1);
            else
                Channel_H_1(1:2:400,i) = data_temp2;
                Channel_H_1(2:2:400,i) = data_temp1;
                Channel_H_Startpos(i)  = RS_POS_0(1);
            end
        end
    end

%% new 滑窗

if eNB.EstimationVersion == 1 
    AAAA = 28;
    dataout = zeros(1,400);
    data_ifft = zeros(400,4);
    for i = 1:1:4
        data_ifft(:,i) = ifft(Channel_H_1(:,i));
    end  
    enpos = zeros(1,4);
    for i = 1 :1 : 4
        datain = [data_ifft(:,i);data_ifft(:,i)];
        for n = 1:1:400
            dataout(n) = sum(abs(datain(n:n+AAAA-1)).^2);
        end
        [~,pos] = max(dataout);
        enpos(i) = pos;
    end
    
%     E_en = zeros(1,4);   
    for i = 1:1:4
        if enpos(i) > 400-AAAA+1
%             E_en(i) = mean(abs(data_ifft(AAAA-400+enpos(i):enpos(i)-1,i)).^2);
            data_ifft(AAAA-400+enpos(i):enpos(i)-1,i) = 0;           
        else
%             E_en(i) = mean(abs([data_ifft(1:enpos(i)-1,i);data_ifft(enpos(i)+AAAA:end,i)]).^2);
            data_ifft(1:enpos(i)-1,i) = 0; 
            data_ifft(enpos(i)+AAAA:end,i) = 0;
        end
%         for n = 1:1:400
%             if abs(data_ifft(n,i))^2 <= E_en(i)
%                 data_ifft(n,i) = 0;
%             end
%         end
    end   
    
    data_fft = zeros(400,4);
    for i = 1:1:4
        data_fft(:,i) =  fft(data_ifft(:,i));
    end 
    data_fft_1 = data_fft; 
    
%% new 2 滑窗 VCFR
elseif eNB.EstimationVersion ==2

%     数组扩展
    data_ex = zeros(112,4);
    
    for i = 1:1:112
        data_ex(i,:) = Channel_H_1(400,:) * (113-i) / 113 + Channel_H_1(1,:) * i / 113 ;
    end
  
    Channel_H_2 = zeros(512,4);
    for i = 1:1:4
        Channel_H_2(:,i) = [ Channel_H_1(201:400,i) ; data_ex(:,i) ; Channel_H_1(1:200,i) ];
    end   

    W_h = ones(512,1);
    for i = 1:1:200
        W_h(i) = ( 0.9 + 0.1 * cos( 2 * pi * (i - 1) / 400 ) ) * exp( 1i * pi * 10 * (i - 1) / 400 );
    end
    
    for i = 313:1:512
        W_h(i) = ( 0.9 + 0.1 * cos( 2 * pi * ( i - 113 ) / 400 ) ) * exp( 1i * pi * 10 * ( i - 113 ) / 400 );
    end
    W_hh = repmat(W_h,1,4); 
%     W_hh = 1;
    Channel_H_3 = Channel_H_2 .* W_hh;
    
%     时域去噪
    data_ifft = zeros(512,4);
    for i = 1:1:4
        data_ifft(:,i) = ifft(Channel_H_3(:,i));
    end  
  
    AAAA = 28;
    enpos = zeros(1,4);
    dataout = zeros(1,512);
    for i = 1 :1 : 4
        datain = [data_ifft(:,i);data_ifft(:,i)];
        for n = 1:1:512
            dataout(n) = sum(abs(datain(n:n+AAAA-1)).^2);
        end
        [~,pos] = max(dataout);
        enpos(i) = pos;
    end
      
    for i = 1:1:4
        if enpos(i) > 512-AAAA+1
            data_ifft(AAAA-512+enpos(i):enpos(i)-1,i) = 0;           
        else
            data_ifft(1:enpos(i)-1,i) = 0; 
            data_ifft(enpos(i)+AAAA:end,i) = 0;
        end
    end   

    data_fft = zeros(512,4);
    for i = 1:1:4
        data_fft(:,i) =  fft(data_ifft(:,i));
    end 

    data_fft_2 = data_fft ./ W_hh;
    
    data_fft_1 = zeros(400,4);
    for i = 1:1:4
        data_fft_1(:,i) =  data_fft_2([313:1:512,1:1:200],i);
    end 
    
%% old
elseif eNB.EstimationVersion ==0
%     数组边缘扩展
    Channel_H_2 = zeros(512,4);
    ONES = ones(56,1);
    for i = 1:1:4
        Channel_H_2(:,i) = [ ONES*Channel_H_1(1,i) ; Channel_H_1(:,i) ; ONES*Channel_H_1(end,i) ];
    end   

%     时域去噪
    data_ifft = zeros(512,4);
    for i = 1:1:4
        data_ifft(:,i) = ifft(Channel_H_2(:,i));
    end  


    ZERO_PADING_COUNT = eNB.ZERO_PADING_COUNT;
    for i = 1:1:4
        data_ifft(ZERO_PADING_COUNT+1:end-ZERO_PADING_COUNT+1,i) = 0;
    end 

    data_fft = zeros(512,4);
    for i = 1:1:4
        data_fft(:,i) =  fft(data_ifft(:,i));
    end 

    data_fft_1 = zeros(400,4);
    for i = 1:1:4
        data_fft_1(:,i) =  data_fft(57:456,i);
    end 
   
end   

%%
    %插值
    Channel_H = zeros(1200,4);

    for i = 1:1:4
        Channel_H(Channel_H_Startpos(i):3:end,i) =  data_fft_1(:,i);

        for n = 1:1:Channel_H_Startpos(i)
            Channel_H(n,i) =  data_fft_1(1,i);
        end
        for n = 1200-3+Channel_H_Startpos(i):1:1200
            Channel_H(n,i) =  data_fft_1(end,i);
        end

        for n = Channel_H_Startpos(i)+1:3:1200-3+Channel_H_Startpos(i)
            Channel_H(n,i) =  Channel_H(n-1,i)*2/3.0 + Channel_H(n+2,i)*1/3.0;
        end
        for n = Channel_H_Startpos(i)+2:3:1200-3+Channel_H_Startpos(i)
            Channel_H(n,i) =  Channel_H(n-2,i)*1/3.0 + Channel_H(n+1,i)*2/3.0;
        end
    end 
    
%% IRC
    U_1 = zeros(200,16);
    if eNB.IRC_flag ==1
        for i = 1:1:16
            if ismember(i , [1,3,6,8,9,11,14,16])
                U_1(:,i) = Channel_H_R(:,i) - Channel_H(RS_POS_0,floor((i-1)/4)+1);
            else 
                U_1(:,i) = Channel_H_R(:,i) - Channel_H(RS_POS_4,floor((i-1)/4)+1);
            end
        end
        
        U_1_r0 = U_1(:,1:8);
        U_1_r1 = U_1(:,9:16);
        U_2 = zeros(4,4,200,8);
        for i = 1:1:8
            for n = 1:1:200
                U_1_rr = [U_1_r0(n,i);conj(U_1_r0(n,i));U_1_r1(n,i);conj(U_1_r1(n,i))];
                
                U_2(:,:,n,i) = U_1_rr * U_1_rr';
            end
        end
        
        U_3 = mean(U_2,4);
        
        U_4 = (U_3(:,:,1:2:end) + U_3(:,:,2:2:end)) ./2;
        
        U = U_4;
%         U_1 = Channel_H_1 - data_fft_1 ;

%         U_sum_0 = (U_1(:,1)+U_1(:,2))./2;
%         U_sum_1 = (U_1(:,3)+U_1(:,4))./2;
%         U_sum_0_1 = reshape(U_sum_0,4,[]);
%         U_sum_1_1 = reshape(U_sum_1,4,[]);
%         U0_0 = (U_sum_0_1(1,:)+U_sum_0_1(2,:)+U_sum_0_1(3,:)+U_sum_0_1(4,:))./4;
%         U1_0 = (U_sum_1_1(1,:)+U_sum_1_1(2,:)+U_sum_1_1(3,:)+U_sum_1_1(4,:))./4;
%         U(1,:) = reshape(ones(12,1)*U0_0,1,[]);
%         U(2,:) = reshape(ones(12,1)*U1_0,1,[]);
    else
        U = 0;
    end
    
    
    
end

