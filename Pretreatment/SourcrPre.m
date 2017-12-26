%% ≥ı ºªØ
clc;
close all;
clear all;
% clearvars;
%%



for i = [46,116:1:125]
    disp (i);
    file_name = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/chip_i_Ant_0.txt' , i );
    data0_i = importdata ( file_name );
    file_name = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/chip_q_Ant_0.txt' , i );
    data0_q = importdata ( file_name );
    file_name = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/chip_i_Ant_1.txt' , i );
    data1_i = importdata ( file_name );
    file_name = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/chip_q_Ant_1.txt' , i );
    data1_q = importdata ( file_name );



    data0 = data0_i + 1i* data0_q;
    data1 = data1_i + 1i* data1_q;
    
    file_name = sprintf ( './SourceData/AD9361_2349.8M_PCI123/AD9361_2349.8M_PCI123_RB100_%dDB/source.mat',i);
    save ( file_name , 'data0' ,'data1');
    clear data0_i data0_q data1_i data1_q data0 data1 file_name
end