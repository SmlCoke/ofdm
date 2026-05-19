
clc
clear
load('bpsk_theory.mat');
ebn0_theory_1 = ebn0_theory;
ber_theory_1 = ber_theory;

load('qpsk_theory.mat');
ebn0_theory_2 = ebn0_theory;
ber_theory_2 = ber_theory;

load('QAM16_theory.mat');
ebn0_theory_3 = ebn0_theory;
ber_theory_3 = ber_theory;

load('QAM64_theory.mat');
ebn0_theory_4 = ebn0_theory;
ber_theory_4 = ber_theory;

load('16psk_theory.mat');
ebn0_theory_5 = ebn0_theory;
ber_theory_5 = ber_theory;

load('64psk_theory.mat');
ebn0_theory_6 = ebn0_theory;
ber_theory_6 = ber_theory;

figure;
hold on ;
grid on ;
axis([0 8.5 1.0e-4, 3.0e-1]);
semilogy (ebn0_theory_1, ber_theory_1,'-ko','linewidth',3,'MarkerSize',8);
semilogy (ebn0_theory_2, ber_theory_2,'-rs','linewidth',3,'MarkerSize',8);
semilogy (ebn0_theory_3, ber_theory_3,'-b^','linewidth',3,'MarkerSize',8);
semilogy (ebn0_theory_4, ber_theory_4,'-gd','linewidth',3,'MarkerSize',8);
semilogy (ebn0_theory_5, ber_theory_5,'-yo','linewidth',3,'MarkerSize',8);
semilogy (ebn0_theory_6, ber_theory_6,'-mo','linewidth',3,'MarkerSize',8);

legend ('BPSK-theory', 'QPSK-theory', '16-QAM-theory', '64-QAM-theory', '16-PSK-theory', '64-PSK-theory');
title('Theoretical BER for BPSK, QPSK, 16-QAM, 64-QAM, 16-PSK and 64-PSK');

hold off;
