function varargout = sleeper(varargin)
% SLEEPER - sleep scoring system
%      SLEEPER(EEG) opens the sleeper GUI to display and score the signal
%      in EEG.

% Last Modified by GUIDE v2.5 07-Jan-2016 09:26:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @sleeper_OpeningFcn, ...
   'gui_OutputFcn',  @sleeper_OutputFcn, ...
   'gui_LayoutFcn',  [] , ...
   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
   [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
   gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Outputs from this function are returned to the command line.
function varargout = sleeper_OutputFcn(~, ~, h)
varargout{1} = h.output;


function rv = the_hypnogram(h)
h = guidata(h);
rv = h.score;

% --- Executes just before sleeper is made visible.
function sleeper_OpeningFcn(hObject, ~, h, eeg, varargin)
%-------------------------------------------------------- Parse input args
p = inputParser;
p.addRequired('EEG', @isnumeric)
p.addOptional('EMG',       [], @isnumeric)
p.addParameter('SRate',   500, @isnumeric)
p.addParameter('Epoch',    10, @isnumeric)
p.addParameter('EpInSeg', 180, @isnumeric)
p.addParameter('Hypno',    [], @isnumeric)
p.addParameter('KLength',   1, @isnumeric)
p.addParameter('EEGPeak',   1, @isnumeric)
p.addParameter('EMGPeak', 0.5, @isnumeric)
p.addParameter('MinHz',     0, @isnumeric)
p.addParameter('MaxHz',    30, @isnumeric)
p.parse(eeg, varargin{:})
%------------------------------ transfer inputParser Results to the handle
r = p.Results;
h.eeg = r.EEG;
h.emg = r.EMG;

h.sampling_rate = r.SRate;   % in Hz
h.scoring_epoch = r.Epoch;   % in seconds
h.kernel_len    = r.KLength; % in seconds
h.epochs_in_seg = r.EpInSeg; % number of epochs in a segment
h.hz_min        = r.MinHz;   % only plot spectra above this
h.hz_max        = r.MaxHz;   % only plot spectra below this
h.eeg_peak      = r.EEGPeak; % the eeg charts' initial ylim
h.emg_peak      = r.EMGPeak; % the emg charts' initial ylim

%------------ compute here parameters that cannot be changed while scoring

% size of epoch in nof samples
h.epoch_size = h.sampling_rate * h.scoring_epoch;
% total signal samples after trimming excess
h.signal_size = length(h.eeg)-rem(length(h.eeg), h.epoch_size);
% signal duration in seconds, after rounding to whole scoring epochs
h.signal_len = h.signal_size/h.sampling_rate;
% number of epochs in the signal
h.tot_epochs = h.signal_len / h.scoring_epoch;

%---------------------- compute here parameters that can be modified later
h = update_parameters(h);

%-------------------------------------------------------- set up hypnogram
if isempty(r.Hypno)
   h.score = nan(h.tot_epochs, 1);
else
   h.score = r.Hypno;
end

%----------------------------------------------------- set up GUI controls
h.txtEpInSeg.String = h.epochs_in_seg;
h.currSeg.String = 1;
h.currEpoch.String = 1;
set(h.lblInfo, 'string', sprintf('%d Hz, %d-s epoch', h.sampling_rate, h.scoring_epoch))
% set up signal time slider; the 12-segment increment is based on the
% assumption that the segment will often last one hour
set(h.segment, ...
   'Min', 1, ...
   'Max', h.num_segments, ...
   'Value', 1, ...
   'SliderStep', [1/(h.num_segments-1), 12/(h.num_segments-1)]);

%---------------------------------------------- Setting up the spectrogram
h.pow = EEpower(h.eeg);
h.pow.setHz(h.sampling_rate);
h.pow.setEpoch(h.scoring_epoch);
h.pow.setKsize(h.kernel_len);
h.pow.setHzMin(h.hz_min);
h.pow.setHzMax(h.hz_max);

axes(h.spectra)
h.sg = h.pow.spectrogram(1:h.epochs_in_seg);
h.spectra.XTick = '';

%------------------------------------------------ Draw first eeg and power
draw_epoch(h)

% Choose default command line output for sleeper
h.output = hObject;
% Update handles structure
guidata(hObject, h);

%---------------------------------------------------------- Update params
function h = update_parameters(h)
% spectro/hypnogram chart duration in seconds
h.segment_len   = h.scoring_epoch * h.epochs_in_seg;
% number of segments in the signal
h.num_segments = ceil(h.signal_len / h.segment_len);
% the width (in samples) of the spectrogram/hypnogram charts
h.segment_size = h.sampling_rate * h.segment_len;

%---------------------------------------------------------- Custom methods
function set_current_segment(h, seg)
% set(h.window, 'pointer', 'watch')
% drawnow
draw_spectra(h, seg)
% set(h.window, 'pointer', 'arrow')
set(h.currEpoch, 'string', 1)
draw_epoch(h)

function next_epoch(h)
set(h.currEpoch, 'string', min(uivalue(h.currEpoch)+1, h.epochs_in_seg))
draw_epoch(h)

function prev_epoch(h)
set(h.currEpoch, 'string', max(uivalue(h.currEpoch)-1, 1))
draw_epoch(h)

function set_state(h, state)
e = h.epochs_in_seg * (uivalue(h.currSeg) - 1) + uivalue(h.currEpoch);
h.score(e) = state;
guidata(h.window, h)
next_epoch(h)

%----------------------------------------------------- Redraw spectra
function draw_spectra(h, seg)
% axes(h.spectra);
% t = h.pow.spectra(seg_range(h, seg));
% h.sg.CData = t;
axes(h.spectra)
h.pow.spectrogram(seg_range(h, seg));
h.spectra.XLim = [0.5 h.epochs_in_seg+0.5];
h.spectra.XTick = '';

%----------------------------------------------------- Redraw epoch charts
function draw_epoch(h)
seg = uivalue(h.currSeg);
epo = uivalue(h.currEpoch);

if h.tot_epochs >= ep1(h, seg) + epo
   draw_eeg(h, seg, epo)
   draw_hypno(h, seg, epo)
   draw_power(h, seg, epo)
end

function draw_eeg(h, seg, epo)
axes(h.eegPlot)
% signal range
first = (seg-1) * h.segment_size + (epo-1) * h.epoch_size + 1;
last  = first + h.epoch_size - 1;
plot(h.eeg(first:last))
h.eegPlot.YLim = [-h.eeg_peak h.eeg_peak];
h.eegPlot.XTickLabel = '';

function draw_hypno(h, seg, epo)
axes(h.hypno)
l = fill([epo-1 epo epo epo-1], [0 0 6 6], 'y');
set(l, 'linestyle', 'none')
hold on
y = h.score(seg_range(h, seg));
x = 0:length(y)-1;
s = stairs(x, y);
set(gca, ...
   'tickdir', 'out', ...
   'ylim', [0 6], ...
   'ydir', 'reverse', ...
   'ytick', 1:5, ...
   'xlim', [0 h.epochs_in_seg], ...
   'yticklabel', {'AW' 'QW' 'SS' 'RS' 'Th'}, ...
   'layer', 'top', ...
   'ButtonDownFcn', @hypno_ButtonDownFcn);
hold off

function draw_power(h, seg, epo)
axes(h.power)
e = ep1(h, seg) + epo -1;
h.pow.power_density_curve(e);

function rv = seg_range(h, seg)
rv = ep1(h, seg):epN(h, seg);

function rv = ep1(h, seg)
rv = (seg-1) * h.epochs_in_seg + 1;

function rv = epN(h, seg)
rv = min(seg * h.epochs_in_seg, h.tot_epochs);

% --- Executes on key press with focus on window and none of its controls.
function window_KeyPressFcn(~, key, h) %#ok<DEFNU>

switch key.Key
   case 'rightarrow'
      next_epoch(h)
   case 'leftarrow'
      prev_epoch(h)
   case '1'
      set_state(h, 1)
   case '2'
      set_state(h, 2)
   case '3'
      set_state(h, 3)
   case '4'
      set_state(h, 4)
   case '5'
      set_state(h, 5)
   case 'n'
      set_state(h, nan)
end


%=============================================================== CALLBACKS


function currEpoch_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.epochs_in_seg, t=h.epochs_in_seg; end
set(hObject, 'String', t)
draw_epoch(h)

% --- Executes on slider movement.
function segment_Callback(hObject, ~, h) %#ok<DEFNU>
% when user clicks on the segment slider, round to the closest segment, then
% update the currSeg textbox, the spectrogram and the hypnogram
v = round(get(hObject, 'Value'));
set(hObject, 'Value', v)
set(h.currSeg, 'String', v)
set_current_segment(h, v)

function currSeg_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.num_segments, t=h.num_segments; end
set(hObject, 'string', t)
set_current_segment(h, t)

% --- Executes on signal size button presses.
function moreEEGpeak_Callback(~, ~, h) %#ok<DEFNU>
set_ylim(h, .9, 1)
function lessEEGpeak_Callback(~, ~, h) %#ok<DEFNU>
set_ylim(h, 1.1, 1)
function moreEMGpeak_Callback(~, ~, h) %#ok<DEFNU>
set_ylim(h, 1, .9)
function lessEMGpeak_Callback(~, ~, h) %#ok<DEFNU>
set_ylim(h, 1, 1.1)

function set_ylim(h, deeg, demg)
p = h.eeg_peak * deeg;
h.eegPlot.YLim = [-p p];
h.eeg_peak = p;
guidata(h.window, h);

% --- Executes on mouse press over axes background.
% I do not know why the handles are not passed here!
function hypno_ButtonDownFcn(hObject, eventdata)
h = guidata(hObject);
cp = eventdata.IntersectionPoint(1);
set(h.currEpoch, 'string', ceil(cp(1)));
draw_epoch(h)

% --- Executes on button press in btnSave.
function btnSave_Callback(hObject, ~, h) %#ok<DEFNU>
t = h.txtHypnoFName.String;
h.txtHypnoFName.String = 'Saving...';
hypnogram = h.score; %#ok<NASGU>
save(t, 'hypnogram')
h.txtHypnoFName.String = 'Saved.';
hObject.BackgroundColor = 'green';
uiwait(h.window, 1);
hObject.BackgroundColor = 'white';
h.txtHypnoFName.String = t;


function txtEpInSeg_Callback(hObject, ~, h) %#ok<DEFNU>
h.epochs_in_seg = uivalue(hObject);
h = update_parameters(h);
guidata(hObject, h)
set_current_segment(h, 1)

function txtHypnoFName_Callback(hObject, ~, h) %#ok<DEFNU>
m = regexp(hObject.String, '\W', 'once');
if isempty(m)
   h.btnSave.Enable = 'on';
else
   hObject.String = 'Invalid file name!';
   h.btnSave.Enable = 'off';
end