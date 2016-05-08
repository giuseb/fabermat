%% testing the EEpower class, for the analysis of power spectra in EEG
clear
load EEpower_sample
e = EEpower(eeg,500)  %#ok<NOPTS>
e.setEpoch(10);
e.setKsize(1);
e.setHzMin(0);
e.setHzMax(30);

% s = e.spectra;
p = e.power_density_curve(102);
% e.spectrogram

%%
clear
pars = [
   10, 4;
   16, 3;
   50, 1;
   235, .5
   ];
s1 = signalgen(60, 1000, pars);
plot(s1(1:1000))

e = EEpower(s1,500);
% e.setHz(1000);
% e.setEpoch(60);
% e.setHz(500);
% e.setEpoch(10);
% e.setKsize(2);
% e.setHzMin(0);
% e.setHzMax(30);

x = e.spectra;
plot(x)

%%

f = fft(s1, 30)
