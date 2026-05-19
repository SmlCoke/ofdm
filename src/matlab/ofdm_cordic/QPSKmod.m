
function [iout,qout]=QPSKmod(paradata,para,nd,ml)
paradata2=paradata.*2-1;
count2=0;

% 原代码没有这样的初始化，数组在循环里越变越大，没提前给它分好房间，运行会变慢！
iout = zeros(para,nd);
qout = zeros(para,nd);

for jj=1:nd
        isi = zeros(para,1);
        isq = zeros(para,1);

        isi = isi + paradata2((1:para),1+count2);
        isq = isq + paradata2((1:para),2+count2);

        iout((1:para),jj)=isi;
        qout((1:para),jj)=isq;
        
        count2=count2+ml;
                
end