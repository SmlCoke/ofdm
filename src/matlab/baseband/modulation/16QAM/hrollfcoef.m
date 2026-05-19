
% hrollfcoef.m
% Generate coefficients of Nyquist filter
% Nyquist，奈奎斯特
function [xh] = hrollfcoef(irfn,ipoint,sr,alfs,ncc)

%****************** variables *************************
% irfn	 : Number of symbols to use filtering抽头数
% ipoint : Number of samples in one symbol上采样数
% sr     : symbol rate
% alfs   : rolloff coeficiense升余弦滤波器的滚降系数
% ncc    : 1 -- transmitting filter  0 -- receiving filter
% *****************************************************

% xi=zeros(1,irfn*ipoint+1);
% xq=zeros(1,irfn*ipoint+1);
% aaa=[];
% point = ipoint;
% 符号周期T=1/sr，采样周期tstp=1/(sr*ipoint)
tr = sr ;
tstp = 1.0 / tr / ipoint;
% 滤波器长度
n = ipoint * irfn;
% mid = ( n ./ 2 ) + 1;RRC关于中心对称
mid = (n + 1) / 2;
sub1 = 4.0 * alfs * tr;		% 4*alpha*R_s

for i = 1 : n
    
    icon = i - mid;
    ym = icon;
    %         aaa=[aaa, ym];
    
    if abs(icon) < eps % eps: MATLAB内置函数，表示一个非常小的数，通常用来判断两个数是否相等，这里判断icon是否为0，即i是否为mid
        xt = (1.0-alfs+4.0.*alfs./pi).* tr;  % h(0)，单独求极限
    else
        sub2 =16.0.*alfs.*alfs.*ym.*ym./ipoint./ipoint; % 普通情况的公式(4*alpha*R_s*t)^2
        if abs(sub2-1) > eps
            x1=sin(pi*(1.0-alfs)/ipoint*ym)./pi./(1.0-sub2)./ym./tstp;
            x2=cos(pi*(1.0+alfs)/ipoint*ym)./pi.*sub1./(1.0-sub2);
            xt = x1 + x2;  % h(t) plot((1:length(xh)),xh)
        else % (4alphaRst)^2 = 1plot((1:length(xh)),xh) 代表sub2=±1的情况，特殊求极限
            xt = alfs.*tr.*((1.0-2.0/pi).*cos(pi/4.0/alfs)+(1.0+2.0./pi).*sin(pi/4.0/alfs))./sqrt(2.0);
        end  %  if sub2 ~= 1.0
    end	%  if icon == 0.0
    
% 发射端脉冲成型滤波器和接收端匹配滤波器都是在上采样之后，下采样之前
% 接收端需要除以ipoint，发送端不需要
% 连续时间中，根升余弦/升余弦滤波器通常满足能量积分为Rs
% 这里的归一化是为了保证滤波器的能量为1，即满足Nyquist准则，避免码间干扰（ISI）。
% 对于接收端，由于上采样后每个符号被分成了ipoint个采样点，类似于8个点直接相加，因此需要除以ipoint来进行归一化。而对于发送端，上采样插值为0，因此不需要除以ipoint。
% 还是不太懂
    if ncc == 0	                        % in the case of receiver
        xh( i ) = xt ./ ipoint ./ tr;	% normalization
    elseif ncc == 1 % in the case of transmitter
        xh( i ) = xt ./ tr;          % normalization
    else
        error('ncc error');
    end    %  if ncc == 0
    
end  % for i = 1 : n
% aaa
% a=0;


%******************** end of file ***************************
