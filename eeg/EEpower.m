classdef EEpower < handle
   %EEpower: power spectra for EEG signals
   %
   % GB: 28 Dec 2015
   
   %----------------------------------------------------------- Properties
   properties (SetAccess = private)
      % default signal sampling rate
      Hz =   500
      % default scoring epoch in seconds
      Epoch = 10
      % kernel size in seconds
      Ksize =  2
      % min and max plotted frequency
      HzMin =  0
      HzMax = 30
      % the number of epochs in the data file
      NumEpochs
      % the EEG signal
      EEG
      % maximum power
      MaxPwr
      % minimum power
      MinPwr
      % maximum log power
      MaxLogPwr
      % minimum log power
      MinLogPwr
   end
   
   properties (Access = private)
      spe    % the number of samples in a single epoch
      spk    % the number of samples in a single kernel
      freqs  % frequency range
      hz_rng % frequency range for plotting (often narrower than above)
      pxx    % the power spectra over time
      dirty  % true if the spectra need recomputing
   end
   
   %------------------------------------------------------- Public Methods
   methods
      %------------------------------------------------------- Constructor
      function obj = EEpower(eeg)
         % store EEG
         obj.EEG = eeg;
         obj.update_parameters
         obj.dirty = true;
      end
      %------------------------------------------------ Return raw spectra
      function rv = spectra(obj, epochs)
         if obj.dirty, obj.setPxx; end
         if nargin < 2, epochs = 1:obj.NumEpochs; end
         rv = obj.pxx(obj.hz_rng, epochs);
      end
      %------------------------------------------------ Return log spectra
      function rv = log_spectra(obj, epochs)
         if nargin < 2, epochs = 1:obj.NumEpochs; end
         rv = 10*log10(obj.spectra(epochs));
         obj.MinLogPwr = min(rv(:));
         obj.MaxLogPwr = max(rv(:));
      end
      %------------------------------------------------ Plot power density
      function rv = power_density_curve(obj, epochs)
         if nargin < 2, epochs = 1:obj.NumEpochs; end
         sa = mean(obj.spectra(epochs), 2);
         rv = semilogy(obj.freqs(obj.hz_rng),sa);
      end
      %-------------------------------------------------- Plot spectrogram
      function rv = spectrogram(obj, epochs)
         if nargin < 2, epochs = 1:obj.NumEpochs; end
         rv = imagesc(obj.log_spectra(epochs));
         set(gca, 'tickdir', 'out')
         axis xy
         colormap(jet(256))
      end
      
      %---------------------------------------------------- Setter methods
      % update parameters whenever a property changes
      % could this be refactored to an event/listener mechanism?
      function setHz(obj, value)
         obj.Hz = value;
         obj.dirty = true;
      end
      
      function setEpoch(obj, value)
         obj.Epoch = value;
         obj.dirty = true;
      end
      
      function setKsize(obj, value)
         obj.Ksize = value;
         obj.dirty = true;
      end
      
      function setHzMin(obj, value)
         obj.HzMin = value;
         obj.dirty = true;
      end
      
      function setHzMax(obj, value)
         obj.HzMax = value;
         obj.dirty = true;
      end
   end
   
   %------------------------------------------------------ Private methods
   methods (Access=private)
      %------------------------------------------------- Calculate spectra
      function setPxx(obj)
         obj.update_parameters
         % preallocate memory for the spectrogram
         obj.pxx = zeros(length(obj.freqs), obj.NumEpochs);
         % generate the Hanning kernel
         ha = hanning(obj.spk);
         % repeat for each epoch
         for ep = 1:obj.NumEpochs
            % get data subset
            idx = (ep-1) * obj.spe+1 : ep * obj.spe;
            data = obj.EEG(idx);
            % compute the spectra
            obj.pxx(:,ep) = pwelch(data, ha, 0, obj.spk, obj.Hz);
         end
         obj.MaxPwr = max(obj.pxx(:));
         obj.MinPwr = min(obj.pxx(:));
      end
            
      function update_parameters(obj)
         % the object will soon be clean
         obj.dirty = false;
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
   end
end
