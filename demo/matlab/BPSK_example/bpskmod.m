
% bpskmod.m
% Function to perform BPSK modulation

function [iout,qout]=bpskmod(paradata,para,nd,ml)

%****************** variables *************************
% paradata : input data (para-by-nd matrix)
% iout :output Ich data
% qout :output Qch data
% para   : Number of paralell channels
% nd : Number of data
% ml : Number of modulation levels
% (QPSK ->2  16QAM -> 4)
% *****************************************************




paradata2=paradata.*2-1;
count2=0;

for jj=1:nd
        
        isi = zeros(para,1);
        isq = zeros(para,1);        

        isi = isi + paradata2((1:para),1+count2);
        isq = 0;

        iout((1:para),jj)=isi;
        qout((1:para),jj)=isq;
        
        count2=count2+ml;
        
end
	
	

%******************** end of file ***************************
