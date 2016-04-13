function sig = siggrab(fn, sig, dt, dur)
   %SIGGRAB(FN, SIG, DT, DUR)   extract signal data from a .MAT file
   %
   % FN:  the path/name of a .MAT file containing the signals
   % SIG: the signal label, i.e. the name of the variable containing it
   % DT:  the day and time at which to start extracting data; it can be any
   %      input accepted by the function DATETIME; simple examples are:
   %      21-Aug-2016 21:15:00
   %      2016-08-21 0:00
   % DUR: length of signal in hours
   mf = matfile(fn);
   
   
end