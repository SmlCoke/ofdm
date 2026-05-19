
% compconv.m
% Function to perform convolution between signal and filter

function [iout, qout] = compconv(idata, qdata, filter)

% **************************************************************** 
%	idata		: ich data sequcence
%	qdata		: qch data sequcence
%   filter      : filter tap coefficience
% **************************************************************** 
% 这里是做线性卷积而非filter，conv的输出长度是length(idata)+length(filter)-1，而filter的输出长度是length(idata)，所以不能用filter
iout = conv(idata,filter);
qout = conv(qdata,filter);
 
%******************** end of file ***************************