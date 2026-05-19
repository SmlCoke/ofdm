
function [demodata]=QAM16demod(idata,qdata,para,nd,ml)

demodata = zeros(para,ml*nd);

% 以下不是格雷码，ber会偏高
% 前2个bit是±2，后2个bit是±1
% demodata((1:para),(1:ml:ml*nd))=idata((1:para),(1:nd))>=0;
% demodata((1:para),(2:ml:ml*nd))=qdata((1:para),(1:nd))>=0;
% 向量化运算，不能用||，它适用于单个元素，要用|
% demodata((1:para),(3:ml:ml*nd))=(idata((1:para),(1:nd))>2) | ( (idata((1:para),(1:nd))>-2) & (idata((1:para),(1:nd))<0 ) );
% demodata((1:para),(4:ml:ml*nd))=(qdata((1:para),(1:nd))>2) | ( (qdata((1:para),(1:nd))>-2) & (qdata((1:para),(1:nd))<0 ) );

% 奇怪，我如果写idata(:,:)就会报错，提示“无法执行赋值，因为左侧的大小为 1×10000，右侧的大小为 1×10021。”

demodata(:,(1:ml:ml*nd))=idata(:,(1:nd))>=0;
demodata(:,(2:ml:ml*nd))=qdata(:,(1:nd))>=0;
demodata(:,(3:ml:ml*nd))=abs(idata(:,(1:nd)))>=2;
demodata(:,(4:ml:ml*nd))=abs(qdata(:,(1:nd)))>=2;