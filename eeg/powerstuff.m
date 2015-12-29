%% power spectrum analysis of EEG signals

%% PREPARING DATA

% we start from an existing EEG trace, for example one contained in a .mat
% file produced by segmentparser2

load('~/data/zurigo/040408-1_43941.mat')
eeg = data.eeg;
clear data

% this particular file has NaNs. For testing purposes, let's force all of
% them to zeros
eeg(isnan(eeg))=0;

%% SETTING UP PARAMETERS

% EEG sampling rate
fs = 500;

% we need to decide the duration of the analysis epoch, which would usually
% match the sleep scoring epoch
epoch = 20; % seconds

% The pwelch analysis (see below) is performed by sliding a kernel over the
% epoch, repeating the calculations, and averaging the results. We want to
% do the sliding without overlap, i.e. with the spectra being computed on
% adjacent kernel windows. Thus, kernel size should be a whole fraction of
% the epoch. Often used kernel sizes range from 2 to 10 seconds.
ksize = epoch/20; % seconds

%% CALCULATING SPECTRA

% the number of samples in a single epoch
spd = epoch*fs;
% the number of samples in a single kernel
spk = ksize*fs;

% the total number of available epochs in the data (note that any trailing
% samples will be ignored)
nepochs = floor(length(eeg)/spd);

% the frequencies; frequency resolution is the inverse of the kernel size;
% maximum frequency is always half of the sampling rate
f = 0:(1/ksize):fs/2;

% preallocate memory for the spectrogram
pxx = zeros(length(f), nepochs);

% generate the Hanning kernel
ha = hanning(spk);

% repeat for each epoch
for ep = 1:nepochs
   % find the indices along the data vector
   i1 = (ep-1)*spd+1;
   i2 = ep*spd;
   % compute the spectra
   pxx(:,ep) = pwelch(eeg(i1:i2), ha, 0, spk, fs);
end

%% PLOTTING SAMPLE POWER DENSITY SPECTRA

% extract and average spectra for a subset of epochs
epoch1 = 100; % the first epoch
epoch2 = 201; % the last epoch

sa = mean(pxx(:, epoch1:epoch2), 2);
semilogy(f,sa)
set (gca, 'xlim', [0 30])

%% PLOTTING THE SPECTROGRAM

% transforming data for better visualization
d = 10*log10(pxx);
imagesc(d, [-100 -40] )
axis xy
colormap(jet)
