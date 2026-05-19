
% Simulation program to realize OFDM transmission system

%% ********************** preparation part ***************************

clear;
clc;
tic;
para=108;       % Number of parallel channel to transmit (points)
npilot=6;        % Number of pilot symbols in one OFDM symbol
empty=14;     % Number of empty symbols in one OFDM symbol
fftlen=128;       % FFT length
nd=6;             % Number of information OFDM symbol for one loop，6组128子载波
ml=1;             % Modulation level (BPSK:ml=1, QPSK:ml=2, 16QAM:ml=4, 64QAM:ml=6)
sr=250000;   % OFDM symbol rate (250 ksyombol/s)
br=sr.*ml;      % Bit rate per carrier
gilen=fftlen/4;       % Length of guard interval (points)保护间隔，消除ISI，ICI，通常为FFT长度的1/4
ebn0=[0:11];         % Eb/N0
ber=zeros(1,length(ebn0));

%% ************************** main loop part **************************

nloop=100;  % Number of simulation loops

for cnt = 1:length(ebn0)
    disp(ebn0(cnt));
    noe = 0;    % Number of error data
    nod = 0;    % Number of transmitted data
    
    % transmitter
    
    for iii=1:nloop
        
        % data generation
        
        seridata=rand(1, para*nd*ml)>0.5;
        
        % serial to parallel convertion
% 将串行数据转为并行数据，para行，nd*ml列，每列为1个符号
        paradata=reshape(seridata,para,nd*ml);
        
        % modulation
% 调制，得到每个OFDM符号的108个数据子载波
        [ich,qch]=symbolmod(paradata,para, nd,ml);
        
        % pilot symbol Insertion and OFDM symbol mapping ( input data switching for IFFT)
% 得到每个OFDM符号的128个子载波，并映射到IFFT输入
        [ich1,qch1]=ofdmmap(ich,qch,fftlen,nd);
        
        %  IFFT
% 似乎IFFT存在1/N，而FFT不存在1/N，但在计算高斯噪声标准差时使用的是IFFT之后的功率
% 保证噪声功率与信号功率的比例正确，所以不需要再除以N了
% 明白了，IFFT会导致功率降低，FFT有累加，保持了功率不变，所以最后恢复到1，3，5，7这种应有的尺度，解调就没有问题
        x=ich1+qch1.*1i;
        y=ifft(x);
        ich2=real(y);
        qch2=imag(y);

        % Guard interval insertion
% 插入保护间隔，复制最后gilen个点到前面
% 我对addcp增加了nd参数
        [ich3,qch3]= addcp(ich2,qch2,fftlen,gilen,nd);
        
        %  parallel to serial convertion
% 并转串
        ich3 = reshape( ich3 , 1 , (fftlen+gilen)*nd);
        qch3 = reshape( qch3 , 1 , (fftlen+gilen)*nd);
        
        % Attenuation Calculation
% 计算高斯噪声标准差，加入AWGN噪声 ，多除以para，是考虑单个symbol的功率
        spow=sum(ich3.^2+qch3.^2)/nd./para;
% PSK的Es=ml*Eb，QAM的Es=(2/3)*(ml-1)*Eb
        attn=0.5*spow*sr/br*10.^(-ebn0(cnt)/10);
        attn=sqrt(attn);
        
        % AWGN addition
        
        [ich4,qch4]=comb(ich3,qch3,attn);
  
        % serial to parallel convertion
% 串转并        
        ich4=reshape( ich4, (fftlen+gilen), nd);
        qch4=reshape( qch4, (fftlen+gilen), nd);
        
        % Guard interval removal
% 去掉保护间隔   
        [ich5,qch5]= removecp(ich4,qch4,(fftlen+gilen),gilen,nd);
        
        % FFT
        rx=ich5+qch5.*1i;
        ry=fft(rx);
        ich6=real(ry);
        qch6=imag(ry);
        
        %  pilot data removal and  OFDM symbol demapping
% 从128子载波恢复108个数据子载波
        [ich7,qch7]=ofdmdemap(ich6,qch6);
        
        %  demoduration
% 解调，得到每个OFDM符号的108个数据子载波对应的比特数据
        [demodata]=symboldemod(ich7,qch7,para,nd,ml);
        
        %  parallel to serial convertion
% 并转串
        demodata1=reshape(demodata,1,para*nd*ml);
        
        %  bit error
        
        noe2=sum(abs(demodata1-seridata));
        nod2=length(seridata);
        
        % calculating BER
        
        noe=noe+noe2;
        nod=nod+nod2;
        
    end
    
    ber(cnt)=noe/nod;
end

%% Output result *
disp(['SNR = ', num2str(ebn0)]);
disp(['BER = ', num2str(ber)]);
toc;

if(ml==1)
        load('bpsk_theory.mat');

        ebn0_theory_sub = ebn0_theory(1, 1:length(ebn0)); 
        ber_theory_sub = ber_theory(1, 1:length(ber));

        save('bpsk_matlab.mat', 'ebn0', 'ber');

        figure;
        axis([0 12 1.0e-7, 1.0e-0]);
        semilogy (ebn0_theory_sub, ber_theory_sub,'-k>','linewidth',3,'MarkerSize',8);
        hold on ;
        semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
        legend ('BPSK-theory', 'OFDM-simulation');
        title('802.11n-OFDM Simulation');
        grid on ;
        hold off;
elseif(ml==2)
        load('qpsk_theory.mat');

        ebn0_theory_sub = ebn0_theory(1, 1:length(ebn0)); 
        ber_theory_sub = ber_theory(1, 1:length(ber));

        figure;
        axis([0 12 1.0e-7, 1.0e-0]);
        semilogy (ebn0_theory_sub, ber_theory_sub,'-k>','linewidth',3,'MarkerSize',8);
        hold on ;
        semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
        legend ('QPSK-theory', 'OFDM-simulation');
        title('802.11n-OFDM Simulation');
        grid on ;
        hold off;
elseif(ml==4)
        load('QAM16_theory.mat');

        ebn0_theory_sub = ebn0_theory(1, 1:length(ebn0)); 
        ber_theory_sub = ber_theory(1, 1:length(ber));

        figure;
        axis([0 12 1.0e-7, 1.0e-0]);
        semilogy (ebn0_theory_sub, ber_theory_sub,'-k>','linewidth',3,'MarkerSize',8);
        hold on ;
        semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
        legend ('16QAM-theory', 'OFDM-simulation');
        title('802.11n-OFDM Simulation');
        grid on ;
        hold off;
elseif(ml==6)
        load('QAM64_theory.mat');

        ebn0_theory_sub = ebn0_theory(1, 1:length(ebn0)); 
        ber_theory_sub = ber_theory(1, 1:length(ber));

        figure;
        axis([0 12 1.0e-7, 1.0e-0]);
        semilogy (ebn0_theory_sub, ber_theory_sub,'-k>','linewidth',3,'MarkerSize',8);
        hold on ;
        semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
        legend ('64QAM-theory', 'OFDM-simulation');
        title('802.11n-OFDM Simulation');
        grid on ;
        hold off;        
end

%end of file *
