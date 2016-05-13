function rv = signalgen(seconds, sampling_rate, params, noise)
   % SIGNALGEN   generating simple signals by summing sinusoidal waves
   %
   %     SIGNALGEN(SECONDS, SAMPLING_RATE, PARAMS, NOISE)
   %     generates a SECONDS-long signal at SAMPLING_RATE Hertz, with the
   %     given PARAMS. The latter is a two-column numerical matrix, where
   %     each row defines a sinusoidal wave. The first column is the
   %     periodicity in Hertz, the second is the amplitude.
   %     With a single PARAMS row, the signal is a perfect sinusoid; the
   %     more rows are added, the noisier the signal.
   %     White noise of NOISE amplitude is added, if the argument is
   %     provided.
   %
   % Last modified: 6 May 2016
   
   if ~isnumeric(params) || size(params,2) ~= 2
      error('PARAMS should be a two-column numerical matrix')
   end
   % the number of overlapping signals
   harmonics = size(params,1);
   % the temporal line
   t = repmat(0:1/sampling_rate:seconds, harmonics, 1);
   % laying out params
   wave_hz   = repmat(params(:,1), 1, size(t,2));
   amplitude = repmat(params(:,2), 1, size(t,2));
   % computing the signal
   rv = sum(amplitude .* sin(2*pi*wave_hz.*t), 1);
   if nargin==4
      rv = rv + randn(size(rv)) * noise;
   end
end