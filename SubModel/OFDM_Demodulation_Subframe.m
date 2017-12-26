function data_ofdm  = OFDM_Demodulation_Subframe( DATA  )
%OFDM_DEMODULATION 此处显示有关此函数的摘要
%   此处显示详细说明
    data_ofdm = zeros(1200,14);
    for i = 0:1:13 
        symbol = mod(i,7);
        slot = (i - symbol )/7;
        start_bit = 161 + (2048+144)*i+16*slot;

        pos_n = start_bit:1:start_bit+2047;

        data_fft_r = fft(DATA(pos_n),2048);
        data_ofdm(:,i+1) = [data_fft_r(2048-600+1:2048);data_fft_r(2:601)];
    end

end

