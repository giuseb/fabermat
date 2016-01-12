%% testing the sleeper GUI
clear
clear classes %#ok<*CLSCR>
load test_sleeper.mat
sleeper(eeg, emg)

%% looking at power spectra over SWD episodes

% there's a nice one at
epo=56;
sec_start = 3.2;
sec_end   = 5.3;

idx1 = 5000 * epo + sec_start * 500 + 1;
idx2 = 5000 * epo + sec_end * 500;

swd = eeg(idx1:idx2);
subplot(1,2,1)
plot(swd)
subplot(1,2,2)
e = EEpower(swd);
e.setEpoch(2);
e.power_density_curve(1)