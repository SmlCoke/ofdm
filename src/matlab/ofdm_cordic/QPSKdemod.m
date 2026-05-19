
function [demodata]=QPSKdemod(idata,qdata,para,nd,ml)

demodata = zeros(para,ml*nd);
demodata((1:para),(1:ml:ml*nd))=idata((1:para),(1:nd))>=0;
demodata((1:para),(2:ml:ml*nd))=qdata((1:para),(1:nd))>=0;
