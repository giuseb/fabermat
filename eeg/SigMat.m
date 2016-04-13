classdef SigMat < handle
   % SigMat: managing our own .MAT files containing eeg/emg signals
   
   properties (SetAccess = private)
      SigMatPath
      RecStart
      Hertz
   end
   
   properties(Access=private)
      MatFileObj
   end
   
   methods
      % -----------------------------------------------------> Constructor
      function obj = SigMat(fn, start, hertz)
         % initialize the matfile in a temporary var
         mf = matfile(fn, 'writable', true);
         switch nargin
            case 3 % creating a new SigMat
               if exist(fn, 'file')
                  error('A .MAT file by that name already exists')
               else
                  mf.start = datetime(start);
                  mf.hertz   = hertz;
               end
               
            case 1 % opening an existing SigMat
               if exist(fn, 'file')
                  % find out if the existing file is valid
                  vars = whos(mf);
                  % try to find the rec_start datetime
                  rsi = find(strcmp({vars.name}, 'rec_start'), 1);
                  % try to find the rec_end datetime
                  rei = find(strcmp({vars.name}, 'rec_end'), 1);
                  if isempty(rsi) || isempty(rei)
                     error('A .MAT file exists, but it does not contain time stamps')
                  end
               else
                  error('The .MAT file does not exist')
               end
            otherwise
               error('Wrong number of arguments')
         end
         % store away the matfile, for subsequent use
         obj.MatFileObj = mf;
         obj.SigMatPath = mf.Properties.Source;
         obj.Hertz      = mf.hertz;
         obj.RecStart   = mf.start;
      end
      
      function write(obj, label, signal)
         obj.MatFileObj.(label) = signal;
      end
      
      function rv = read(obj, label, start, finish)
         if nargin==2
            rv = obj.MatFileObj.(label);
         elseif nargin==4
            dtstart = datetime(start);
            dtfin   = datetime(finish);
            if dtstart > dtfin
               error('start occurs after end')
            end
            istart = seconds(dtstart-obj.RecStart) * obj.Hertz + 1;
            iend   = seconds(dtfin  -obj.RecStart) * obj.Hertz;
            rv = obj.MatFileObj.(label)(istart:iend,1);
         else
            error('Invalid number of arguments')
         end
      end
   end
   
   methods (Access=private)
      
   end
end