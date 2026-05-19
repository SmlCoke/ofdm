function [ich3,qch3]= addcp(ich2,qch2,fftlen,gilen,nd)

ich3=zeros(fftlen+gilen,nd);
qch3=zeros(fftlen+gilen,nd);

ich3(1:gilen,:)=ich2(fftlen-gilen+1:fftlen,:);
ich3(gilen+1:fftlen+gilen,:)=ich2(1:fftlen,:);

qch3(1:gilen,:)=qch2(fftlen-gilen+1:fftlen,:);
qch3(gilen+1:fftlen+gilen,:)=qch2(1:fftlen,:);