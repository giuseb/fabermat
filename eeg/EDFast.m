classdef EDFast < handle
   %EDFast: efficiently import EDF signals into matrices
   %
   % Create an EDFast object from an EDF file:
   % >> edf = EDFast('data.edf')
   %
   % Set verbosity to get information in the Command Window while
   % processing (default is false to reduce clutter)
   % >> edf.Verbose = true
   %
   % By changing the processing block size, you may improve execution
   % speed. Optimal values depend on available PC memory, duration of
   % recordings, and number of channels. You need to experiment.
   % >> edf.RecordsPerBlock = 1000
   %
   % Retrieve the specified signal (default is 1, if parameter is omitted)
   % >> sig = edf.get_signal(2);
   %
   %
   % Inspired by Dennis A. Dean's blockEdfLoadClass
   % http://www.mathworks.com/matlabcentral/fileexchange/45227-blockedfloadclass
   % https://github.com/DennisDean/BlockEdfLoadClass
   % Some of his code is still here.
   %
   % Here, the focus is to extract one signal at a time,
   % especially for very large data files.
   %
   % GB: 28 Dec 2015
   
   
   %----------------------------------------------------------- Properties
   properties (Access = public)
      Verbose = false
      RecordsPerBlock = 100
      ActiveSignal = 1
   end
   
   properties (SetAccess = private)
      Filename
   end
   
   properties (Access = private)
      headSize = 256
      headVars = {
         'edf_ver';
         'patient_id';
         'local_rec_id';
         'recording_startdate';
         'recording_starttime';
         'num_header_bytes';
         'reserve_1';
         'num_data_records';
         'data_record_duration';
         'num_signals'
         }
      headVarsConF = {
         @strtrim; @strtrim; @strtrim; @strtrim; @strtrim;
         @str2num; @strtrim; @str2num; @str2num; @str2num
         }
      headVarSize = [8 80 80 8 8 8 44 8 8 4]
      sigHeadVar = {
         'signal_labels';
         'tranducer_type';
         'physical_dimension';
         'physical_min';
         'physical_max';
         'digital_min';
         'digital_max';
         'prefiltering';
         'samples_in_record';
         'reserve_2'
         };
      sigHeadVarConvF = {
         @strtrim; @strtrim; @strtrim; @str2num; @str2num;
         @str2num; @str2num; @strtrim; @str2num; @strtrim
         }
      sigHeadVarSize = [16 80 8 8 8 8 8 80 8 32]
      
   end
   
   properties (SetAccess = private)
      Header = struct
      SignalHeader = struct(...
         'signal_labels', {}, ...
         'tranducer_type', {}, ...
         'physical_dimension', {}, ...
         'physical_min', {}, ...
         'physical_max', {}, ...
         'digital_min', {}, ...
         'digital_max', {}, ...
         'prefiltering', {}, ...
         'samples_in_record', {}, ...
         'reserve_2', {});
   end
   
   %------------------------------------------------------- Public Methods
   methods
      %------------------------------------------------------- Constructor
      function obj = EDFast(filename)
         obj.Filename = filename;
         % Open the input file
         [fid, msg] = fopen(filename);
         if fid < 0, error(msg); end
         % Load header data
         A = fread(fid, obj.headSize);
         % Place header data into its structure
         hvl = [0, cumsum(obj.headVarSize)];
         for h = 1:length(obj.headVars)
            conF = obj.headVarsConF{h};
            value = conF(char((A(hvl(h)+1:hvl(h+1)))'));
            obj.Header.(obj.headVars{h}) = value;
         end         
         % Load Signal Header data
         ss = obj.Header.num_header_bytes - sum(obj.headVarSize);
         A = fread(fid, ss);
         % Place signal header data into its structure
         ns = obj.Header.num_signals;
         svl = [0, cumsum(obj.sigHeadVarSize*ns)];
         for v = 1:length(obj.sigHeadVar)
            varBlock = A(svl(v)+1:svl(v+1))';
            varSize = obj.sigHeadVarSize(v);
            conF = obj.sigHeadVarConvF{v};
            for s = 1:ns
               range = varSize*(s-1)+1:varSize*s;
               value = conF(char(varBlock(range)));
               obj.SignalHeader(s).(obj.sigHeadVar{v}) = value;
            end
         end
         fclose(fid);
      end
      
      % Return an entire signal as a vector
      function rv = get_signal(obj, sig)
         % Save argument to current Signal, if passed
         if nargin > 1, obj.ActiveSignal = sig; end
         % Open the input file
         [fid, msg] = fopen(obj.Filename);
         if fid < 0, error(msg); end
         % move file pointer past the header
         fseek(fid, obj.Header.num_header_bytes, -1);
         % allocate memory for the entire digital signal
         if obj.Verbose, fprintf('Allocating %d bytes\n', obj.SSize*2); end
         A = zeros(obj.SSize, 1, 'int16');
         if obj.Verbose, disp('Done.'); end
         % process data in chunks
         for block = 1:obj.NumMemBlocks
            a = fread(fid, obj.BlockSize, 'int16');
            t = obj.SigMask;
            t(length(a)+1:end) = [];
            A(obj.BlockRange(block)) = a(t);
            if obj.Verbose
               fprintf('Read block #%d of %d\n', block, obj.NumMemBlocks);
            end
         end
         fclose(fid);
         % convert to analog
         dm = obj.SignalHeader(obj.ActiveSignal).digital_min;
         dx = obj.SignalHeader(obj.ActiveSignal).digital_max;
         rv = (double(A) - (dx+dm)/2) / (dx-dm);
         if obj.SignalHeader(obj.ActiveSignal).physical_min > 0
            rv = -rv;
         end
      end
   end
   %---------------------------------------------------- Private functions
   methods (Access=private)
      % Length = seconds, or number of records
      % Size   = samples
      % Range  = array used as index
      
      % range for the current block
      function rv = BlockRange(obj, block)
         r = [0:obj.SRSize*obj.RecordsPerBlock:obj.SSize, obj.SSize];
         rv = (r(block)+1 : r(block+1))';
      end
      
      % the total number of samples for the active signal
      function rv = SSize(obj)
         rv = obj.SRSize * obj.Header.num_data_records;
      end
      
      % to extract the active signal from a loaded record
      function rv = SigMask(obj)
         a = false(obj.DRSize, 1);
         a(obj.DRSigRange) = true;
         rv = repmat(a, obj.RecordsPerBlock, 1);
      end
      
      % number of samples read on each iteration while loading signals
      function rv = BlockSize(obj)
         rv = obj.RecordsPerBlock * obj.DRSize;
      end
      
      % the number of iterations to read signals from the entire data file
      function rv = NumMemBlocks(obj)
         rv = ceil(obj.Header.num_data_records / obj.RecordsPerBlock);
      end
      
      % number of samples per record, for the active signal
      function rv = SRSize(obj)
         rv = obj.SignalHeader(obj.ActiveSignal).samples_in_record;
      end

      % within-record range for the active signal
      function rv = DRSigRange(obj)
         cum = [0, cumsum(obj.DRSizes)];
         rv = cum(obj.ActiveSignal)+1 : cum(obj.ActiveSignal+1);
      end
      
      % data record size broken down by signal
      function rv = DRSizes(obj)
         rv = [obj.SignalHeader.samples_in_record];
      end
      
      % overall data record size
      function rv = DRSize(obj)
         rv = sum(obj.DRSizes);
      end
   end
end
