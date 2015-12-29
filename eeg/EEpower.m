classdef EEpower < handle
   %EEpower: power spectra for EEG signals
   %
   % GB: 28 Dec 2015
   
   %----------------------------------------------------------- Properties
   properties (Access = public)
      % default signal sampling rate
      Hz =   500
      % default scoring epoch in seconds
      Epoch = 10
      % kernel size in seconds
      Ksize =  2
      % min and max plotted frequency
      HzMin =  0
      HzMax = 30
   end
   
   properties (Access = private)
      spe    % the number of samples in a single epoch
      spk    % the number of samples in a single kernel
      freqs  % frequency range
      hz_rng % frequency range for plotting (often narrower than above)
   end
   
   properties (SetAccess = private)
      % the number of epochs in the data file
      NumEpochs
      % the EEG signal
      EEG
      % the power spectra over time
      Pxx
   end
   
   %------------------------------------------------------- Public Methods
   methods
      %------------------------------------------------------- Constructor
      function obj = EEpower(eeg)
         % store EEG
         obj.EEG = eeg;
         % update parameters
         obj.update_parameters;
         % store number of available epochs
         % (note that any trailing samples will be ignored)
         obj.NumEpochs = floor(length(eeg)/obj.spe);
      end
      
      %------------------------------------------------- Calculate spectra
      function rv = spectra(obj)
         obj.update_parameters;
         % preallocate memory for the spectrogram
         obj.Pxx = zeros(length(obj.freqs), obj.NumEpochs);
         % generate the Hanning kernel
         ha = hanning(obj.spk);
         % repeat for each epoch
         for ep = 1:obj.NumEpochs
            % get data subset
            data = obj.EEG(obj.sliding_idx(ep));
            % compute the spectra
            obj.Pxx(:,ep) = pwelch(data, ha, 0, obj.spk, obj.Hz);
         end
         rv = obj.Pxx;
      end
      
      %------------------------------------------------ Plot power density
      function rv = power_density_curve(obj, epochs)
         obj.ensure_uptodate;
         sa = mean(obj.Pxx(obj.hz_rng, epochs), 2);
         rv = semilogy(obj.freqs(obj.hz_rng),sa);
      end
      
      %-------------------------------------------------- Plot spectrogram
      function rv = spectrogram(obj, epochs)
         obj.ensure_uptodate;
         if nargin < 2, epochs = 1:obj.NumEpochs; end
         % transforming data for better visualization
         d = 10*log10(obj.Pxx(obj.hz_rng, epochs));
         rv = imagesc(d, [-100 -40]);
         axis xy
         colormap(jet)
      end
   end
   %---------------------------------------------------- Private functions
   methods (Access=private)
      
      function ensure_uptodate(obj)
         if isempty(obj.Pxx), obj.spectra; end
         obj.update_parameters;
      end
      
      function update_parameters(obj)
         % the number of samples in a single kernel
         obj.spk       = obj.Ksize * obj.Hz;
         % the number of samples in a single epoch
         obj.spe       = obj.Epoch * obj.Hz;
         % the number of available epochs in the data file
         obj.NumEpochs = floor(length(obj.EEG)/obj.spe);
         % frequency range; resolution is the inverse of kernel size;
         % maximum frequency is always half of the sampling rate
         obj.freqs     = 0:(1/obj.Ksize):obj.Hz/2;
         % frequency range for plotting purposes; very high frequencies
         % are often useless
         obj.hz_rng = find(obj.freqs >= obj.HzMin & obj.freqs <= obj.HzMax);
      end
      
      function rv = sliding_idx(obj, n)
         rv = (n-1) * obj.spe+1 : n * obj.spe;
      end
   end
end
