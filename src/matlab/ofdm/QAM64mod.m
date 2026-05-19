
function [iout,qout]=QAM64mod(paradata,para,nd,ml)
count2=0;

% 原代码没有这样的初始化，数组在循环里越变越大，没提前给它分好房间，运行会变慢！
iout = zeros(para,nd);
qout = zeros(para,nd);

for jj=1:nd
        isi = zeros(para,1);
        isq = zeros(para,1);

        b1=paradata(:,1+count2);
        b2=paradata(:,2+count2);
        b3=paradata(:,3+count2);
        b4=paradata(:,4+count2);
        b5=paradata(:,5+count2);
        b6=paradata(:,6+count2);

        isi(b1==1 & b3==1 & b5==1)=7;
        isi(b1==1 & b3==1 & b5==0)=5;
        isi(b1==1 & b3==0 & b5==0)=3;
        isi(b1==1 & b3==0 & b5==1)=1;
        isi(b1==0 & b3==0 & b5==1)=-1;
        isi(b1==0 & b3==0 & b5==0)=-3;
        isi(b1==0 & b3==1 & b5==0)=-5;
        isi(b1==0 & b3==1 & b5==1)=-7;

        isq(b2==1 & b4==1 & b6==1)=7;
        isq(b2==1 & b4==1 & b6==0)=5;
        isq(b2==1 & b4==0 & b6==0)=3;
        isq(b2==1 & b4==0 & b6==1)=1;
        isq(b2==0 & b4==0 & b6==1)=-1;
        isq(b2==0 & b4==0 & b6==0)=-3;
        isq(b2==0 & b4==1 & b6==0)=-5;
        isq(b2==0 & b4==1 & b6==1)=-7;

        iout((1:para),jj)=isi;
        qout((1:para),jj)=isq;
        
        count2=count2+ml;
                
end