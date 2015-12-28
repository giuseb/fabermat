%%%%%%%%%%%%%%%%%%%%%%%%%
% testing EDFast class
%%%%%%%%%%%%%%%%%%%%%%%%%
% We need a way to import large EDF files into Matlab. EEGLAB is not very
% efficient. Let's start from blockEdfLoadClass, downloaded from
% http://www.mathworks.com/matlabcentral/fileexchange/45227-blockedfloadclass
%
% test_generator_hiRes.edf contains 450 seconds of 5 sinusoidal signals
% (https://github.com/DennisDean/BlockEdfDeidentify)
% Following code run once in order to use returned signals for testing:
%
% e = BlockEdfLoadClass('test_generator_hiRes.edf');
% e = e.blockEdfLoad;
% BELC_test = e.edf.signalCell;
% save('test_EDFast.mat', 'BELC_test')
%
% Now we can test EDFast:
clear
load test_EDFast
e = EDFast('test_generator_hiRes.edf') %#ok<NOPTS>
e.Verbose = true;
for sig = 1:5
   t{sig} = e.get_signal(sig); %#ok<SAGROW>
end
isequal(BELC_test, t)

%% testing a very large (21GB) file containing 7+ days of recordings over 32 channels
e = EDFast('/Users/giuseppe/data/edf/ALL_AJ&C57_group2_baseline7days_228h_20082015.edf') %#ok<NOPTS>
e.Verbose = true;
e.RecordsPerBlock = 10000;
tic
x=e.get_signal(3);
toc

