classdef HypnoAnal < handle
   %HypnoAnal: simple calculations on hypnograms
   %
   %   ha = HypnoAnal(hyp)
   %
   %   where hyp is a numerical vector, builds the object. The following
   %   name/value pair parameters may be added:
   %
   %   ha = HypnoAnal(hyp, 'Epoch', s) specifies the epoch duration in
   %   seconds (default is 10)
   %
   %   ha = HypnoAnal(hyp, 'Stages', {'REM', 'NREM', 'Wake'}) specifies the
   %   stages (the ones shown here are the defaults); every "1" in the
   %   hystogram vector is interpreted as 'REM', every "2" is 'NREM', and
   %   so on.
   %
   %   After constructions, you can execute any of the following:
   %
   %   ha.tot_epochs
   %   ha.tot_seconds
   %   ha.tot_minutes
   %   ha.n_episodes
   %   ha.durations
   %   ha.mean_sec_durations
   %   ha.std_sec_durations
   %
   %   All these functions return an array with as many elements as there
   %   are stages, in the order specified as above.
   
   %----------------------------------------------------------- Properties
   properties (SetAccess = private)
      hypno
      changes
      stages
      epoch
   end
   %------------------------------------------------------- Public Methods
   methods
      %------------------------------------------------------- Constructor
      function obj = HypnoAnal(hypnogram, varargin)
         p = inputParser;
         p.addRequired( 'hypnogram', @isnumvector)
         p.addParameter('Epoch', 10, @isnumscalar)
         p.addParameter('Stages', {'REM', 'NREM', 'Wake'}, @iscellstr)
         p.parse(hypnogram, varargin{:})

         % assumes a vector
         obj.hypno  = p.Results.hypnogram(:); % enforce vertical!
         obj.stages = p.Results.Stages;
         obj.epoch  = p.Results.Epoch;
         obj.changes = [1; diff(obj.hypno)];
      end
      
      function rv = tot_seconds(obj)
         rv = obj.tot_epochs * obj.epoch;
      end
      
      function rv = tot_minutes(obj)
         rv = obj.tot_seconds / 60;
      end
      
      function rv = n_episodes(obj)
         for i=1:obj.n_stages
            rv(i) = sum(obj.hypno==i & obj.changes ~= 0); %#ok<AGROW>
         end
      end
      
      function rv = mean_sec_durations(obj)
         d = obj.durations;
         for i = 1:obj.n_stages
            rv(i) = mean(d{i} * obj.epoch); %#ok<AGROW>         
         end
      end
      
      function rv = std_sec_durations(obj)
         d = obj.durations;
         for i = 1:obj.n_stages
            rv(i) = std(d{i} * obj.epoch); %#ok<AGROW>         
         end
      end
      
      function rv = durations(obj)
         n = obj.n_stages;
         % set up the cell array to be returned
         rv = cell(1, n);
         % use the first epoch as a starting point
         c_stg = obj.hypno(1);
         c_len = 1;
         % loop over each epoch
         for i=2:length(obj.hypno)
            if obj.changes(i)
               rv{c_stg} = [rv{c_stg}; c_len];
               c_stg = obj.hypno(i);
               c_len = 1;
            else
               c_len = c_len + 1;
            end
         end
         rv{c_stg} = [rv{c_stg}; c_len];
      end
      
      function rv = tot_epochs(obj)
         for i=1:obj.n_stages
            rv(i) = sum(obj.hypno==i); %#ok<AGROW>
         end
      end
      
      function rv = n_stages(obj)
         rv = length(obj.stages);
      end
   end
end