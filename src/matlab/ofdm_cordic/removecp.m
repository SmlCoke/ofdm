function [ich5,qch5]= removecp(ich4,qch4,total_len,gilen,nd)

ich5=zeros(total_len-gilen,nd);
qch5=zeros(total_len-gilen,nd);

ich5(1:total_len-gilen,:)=ich4(gilen+1:total_len,:);
qch5(1:total_len-gilen,:)=qch4(gilen+1:total_len,:);