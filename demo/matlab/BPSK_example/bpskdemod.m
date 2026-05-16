
% bpskdemod.m
% Function to perform BPSK demodulation

function [demodata]=bpskdemod(idata,qdata,para,nd,ml)

%****************** variables *************************
% idata :input Ich data
% qdata :input Qch data
% demodata: demodulated data (para-by-nd matrix)
% para   : Number of paralell channels
% nd : Number of data
% ml : Number of modulation levels
% (QPSK ->2  16QAM -> 4)
% *****************************************************

demodata = zeros(para,ml*nd);
demodata((1:para),(1:ml:ml*nd))=idata((1:para),(1:nd))>=0;

%******************** end of file ***************************
