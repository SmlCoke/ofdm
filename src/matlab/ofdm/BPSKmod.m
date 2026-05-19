
% bpskmod.m
% Function to perform BPSK modulation
%将二进制数据映射为 OFDM 子载波上的 BPSK 符号
function [iout,qout]=BPSKmod(paradata,para,nd,ml)

%****************** variables *************************
% paradata : input data (para-by-nd matrix)
% iout :output Ich data
% qout :output Qch data
% para   : Number of paralell channels
% nd : Number of data
% ml : Number of modulation levels
% (QPSK ->2  16QAM -> 4)
% *****************************************************



%1->1,0->-1
paradata2=paradata.*2-1;
count2=0;
% 原代码没有这样的初始化，数组在循环里越变越大，没提前给它分好房间，运行会变慢！
iout = zeros(para,nd);
qout = zeros(para,nd);

for jj=1:nd
%创建para*1的列向量isi和isq，分别存储每个符号的I路和Q路数据
        isi = zeros(para,1);
        isq = zeros(para,1);        

        isi = isi + paradata2((1:para),1+count2);
        isq = 0;

        iout((1:para),jj)=isi;
        qout((1:para),jj)=isq;
        
        count2=count2+ml;
        
end
	
	

%******************** end of file ***************************
