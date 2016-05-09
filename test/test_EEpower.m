%% testing the EEpower class, for the analysis of power spectra in EEG
es = load('test_EEpower');
eep = EEpower(es.eeg,500)  %#ok<NOPTS>
assert(isequal(eep.NumEpochs, 360))
assert(isequal(eep.SRate, 500))
assert(isequal(eep.Ksize, 2))
assert(isequal(eep.HzMin, 0))
assert(isequal(eep.HzMax, 30))
assert(isequal(eep.spectra, es.spectra))


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

eep = EEpower(s1,500);
% e.setHz(1000);
% e.setEpoch(60);
% e.setHz(500);
% e.setEpoch(10);
% e.setKsize(2);
% e.setHzMin(0);
% e.setHzMax(30);

x = eep.spectra;
plot(x)
