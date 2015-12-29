%% testing the EEpower class, for the analysis of power spectra in EEG
clear
load EEpower_sample
e = EEpower(eeg)  %#ok<NOPTS>
e.Epoch = 10;
e.power_density_curve(100:150);
