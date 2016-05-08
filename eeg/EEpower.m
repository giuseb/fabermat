classdef EEpower < handle
   %EEpower: power density estimates for signals
   %
   % GB: 28 Dec 2015
   
   %----------------------------------------------------------- Properties
   properties (SetAccess = private)
      EEG       % the actual EEG signal
      SRate     % signal sampling rate
   end
   properties (SetObservable)
      Epoch     % scoring epoch in seconds (default is 10)      
      Ksize     % kernel size in seconds (default is 2)
      HzMin     % minimum plotted frequency (default is 0)
      HzMax     % maximum plotted frequency (default is 30)
   end
   properties (SetAccess = private)
      NumEpochs % the number of epochs in the data file
      MaxPwr    % maximum power computed over the entire signal
      MinPwr    % minimum power computed over the entire signal
      MaxLogPwr % maximum log power computed over the entire signal
      MinLogPwr % minimum log power computed over the entire signal
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
      function obj = EEpower(eeg, SRate, varargin)
         p = inputParser;
         p.addRequired( 'EEG',       @isnumvector)
         p.addRequired( 'SRate',     @isnumscalar)
         p.addParameter('Epoch', 10, @isnumscalar)
         p.addParameter('Ksize',  2, @isnumscalar)
         p.addParameter('HzMin',  0, @isnumscalar)
         p.addParameter('HzMax', 30, @isnumscalar)
         p.parse(eeg, SRate, varargin{:})
         
         obj.EEG   = p.Results.EEG;
         obj.SRate = p.Results.SRate;
         obj.Epoch = p.Results.Epoch;
         obj.Ksize = p.Results.Ksize;
         obj.HzMin = p.Results.HzMin;
         obj.HzMax = p.Results.HzMax;
         
         lprops = { 'Epoch' 'Ksize' 'HzMin' 'HzMax' };
         obj.addlistener(lprops, 'PostSet', @obj.HandleProps);
         obj.update_parameters
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
   end
   
   methods (Static)
      function HandleProps(~, event)
         event.AffectedObject.update_parameters
      end
   end
   %------------------------------------------------------ Private methods
   methods (Access=private)
      %------------------------------------------------- Calculate spectra
      function setPxx(obj)
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
            obj.pxx(:,ep) = pwelch(data, ha, [], obj.spk, obj.SRate);
         end
         t = obj.pxx(obj.hz_rng, :);
         obj.MaxPwr = max(t(:));
         obj.MinPwr = min(t(:));
         obj.dirty = false;
      end
            
      function update_parameters(obj)
         % spectra will have to be recomputed after this
         obj.dirty = true;
         % the number of samples in a single kernel
         obj.spk       = obj.Ksize * obj.SRate;
         % the number of samples in a single epoch
         obj.spe       = obj.Epoch * obj.SRate;
         % the number of available epochs in the data file
         obj.NumEpochs = floor(length(obj.EEG)/obj.spe);
         % frequency range; resolution is the inverse of kernel size;
         % maximum frequency is always half of the sampling rate
         obj.freqs     = 0:(1/obj.Ksize):obj.SRate/2;
         % frequency range for plotting purposes; very high frequencies
         % are often useless
         obj.hz_rng = find(obj.freqs >= obj.HzMin & obj.freqs < obj.HzMax);
      end
   end
end
