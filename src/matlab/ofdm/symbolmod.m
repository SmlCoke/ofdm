function [ich,qch]=symbolmod(paradata,para,nd,ml)

ich = zeros(para,nd);
qch = zeros(para,nd);
if(ml==1)
    [ich,qch]=BPSKmod(paradata,para,nd,ml);
elseif(ml==2)
    [ich,qch]=QPSKmod(paradata,para,nd,ml);
elseif(ml==4)
    [ich,qch]=QAM16mod(paradata,para,nd,ml);
elseif(ml==6)
    [ich,qch]=QAM64mod(paradata,para,nd,ml);
end