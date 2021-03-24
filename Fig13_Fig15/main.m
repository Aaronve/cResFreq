%% Wide Band LFM Echo for ISAR
clear all;
close all
clc
% format long
%% �״������������
C=299792458;                    %����
% C=3e8;
FC=9e9;                         %����Ƶ��
FS=1e9;                         %����Ƶ��
TS=1/FS;                        %�������
rng_gate_res=C/2/FS;            %���벨�ŷֱ���
BW=0.3e9;                         %����
PRF=1;                        %�����ظ�Ƶ��
PRI=1/PRF;                      %�����ظ����
TW=100e-6;                      %������
sweep_slope=BW/TW;              %��Ƶ��
n_pulse=512;                     %��������
% r_rwnd=15900;                   %���Ŵ�С�����룩
% t_rwnd=2*r_rwnd/C;              %���Ŵ�С��ʱ�䣩
% n_rwnd=ceil(t_rwnd/TS);         %���Ŵ�С��������
n_rwnd=120000;
df=1/TW;   
%-------------------------------------------------------------------------%
%% ɢ���ģ�ͽ���
center=[8000,0,0];                                             %ģ������
x=[0,-1,-1,-6.5,-6.5,-1,-1,-2.5,-2.5,2.5,2.5,1,1,6.5,6.5,1,1]+center(1);      %ɢ����������
y=[9,7,4,0.5,-1,0,-2.5,-3.5,-4,-4,-3.5,-2.5,0,-1,0.5,4,7];



theta=0;
for i=1:length(x)
    huai=atan2(y(i)-center(2),x(i)-center(1));
    xx(i)=sqrt((x(i)-center(1))^2+(y(i)-center(2))^2)*cos(huai+theta)+center(1);
    yy(i)=sqrt((x(i)-center(1))^2+(y(i)-center(2))^2)*sin(huai+theta);
end
x=xx;
y=yy;


n_tgt=length(x);                                %ɢ�����Ŀ

%-------------------------------------------------------------------------%
%% ��ת�ٶȡ��ٶȡ����ٶȡ����ȡ������ų�ʼ����
%��ת�ٶȲ��ܹ��죬�迼�Ǿ��뵥Ԫ��С�Ĺ�ϵ
%Ŀ���ٶ�ֵѡȡ���迼����PRI�����Ÿı�ʱ�䡢���Ŵ�С�Ĺ�ϵ
%Ŀ����ٶȲ��ܹ��󣬷�����پ��Ƚ��ͣ�Ӱ�첹��Ч��
rotate_w=0.15;
tgt_vel=zeros(n_pulse,n_tgt);                 %Ŀ���ٶ�
tgt_dist=zeros(n_pulse,n_tgt);                %Ŀ�����
rng_gate=zeros(n_pulse,1);                    %������ǰ��

sig_echo=[];                                  %�����ź�
tgt_dist_init=zeros(n_tgt,1);                 %Ŀ���ʼ����
tgt_vel_init=zeros(n_tgt,1);                  %Ŀ���ʼ�ٶ�
tgt_acc_init=zeros(n_tgt,1);                  %Ŀ���ʼ���ٶ�
amp=zeros(n_tgt,1);                           %�����źŷ���
time_rec=[];
for k = 1:n_tgt
    tgt_dist_init(k)=center(1);           %Ŀ���ʼ����
    tgt_vel_init(k)=0;                      %Ŀ���ʼ�ٶ�
    tgt_acc_init(k)=0;                        %Ŀ����ٶ�
    amp(k)=1;                                 %Ŀ�귴��ϵ��Ȩֵ
end
%-------------------------------------------------------------------------%
%% ����LFM�ز��ź�
%����ο��ź�
dt=TS;
t=dt:dt:n_rwnd*dt;
sig_ref=exp(1i*sweep_slope*pi*t.*t);          %���زο��ź�
sig_dechirped=[];
%�����ز��źţ�ȥб���²�����
ll=1;  
SNR=20;
%�������̶�
bz=n_pulse;
for j = 1:n_pulse
    h=waitbar(ll/n_pulse);                    %������    
    ll=ll+1;
%-------------------------------------------------------------------------%    
    %Ŀ��ģ��
    for k = 1:n_tgt
        %��ת
        theta=atan2(y(k)-center(2),x(k)-center(1));
        RR(j,k)=sqrt((x(k)-center(1))^2+(y(k)-center(2))^2)*cos(theta+rotate_w*(j-1)/180*pi)+center(1);

        %ƽ��
        tgt_vel(j,k)=tgt_vel_init(k)+(j-1)*tgt_acc_init(k)*PRI;
        tgt_dist(j,k)=tgt_dist_init(k)+tgt_vel_init(k)*((j-1)*PRI)...
                +tgt_acc_init(k)*((j-1)*PRI)^2/2+RR(j,k);
    end
 %-------------------------------------------------------------------------%
    %�������ƶ���ÿ���̶��������ƶ�һ��
     if j==1  
        rng_gate(j)=floor(min(tgt_dist(j,:)-C*TW/4-C*TW/128)/rng_gate_res)*rng_gate_res;
     else 
        rng_gate(j)=rng_gate(j-1);
     end
%-------------------------------------------------------------------------%    
    %��¼ʱ��
    time_rec(j)=(j-1)*PRI;
%-------------------------------------------------------------------------%    
    %�����ź�
    sig_echo=EchoSignalGen(TW,BW,rng_gate(j),n_rwnd,tgt_dist(j,:),amp.',FC,TS);
%     figure;plot(real(sig_echo));
%-------------------------------------------------------------------------%    
    %ȥб���²������²����������ܹ����迼���²�����Ĳ���Ƶ����ȥб�źŴ����ϵ����ֹ�����
    sig_dechirped=(sig_echo).*(conj(sig_ref));
    sig_dechirped_ds=sig_dechirped;
    tmp1=wgn(size(sig_dechirped_ds,1),size(sig_dechirped_ds,2),0,'complex');
    sqrt(mean((abs(sig_dechirped_ds)).^2))
    sig_dechirped_ds=sig_dechirped_ds/sqrt(mean((abs(sig_dechirped_ds)).^2));
    sig_dechirped_ds_1=sig_dechirped_ds*10^(SNR/20)+tmp1;
    
    sig_dechirped_down(j,:)=sig_dechirped_ds_1(1:1625:104000);
    
    RPP(j,:)=sig_dechirped_down(j,:)/max((abs(sig_dechirped_down(j,:))));
end
df=df*size(sig_dechirped_ds_1,2)/64;
nfft=4096;
deltaR=3e8/2/df/nfft;
r=(-(nfft-1)/2:(nfft-1)/2).*deltaR;

if ~exist('matlab_real2.h5','file')==0
    delete('matlab_real2.h5')
end

if ~exist('matlab_imag2.h5','file')==0
    delete('matlab_imag2.h5')   
end


if ~exist('bz.h5','file')==0
    delete('bz.h5')   
end

h5create('matlab_real2.h5','/matlab_real2',size(RPP));
h5write('matlab_real2.h5','/matlab_real2',real(RPP));
h5create('matlab_imag2.h5','/matlab_imag2',size(RPP));
h5write('matlab_imag2.h5','/matlab_imag2',imag(RPP));
h5create('bz.h5','/bz',size(bz));
h5write('bz.h5','/bz',bz)

system('D:\ProgramData\Anaconda3\envs\complexPytorch-gpu\python.exe resfreq_model.py')
load data1_resfreq.mat
% for i=1:bz
%     data_resfreq_norm(i,:)=data1_resfreq(i,:)/max(abs(data1_resfreq(i,:)));
% end
win=ones(size(sig_dechirped_down,1),1)*hamming(64).';
spc=fftshift(abs(fft(sig_dechirped_down.*win,4096,2)),2);
fsz=13;
h=figure();
set(h,'position',[100 100 800 400]);
ha=tight_subplot(1,2,[0.05 0.05],[.2 .08],[.08 .01]);
axes(ha(1))
plot(r,spc(1,:)./max(spc(1,:)),'k-.','linewidth',2);
set(gca,'FontSize',fsz); 
set(get(gca,'XLabel'),'FontSize',fsz);
set(get(gca,'YLabel'),'FontSize',fsz);
title('periodogram');
xlabel({'Range / m';'(a)'});
ylabel('Normalized Amp.');
xlim([-8 13])


axes(ha(2))
plot(r,abs(data1_resfreq(1,:))/max(abs(data1_resfreq(1,:))),'k-.','linewidth',2);
set(gca,'FontSize',fsz); 
set(get(gca,'XLabel'),'FontSize',fsz);
set(get(gca,'YLabel'),'FontSize',fsz);
title('cResFreq');
xlabel({'Range / m';'(b)'});
ylabel('Normalized Amp.');
xlim([-8 13])

h=figure();
set(h,'position',[100 100 800 400]);
ha=tight_subplot(1,2,[0.05 0.05],[.2 .08],[.08 .01])

axes(ha(1))
win=ones(size(sig_dechirped_down,1),1)*hamming(64).';
spc=fftshift(abs(fft(sig_dechirped_down.*win,4096,2)),2);
imagesc(r,1:512,spc);
set(gca,'FontSize',fsz); 
set(get(gca,'XLabel'),'FontSize',fsz);
set(get(gca,'YLabel'),'FontSize',fsz);
title('cResFreq');
xlabel({'Range / m';'(a)'});
ylabel('Pulse Index');
% xlim([-10 10])

axes(ha(2))
imagesc(r,1:512,abs(data1_resfreq))
set(gca,'FontSize',fsz); 
set(get(gca,'XLabel'),'FontSize',fsz);
set(get(gca,'YLabel'),'FontSize',fsz);
title('cResFreq');
xlabel({'Range / m';'(b)'});
% xlim([-10 10])
x=1

%%

