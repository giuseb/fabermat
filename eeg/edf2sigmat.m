function edf2sigmat(edfname, subjects, channels, outdir)
   % EDF2SIGMAT(EDFNAME, SUBJECTS, CHANNELS, OUTDIR) converts EDF to SigMat
   %
   %     EDFNAME:  a string with the path/name of the EDF source
   %     SUBJECTS: a cell array of strings with the names of the subjects
   %     CHANNELS: a cell array of strings with the channel labels
   %     OUTDIR:   a string with the destination path for SigMats
   %
   % EDF2SIGMAT assumes a specific, orderly arrangement of recorded
   % signals, where blocks of consecutive channels come from the same
   % subject. For example, an EDF containing 32 signals, 4 for each of 8
   % subjects, can be parsed using these arguments:
   %
   %     subjects = {'s1' 's2' 's3' 's4' 's5' 's6' 's7' 's8'};
   %     channels = {'EEG1' 'EEG2' 'EEG3' 'EMG'};
   %
   % SigMat files, one for each subject, are created and placed in the
   % specified output directory.
   %
   % Last modified 1 May 2016
   
   % the counter to keep track of which signal to load next
   signum = 0;
   % instantiating the EDFast
   edf = EDFast(edfname);
   % save the string representation of the recording start datetime
   ds = datestr(edf.RecStart, 'yyyy-mm-dd');
   
   for s = subjects
      subj = s{:};
      % the name of the SigMat output, composed of the two characterizing
      % pieces of information, ie the recording start and the subject name
      ofn = [outdir ds '_' subj];
      sm = SigMat(ofn, edf.RecStart, subj);
      for c = channels
         signum = signum + 1;
         sm.write(c{:}, edf.SigHertz(signum), edf.get_signal(signum));
      end
   end
end

