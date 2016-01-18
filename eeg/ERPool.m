classdef ERPool < handle
   properties (SetAccess = private)
      Hz = 4000
      baseline = 200
      response = 600
   end
   
   properties (Access = private)
      eeg
      idx
      codes
      dirty
      matz
      KHz
   end
   
   methods
      function obj = ERPool(eeg, event_idx, event_code)
         obj.eeg  = eeg;
         obj.idx  = event_idx;
         obj.codes = event_code;
         obj.dirty = true;
      end
      
      function rv = average(obj, code)
         if obj.dirty, obj.create_mat; end
         t = obj.matz(obj.codes==code, :);
         rv = mean(t);
      end
      
      function rv = time_range(obj)
         if obj.dirty, obj.create_mat; end
         rv = 1-obj.baseline:1/obj.KHz:obj.response;
      end
      
      function setHz(obj, value)
         obj.Hz = value;
         obj.dirty = true;
      end
      
      function setBaseLine(obj, value)
         obj.baseline = value;
         obj.dirty = true;
      end
      
      function setResponse(obj, value)
         obj.response = value;
         obj.dirty = true;
      end
   end
   
   methods (Access=private)
      function create_mat(obj)
         obj.KHz = obj.Hz / 1000;
         bl = obj.baseline * obj.KHz;
         rs = obj.response * obj.KHz;
         obj.matz = zeros(length(obj.codes), bl+rs);
         for n = 1:length(obj.idx)
            ce = obj.idx(n);
            first = ce-bl+1;
            last = ce+rs;
            obj.matz(n, :) = obj.eeg(first:last);
         end
         obj.dirty = false;
      end
   end
 end