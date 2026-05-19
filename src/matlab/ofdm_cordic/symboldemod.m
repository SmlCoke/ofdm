function [demodata]=symboldemod(idata,qdata,para,nd,ml)

demodata = zeros(para,ml*nd);
if(ml==1)
    [demodata]=BPSKdemod(idata,qdata,para,nd,ml);
elseif(ml==2)
    [demodata]=QPSKdemod(idata,qdata,para,nd,ml);
elseif(ml==4)
    [demodata]=QAM16demod(idata,qdata,para,nd,ml);
elseif(ml==6)
    [demodata]=QAM64demod(idata,qdata,para,nd,ml);
end