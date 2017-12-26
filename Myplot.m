
%% 
figure;
n=1;
for i = 1:1:4
    subplot(2,2,i);
    plot(real(Channel_H1(:,i)),'r');
    hold on;
    plot(real(Channel_H0(:,i)),'b');
%     hold on;
%     plot(abs(Channel_H_nPCI_2(:,i)),'g');
    legend('6-413','5-413');
end

%% 
figure;
% plot(-2:0.1:2,zeros(1,41),'r');
% hold on;
plot(-2:0.1:2,ones(1,41)*1/sqrt(10),'r');
hold on;
plot(-2:0.1:2,ones(1,41)*3/sqrt(10),'r');
hold on;
plot(-2:0.1:2,ones(1,41)*-1/sqrt(10),'r');
hold on;
plot(-2:0.1:2,ones(1,41)*-3/sqrt(10),'r');
% hold on;
% plot(zeros(1,41),-2:0.1:2,'r');
hold on;
plot(ones(1,41)*1/sqrt(10),-2:0.1:2,'r');
hold on;
plot(ones(1,41)*3/sqrt(10),-2:0.1:2,'r');
hold on;
plot(ones(1,41)*-1/sqrt(10),-2:0.1:2,'r');
hold on;
plot(ones(1,41)*-3/sqrt(10),-2:0.1:2,'r');
hold on;
plot(real(DATAOUT),imag(DATAOUT),'b.');

%%

plot(abs())

%% 
ffid = fopen('pdcch.txt','w');
fprintf(ffid,'%d  %d\n',floor(real(pdcchSymbols(:))*1000),floor(imag(pdcchSymbols(:))*1000));
fclose all;

%% 
ffid = fopen('pdcch1.txt','w');
fprintf(ffid,'%d\n',floor(-dciBits(:)/1e12*1024) );
fclose all;

%% pdcch均衡

DCIPos = pdcchIndices(:,1);
indices = mwltelibrary('ltePDCCHDeinterleave',eNB_r,1828) + 1;
DCIPos = DCIPos(indices);

DATA_rr1 = DATA_SF.data0(:,1:eNB_r.CFI);
DATA_rr2 = reshape(DATA_rr1,1,[]);
DCIDATA.data0 = DATA_rr2.';
DATA_rr1 = DATA_SF.data1(:,1:eNB_r.CFI);
DATA_rr2 = reshape(DATA_rr1,1,[]);
DCIDATA.data1 = DATA_rr2.';

Channel_H_DCI = repmat(Channel_H,eNB_r.CFI,1);
RE_POS = reshape(DCIPos,2,[]);

H_00 = (Channel_H_DCI(RE_POS(1,:),1) + Channel_H_DCI(RE_POS(2,:),1))/2;
H_10 = (Channel_H_DCI(RE_POS(2,:),2) + Channel_H_DCI(RE_POS(1,:),2))/2;
H_01 = (Channel_H_DCI(RE_POS(1,:),3) + Channel_H_DCI(RE_POS(2,:),3))/2;
H_11 = (Channel_H_DCI(RE_POS(2,:),4) + Channel_H_DCI(RE_POS(1,:),4))/2;    

R_00 = DCIDATA.data0(RE_POS(1,:));
R_10 = DCIDATA.data0(RE_POS(2,:));
R_01 = DCIDATA.data1(RE_POS(1,:));
R_11 = DCIDATA.data1(RE_POS(2,:));


H_ABSSUM = abs(H_00).^2 + abs(H_10).^2 + abs(H_01).^2 + abs(H_11).^2;
RR = ([R_00,conj(R_10),R_01,conj(R_11)]).';
X_r = zeros(1,length(H_00)*2);
if eNB_r.IRC_flag ==1
    U_0 =  UU(:,:,floor((RE_POS(1,:)-1)./12)+1) ;
%         U_1 = ( U1(RE_POS(1,:)) + U1(RE_POS(2,:)) )./ 2;
end

for n = 1:1:length(H_00)
    HH = [H_00(n) ,-H_10(n) ; conj(H_10(n)) , conj(H_00(n)) ; H_01(n) , -H_11(n) ; conj(H_11(n)) , conj(H_01(n))];

    if eNB_r.IRC_flag ==1
        R_uu = U_0(:,:,n);
        R_hh = HH * HH';
                    
        W_H =  HH' * (R_uu + R_hh)^-1 ;
    else                  
        W_H = HH'./ H_ABSSUM(n) ;        
    end
    X_r(n*2-1) = W_H(1,:) * RR(:,n);
    X_r(n*2)   = conj(W_H(2,:) * RR(:,n));
end

demod = lteSymbolDemodulate(X_r,'QPSK','Soft');
descramblingSeq = ltePDCCHPRBS(eNB_r,length(demod),'signed');
cw = demod.*descramblingSeq;
pdcch.RNTI                       = eNB_r.PDSCH.RNTI;
%         pdcch.SearchSpace                = 'UESpecific';
pdcch.EnableCarrierIndication    = 'Off';
pdcch.EnableSRSRequest           = 'Off';
pdcch.EnableMultipleCSIRequest   = 'Off';
pdcch.NTxAnts                    = eNB_r.CellRefP;

[rxDCI2,rxDCIBits2] = ltePDCCHSearch(eNB_r,pdcch,cw);

ffid = fopen('pdcch.txt','w');
fprintf(ffid,'%d  %d\n',floor(real(X_r(:))*1000),floor(imag(X_r(:))*1000));
fclose(ffid);

%%  
figure
subplot(211);
plot(dciBits);
xlim([1 3968]);
subplot(212);
plot(dciBits1);
xlim([1 3968]);
% subplot(213);
% plot(cw);
% xlim([1 3656]);

%% 

dciSymbol = load ('./QQQ_pdcch_demap_dat.txt');

dciSymbol = dciSymbol(:,1) + 1i * dciSymbol(:,2);
figure
subplot(211);
plot(abs(pdcchSymbols));
xlim([1 1828]);
subplot(212);
plot(abs(dciSymbol));
xlim([1 1828]);


%%

plot(abs(Channel_H1(:,1)));
hold on ;
plot(abs(Channel_H(:,1)),'r');
%% 
for i = 1:1:4
    subplot(4,1,i);
    plot(abs(data_ifft(:,i)));
end


%% 
for i = 1:1:4
    subplot(4,1,i);
    plot(abs(Channel_H_1(:,i)),'b');
    hold on ;
    plot(abs(data_fft_1(:,i)),'r');
    hold on ;
    plot(abs(data_fft_11(:,i)),'g');
    legend('原始','新方法','老方法');
end

%% 
for i = 1:1:4
    subplot(4,1,i);
%     plot(abs(Channel_H_1(:,i)),'b');
%     hold on ;
    plot(abs(Channel_H1(:,i)),'r');
    hold on ;
    plot(abs(Channel_H(:,i)),'g');
    legend('新方法','老方法');
end
%% 
for i = 1:1:4
    subplot(4,1,i);
%     plot(abs(Channel_H_1(:,i)),'b');
%     hold on ;
    plot(abs(data_ifft(:,i)),'r');
%     hold on ;
%     plot(abs(Channel_H(:,i)),'g');
%     legend('新方法','老方法');
end

%% 
n=1;
for i = [1,5,8,12]
    subplot(4,1,n);
    n=n+1;
%     plot(abs(Channel_H_1(:,i)),'b');
%     hold on ;
    plot(abs(DATA_SF.data0(:,i)),'r');
%     hold on ;
%     plot(abs(Channel_H(:,i)),'g');
%     legend('新方法','老方法');
end


