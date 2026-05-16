
% Simulation program to realize OFDM transmission system

%% ********************** preparation part ***************************

clear;
clc;
tic;
para=108;       % Number of parallel channel to transmit (points)
npilot=6;        % Number of pilot symbols in one OFDM symbol
empty=14;     % Number of empty symbols in one OFDM symbol
fftlen=128;       % FFT length
nd=6;             % Number of information OFDM symbol for one loop
ml=1;             % Modulation level (BPSK:ml=1, QPSK:ml=2, 16QAM:ml=4, 64QAM:ml=6)
sr=250000;   % OFDM symbol rate (250 ksyombol/s)
br=sr.*ml;      % Bit rate per carrier
gilen=fftlen/4;       % Length of guard interval (points)
ebn0=[0:8];         % Eb/N0
ber=zeros(1,length(ebn0));

%% ************************** main loop part **************************

nloop=1000;  % Number of simulation loops

for cnt = 1:length(ebn0)
    disp(ebn0(cnt));
    noe = 0;    % Number of error data
    nod = 0;    % Number of transmitted data
    
    % transmitter
    
    for iii=1:nloop
        
        % data generation
        
        seridata=rand(1, para*nd*ml)>0.5;
        
        % serial to parallel convertion
        
        paradata=reshape(seridata,para,nd*ml);
        
        % modulation
        
        [ich,qch]=symbolmod(paradata,para, nd,ml);
        
        % pilot symbol Insertion and OFDM symbol mapping ( input data switching for IFFT)
        
        [ich1,qch1]=ofdmmap(ich,qch,fftlen,nd);
        
        %  IFFT
        x=ich1+qch1.*1i;
        y=ifft(x);
        ich2=real(y);
        qch2=imag(y);
        
        % Guard interval insertion
        
        [ich3,qch3]= addcp(ich2,qch2,fftlen,gilen);
        
        %  parallel to serial convertion
        
        ich3 =reshape( ich3,1, (fftlen+gilen)*nd);
        qch3=reshape(qch3,1, (fftlen+gilen)*nd);
        
        % Attenuation Calculation
        
        spow=sum(ich3.^2+qch3.^2)/nd./para;
        attn=0.5*spow*sr/br*10.^(-ebn0(cnt)/10);
        attn=sqrt(attn);
        
        % AWGN addition
        
        [ich4,qch4]=comb(ich3,qch3,attn);
        
        % serial to parallel convertion
        
        ich4=reshape( ich4,  (fftlen+gilen),  nd);
        qch4=reshape(qch4, (fftlen+gilen),  nd);
        
        % Guard interval removal
        
        [ich5,qch5]= removecp(ich4,qch4,(fftlen+gilen),gilen);
        
        % FFT
        rx=ich5+qch5.*1i;
        ry=fft(rx);
        ich6=real(ry);
        qch6=imag(ry);
        
        %  pilot data removal and  OFDM symbol demapping
        
        [ich7,qch7]=ofdmdemap(ich6,qch6);
        
        %  demoduration
        
        [demodata]=symboldemod(ich7,qch7,para,nd,ml);
        
        %  parallel to serial convertion
        
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

load('ber_theory.mat');
figure;
axis([0 8.5 1.0e-4, 1.0e-1]);
semilogy (ebn0_theory, ber_theory,'-k>','linewidth',3,'MarkerSize',8);
hold on ;
semilogy (ebn0, ber, '-b<', 'linewidth',3, 'MarkerSize',8);
legend ('BPSK-theory', 'OFDM-simulation');
title('802.11n-OFDM Simulation');
grid on ;
hold off;

%end of file *
