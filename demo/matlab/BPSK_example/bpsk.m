% bpsk.m
clc
clear
load('bpsk_theory.mat');

%******************** Preparation part *************************************
sr = 256000;     % Symbol rate
ml = 1;          % ml:Number of modulation levels (BPSK:ml=1, QPSK:ml=2, 16QAM:ml=4, 64QAM:ml=6)
br = sr .* ml;   % Bit rate
nd = 1000;       % Number of symbols that simulates in each loop
ebn0 = 0:8;      % Eb/N0
ber = zeros(1,length(ebn0)); %ber
IPOINT = 8;    % Number of oversamples
multi_path = 0;		% 1 = enable multi_path; 0 = disable multi_path

%************************* Filter initialization ***************************
irfn = 21;                   % Number of taps
alfs = 0.5;                  % Rolloff factor
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
        
        data1=rand(1,nd*ml)>0.5;  % rand: built in function
        
        %*************************** BPSK Modulation ********************************
        
        [ich,qch]=bpskmod(data1,1,nd,ml);
        
        %*************************** Up sample ********************************
        
        [ich1,qch1]= compoversamp(ich,qch,length(ich),IPOINT);
        
        %*************************** Pulse shaping filter ********************************
        
        [ich2,qch2]= compconv(ich1,qch1,xh);
        
        %************************************** Channel************************
        switch multi_path
            case 1
                rtf = [1, 0.6, 0.4];%multi path
                ich3 = filter(sqrt(sum(rtf.*rtf)), rtf, ich2);%filter: built in function
                qch3 = filter(sqrt(sum(rtf.*rtf)), rtf, qch2);
            case 0
                ich3 = ich2;%filter: built in function
                qch3 = qch2;
        end
        
        
        %**************************** Attenuation Calculation ***********************
        
        spow=sum(ich3.*ich3+qch3.*qch3)/nd;  % sum: built in function
        attn=0.5*spow*sr/br*10.^(-ebn0(cnt)/10);
        attn=sqrt(attn);  % sqrt: built in function
        
        %********************* Add White Gaussian Noise (AWGN) **********************
        
        [ich4,qch4]= comb(ich3,qch3,attn);% add white gaussian noise
        
        %*************************** Pulse shaping filter ********************************
        
        [ich5,qch5]= compconv(ich4,qch4,xh2); % receive filtering
        
        %*************************** Synchronization and Down sample ********************************
        
        syncpoint=irfn*IPOINT;
        ich6=ich5(syncpoint:IPOINT:length(ich5));
        qch6=qch5(syncpoint:IPOINT:length(qch5));
        
        %**************************** BPSK Demodulation *****************************
        
        [demodata]=bpskdemod(ich6,qch6,1,nd,ml);
        
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
legend ('BPSK-theory', 'BPSK-simulation');
title('BPSK Simulation');
grid on ;
hold off;
