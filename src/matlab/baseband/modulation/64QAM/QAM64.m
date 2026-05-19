% QAM64.m
clc
clear
load('QAM64_theory.mat');

%******************** Preparation part *************************************
sr = 256000;     % Symbol rate
ml = 6;          % ml:Number of modulation levels (BPSK:ml=1, QPSK:ml=2, 16QAM:ml=4, 64QAM:ml=6)
br = sr .* ml;   % Bit rate
nd = 10000;       % Number of symbols that simulates in each loop
ebn0 = 0:8;      % Eb/N0
ber = zeros(1,length(ebn0)); %ber
%上采样倍数，这里为8，例如每个符号之间插入 7 个零
IPOINT = 8;    % Number of oversamples
multi_path = 0;		% 1 = enable multi_path; 0 = disable multi_path

%************************* Filter initialization ***************************
irfn = 21;                   % Number of taps
%α=0.5，升余弦滤波器带宽B=(1+α)*Rs/2
alfs = 0.5;                  % Rolloff factor
%发射端脉冲成形滤波器和接收端匹配滤波器系数计算
[xh] = hrollfcoef(irfn,IPOINT,sr,alfs,1);   %Transmitter Pulse Shape Filter coefficients
[xh2] = hrollfcoef(irfn,IPOINT,sr,alfs,0);  %Receiver Match Filter coefficients

%******************** START CALCULATION *************************************

nloop = 100;  % Number of simulation loops
noe = 0;      % Number of error data
nod = 0;      % Number of transmitted data

tic;
for cnt = 1:length(ebn0)
    disp(ebn0(cnt));
    noe = 0;    % Number of error data
    nod = 0;    % Number of transmitted data
    for iii=1:nloop
        
        %*************************** Data generation ********************************
        
        data1=rand(1,nd*ml)>0.5;  % rand: built in function，产生0/1
        
        %*************************** QAM64 Modulation ********************************
        
        [ich,qch]=QAM64mod(data1,1,nd,ml);
        
        %*************************** Up sample ********************************
% 插零上采样，即在每个符号之间插入 7 个零
        [ich1,qch1]= compoversamp(ich,qch,length(ich),IPOINT);
        
        %*************************** Pulse shaping filter ********************************
% 对I路和Q路分别进行FIR卷积滤波，xh为发射端脉冲成形滤波器系数
        [ich2,qch2]= compconv(ich1,qch1,xh);
        
        %************************************** Channel************************
        switch multi_path
            case 1
                rtf = [1, 0.6, 0.4];%multi path
                ich3 = filter(sqrt(sum(rtf.*rtf)), rtf, ich2);%filter: built in function
                qch3 = filter(sqrt(sum(rtf.*rtf)), rtf, qch2);
% 这里的rtf是多径系数，sqrt(sum(rtf.*rtf))是归一化系数，使得多径信道的总功率不变
% sqrt(sum(rtf.*rtf))是分子，rtf是分母
% MATLAB filter(b,a,x) 对应差分方程：a(1)y(n)+a(2)y(n−1)+a(3)y(n−2)+⋯=b(1)x(n)+b(2)x(n−1)+b(3)x(n−2)+...
% 公式为y(n) = 1·x(n) + 0.6·x(n-1) + 0.4·x(n-2) - 0.6·y(n-1) - 0.4·y(n-2)，是IIR
% 之前mpc = [1, 0.9, 0.8]; %multi path coefficient
% data2 = filter(mpc, 1, data1); %filter: built in function
% y[n]=x[n]+0.9x[n−1]+0.8x[n−2]，是FIR
            case 0
                ich3 = ich2;%filter: built in function
                qch3 = qch2;
        end
        
        
        %**************************** Attenuation Calculation ***********************
% 衰减计算
% spow：每个发送符号的平均能量，例如BPSK的P=A^2/2，不用开根号
        spow=sum(ich3.*ich3+qch3.*qch3)/nd;  % sum: built in function
% dB转线性，这里计算的是每个bit的平均能量。10lg，注意有个负号，因为右侧等式是信号能量，不加负号的话，算出来的是Eb/N0，而不是N0/Eb
        attn=0.5*spow*sr/br*10.^(-ebn0(cnt)/10);
        attn=sqrt(attn);  % sqrt: built in function
        
        %********************* Add White Gaussian Noise (AWGN) **********************
        
        [ich4,qch4]= comb(ich3,qch3,attn);% add white gaussian noise
        
        %*************************** Pulse shaping filter ********************************
% 接收端匹配滤波器，xh2为接收端匹配滤波器系数
        [ich5,qch5]= compconv(ich4,qch4,xh2); % receive filtering
        
        %*************************** Synchronization and Down sample ********************************
% irfn:匹配滤波器的tap数，IPOINT:上采样倍数，syncpoint:同步点位置
        syncpoint=irfn*IPOINT;
% start : step : end，从syncpoint开始，每隔IPOINT个采样点取一个样本，直到ich5的末尾
% 滤波器存在延迟，会导致前面irfn*IPOINT个采样点没有有效数据，所以从syncpoint开始取样
% 但为什么是irfn*IPOINT呢？
        ich6=ich5(syncpoint:IPOINT:length(ich5));
        qch6=qch5(syncpoint:IPOINT:length(qch5));
        
        %**************************** QAM64 Demodulation *****************************
        
        [demodata]=QAM64demod(ich6,qch6,1,nd,ml);
        
        %************************** Bit Error Rate (BER) ****************************
        
        noe2=sum(abs(data1-demodata));  % sum: built in function
        nod2=length(data1);  % length: built in function
        noe=noe+noe2;
        nod=nod+nod2;
        
        %fprintf('%d\t%e\n',iii,noe2/nod2);  % fprintf: built in function
        
    end % for iii=1:nloop
    ber(cnt) = noe/nod;
end
toc;
disp(['BER=  ',num2str(ber)]);

%********************** Output result ***************************

disp(['frame=',num2str(nloop)]);
disp(['BER=',num2str(ber)]);
toc;
% fprintf('%d\t%d\t%d\t%e\n',ebn0,noe,nod,noe/nod);  % fprintf: built in function
% fid = fopen('BERbpsk.dat','a');
% fprintf(fid,'%d\t%e\t%f\t%f\t\n',ebn0,noe/nod,noe,nod);  % fprintf: built in function
% fclose(fid);

%******************** end of file ***************************
figure;
axis([0 8.5 1.0e-4, 1.0e-1]);
semilogy (ebn0_theory, ber_theory,'-k>','linewidth',3,'MarkerSize',8);
hold on ;
semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
legend ('QAM64-theory', 'QAM64-simulation');
title('QAM64 Simulation');
grid on ;
hold off;
