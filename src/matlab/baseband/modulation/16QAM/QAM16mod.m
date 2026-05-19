
function [iout,qout]=QAM16mod(paradata,para,nd,ml)
paradata2=paradata.*2-1;
count2=0;

% 原代码没有这样的初始化，数组在循环里越变越大，没提前给它分好房间，运行会变慢！
iout = zeros(para,nd);
qout = zeros(para,nd);

% 以下不是格雷码，ber会偏高
% isi = isi + paradata2((1:para),1+count2).*2+ paradata2((1:para),3+count2);
% isq = isq + paradata2((1:para),2+count2).*2+ paradata2((1:para),4+count2);

for jj=1:nd
        isi = zeros(para,1);
        isq = zeros(para,1);

        b1=paradata(:,1+count2);
        b2=paradata(:,2+count2);
        b3=paradata(:,3+count2);
        b4=paradata(:,4+count2);
        
        isi(b1==1 & b3==1)=3;
        isi(b1==1 & b3==0)=1;
        isi(b1==0 & b3==0)=-1;
        isi(b1==0 & b3==1)=-3;

        isq(b2==1 & b4==1)=3;
        isq(b2==1 & b4==0)=1;
        isq(b2==0 & b4==0)=-1;
        isq(b2==0 & b4==1)=-3;
        
        iout((1:para),jj)=isi;
        qout((1:para),jj)=isq;
        
        count2=count2+ml;
end