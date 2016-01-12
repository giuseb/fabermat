function varargout = sleeper(varargin)
% SLEEPER - sleep scoring system
%      SLEEPER(EEG) opens the sleeper GUI to display and score the signal
%      in EEG.

% Last Modified by GUIDE v2.5 12-Jan-2016 15:08:47

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
p.addParameter('States', {'REM', 'nREM', 'Wake'}, @iscell)
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
h.states        = r.States;

h.eeg_peak = max(h.eeg)*1.05; % the eeg charts' initial ylim
h.emg_peak = max(h.emg)*1.05; % the emg charts' initial ylim

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

% axes(h.spectra)
% h.sg = h.pow.spectrogram(1:h.epochs_in_seg);
% h.spectra.XTick = '';

set_current_segment(h, 1)

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
set(h.currSeg, 'String', seg)
draw_spectra(h)
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
function draw_spectra(h)
% t = h.pow.spectra(seg_range(h, seg));
% h.sg.CData = t;
axes(h.spectra)
sg = h.pow.spectrogram(seg_range(h, uivalue(h.currSeg)));
sg.HitTest = 'off';
set(h.spectra, ...
   'XLim', [0.5 h.epochs_in_seg+0.5], ...
   'XTick', [], ...
   'YLim', [h.hz_min h.hz_max]+0.5, ...
   'TickLen', [.007 .007])
box on

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
% signal range
first = (seg-1) * h.segment_size + (epo-1) * h.epoch_size + 1;
last  = first + h.epoch_size - 1;
axes(h.eegPlot)
plot(h.eeg(first:last))
h.eegPlot.YLim = [-h.eeg_peak h.eeg_peak];
h.eegPlot.XTickLabel = '';
if ~isempty(h.emg)
   axes(h.emgPlot)
   plot(h.emg(first:last))
   h.emgPlot.YLim = [-h.emg_peak h.emg_peak];
   l = str2double(h.emgPlot.XTickLabel);
   h.emgPlot.XTickLabel = l/h.sampling_rate;
end
set([h.eegPlot, h.emgPlot], 'ticklength', [.007 .007])

function draw_hypno(h, seg, epo)
axes(h.hypno)
ns = length(h.states);
l = fill([epo-1 epo epo epo-1], [0 0 ns+1 ns+1], 'm');
set(l, 'linestyle', 'none')
hold on
y = h.score(seg_range(h, seg));
x = 0:length(y)-1;
stairs(x, y);
set(h.hypno, ...
   'ticklen', [.007 .007], ...
   'tickdir', 'out', ...
   'ylim', [.5 .5+ns], ...
   'ytick', 1:ns, ...
   'xlim', [0 h.epochs_in_seg], ...
   'yticklabel', h.states, ...
   'layer', 'top', ...
   'ButtonDownFcn', @hypno_ButtonDownFcn);
hold off

function draw_power(h, seg, epo)
axes(h.power)
e = ep1(h, seg) + epo -1;
h.pow.power_density_curve(e);
set(h.power, ...
   'ylim', [h.pow.MinPwr h.pow.MaxPwr], ...
   'ticklen', [.05 .05])

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
set_current_segment(h, v)

function currSeg_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.num_segments, t=h.num_segments; end
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
p = h.emg_peak * demg;
h.emgPlot.YLim = [-p p];
h.emg_peak = p;
guidata(h.window, h);

% --- Executes on mouse press over axes background.
% I do not know why the handles are not passed here!
function hypno_ButtonDownFcn(hObject, eventdata)
h = guidata(hObject);
cp = eventdata.IntersectionPoint(1);
set(h.currEpoch, 'string', ceil(cp(1)));
draw_epoch(h)

% --- Executes on mouse press over axes background.
function spectra_ButtonDownFcn(hObject, eventdata, h) %#ok<DEFNU>
cp = eventdata.IntersectionPoint(1)-0.5;
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
% ensure that file name is only made of letters, numbers, underscores
m = regexp(hObject.String, '\W', 'once');
if isempty(m)
   h.btnSave.Enable = 'on';
else
   hObject.String = 'Invalid file name!';
   h.btnSave.Enable = 'off';
end

% --- Executes on mouse press over axes background.
function eegPlot_ButtonDownFcn(hObject, eventdata, h) %#ok<DEFNU>
cp = eventdata.IntersectionPoint(2);
set(h.txtEventThr, 'String', cp)

function txtEventThr_Callback(hObject, eventdata, handles) %#ok<DEFNU>


% --- Executes on button press in btnNext.
function btnNext_Callback(~, ~, h) %#ok<DEFNU>
m = find(h.eeg < uivalue(h.txtEventThr));
mm = uivalue(h.currSeg) * uivalue(h.currEpoch) * h.epoch_size;
m = min(m(m>mm));
e = floor(m/h.epoch_size);
h.currSeg.String = floor(e/uivalue(h.txtEpInSeg))+1;
h.currEpoch.String = rem(e, uivalue(h.txtEpInSeg))+1;
draw_spectra(h)
draw_epoch(h)


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnFindThr.
function btnFindThr_Callback(hObject, ~, h) %#ok<DEFNU>
over_thr = find(abs(h.eeg) > abs(uivalue(h.txtEventThr)));
h.watch_epochs = unique(floor(over_thr / h.epoch_size));

set(h.sldEvents, ...
   'Min', 1, ...
   'Max', length(h.watch_epochs), ...
   'SliderStep', [1/(length(h.watch_epochs)-1), 10/(length(h.watch_epochs)-1)], ...
   'Value', 1)
guidata(hObject, h)
sldEvents_Callback(h.sldEvents, 0, h)

% --- Executes on slider movement.
function sldEvents_Callback(hObject, ~, h) %#ok<DEFNU>
v = round(hObject.Value);
hObject.Value = v;

epInSeg = uivalue(h.txtEpInSeg);
h.currSeg.String = floor(h.watch_epochs(v)/epInSeg)+1;
h.currEpoch.String = rem(h.watch_epochs(v), epInSeg)+1;
draw_spectra(h)
draw_epoch(h)


% --- Executes during object creation, after setting all properties.
function sldEvents_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
