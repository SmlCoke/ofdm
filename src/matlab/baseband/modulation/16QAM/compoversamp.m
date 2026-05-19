
% compoversamp.m
% Insert zero data to Ich and Qch input data

function [iout,qout] = compoversamp( idata, qdata , nsymb , sample) 

%****************** variables *************************
% idata : input Ich data
% qdata : input Qch data
% iout : output Ich data
% qout : output Qch data
% nsymb   : Number of burst symbol
% sample : Number of oversample
% *****************************************************
% 每隔sample个采样点取一个数据，其他采样点插入0(两个数据之间插入sample-1个0)
iout=zeros(1,nsymb*sample);
qout=zeros(1,nsymb*sample);
iout(1:sample:1+sample*(nsymb-1))=idata;
qout(1:sample:1+sample*(nsymb-1))=qdata;

%******************** end of file ***************************
