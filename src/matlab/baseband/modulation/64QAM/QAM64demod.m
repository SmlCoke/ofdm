
function [demodata]=QAM64demod(idata,qdata,para,nd,ml)

demodata = zeros(para,ml*nd);

demodata(:,(1:ml:ml*nd))=idata(:,(1:nd))>=0;
demodata(:,(2:ml:ml*nd))=qdata(:,(1:nd))>=0;
demodata(:,(3:ml:ml*nd))=abs(idata(:,(1:nd)))>=4;
demodata(:,(4:ml:ml*nd))=abs(qdata(:,(1:nd)))>=4;
demodata(:,(5:ml:ml*nd))=abs(idata(:,(1:nd)))>=6 | abs(idata(:,(1:nd)))<=2;
demodata(:,(6:ml:ml*nd))=abs(qdata(:,(1:nd)))>=6 | abs(qdata(:,(1:nd)))<=2;