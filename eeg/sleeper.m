function varargout = sleeper(varargin)
% SLEEPER - sleep scoring system
%      Sleeper is a GUI tool aimed at facilitating vigilance state scoring
%      based on one EEG and (optionally) one EMG signal.
%
%      SLEEPER(EEG) opens the sleeper GUI to display and score the signal
%      in EEG

% Last Modified by GUIDE v2.5 17-Jan-2016 10:51:04

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
% evts = struct( ...
%    'start_seg', 0, ...
%    'start_epoch', 0, ...
%    'start_ms', 0, ...
%    'start_patch', 0, ...
%    'finish_seg', 0, ...
%    'finish_epoch', 0, ...
%    'finish_ms', 0, ...
%    'finish_patch', 0, ...
%    'tag', '');

p = inputParser;
p.addRequired('EEG', @isnumeric)
p.addOptional('EMG',       [], @isnumeric)
p.addParameter('SRate',   500, @isnumeric)
p.addParameter('Epoch',    10, @isnumeric)
p.addParameter('EpInSeg', 180, @isnumeric)
p.addParameter('Hypno',    [], @isnumeric)
p.addParameter('Events', struct, @isstruct)
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
h.events = r.Events;

h.sampling_rate = r.SRate;   % in Hz
h.scoring_epoch = r.Epoch;   % in seconds
h.kernel_len    = r.KLength; % in seconds
h.epochs_in_seg = r.EpInSeg; % number of epochs in a segment
h.hz_min        = r.MinHz;   % only plot spectra above this
h.hz_max        = r.MaxHz;   % only plot spectra below this
h.states        = r.States;

h.eeg_peak = max(h.eeg)*1.05; % the eeg charts' initial ylim
h.emg_peak = max(h.emg)*1.05; % the emg charts' initial ylim

%------------------------------------------------------------------- flags
h.setting_EEG_thr = false;
h.setting_event = false;
h.default_event_tag = 'Tag';
h.ce = 0; % current event

%------------ compute here parameters that cannot be changed while scoring

% size of epoch in nof samples
h.epoch_size = h.sampling_rate * h.scoring_epoch;
% total signal samples after trimming excess
h.signal_size = length(h.eeg)-rem(length(h.eeg), h.epoch_size);
% signal duration in seconds, after rounding to whole scoring epochs
h.signal_len = h.signal_size/h.sampling_rate;
% number of epochs in the signal
h.tot_epochs = h.signal_len / h.scoring_epoch;

%----------- compute here parameters that can be modified during execution
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
set(h.lblInfo, 'string', ...
   sprintf('%d Hz, %d-s epoch', h.sampling_rate, h.scoring_epoch))
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

%=========================================================================
%============================================================== Keypresses
%=========================================================================

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
   case '6'
      set_state(h, 6)
   case '7'
      set_state(h, 7)
   case '8'
      set_state(h, 8)
   case '9'
      set_state(h, 9)
   case 'n'
      set_state(h, nan)
end

%=========================================================================
%=========================================================== Button clicks
%=========================================================================

%-------------------------------------------------------> Save output file
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

%---------------------------------------------- Setting an event threshold
function btnSetEEGThr_Callback(hObject, ~, h) %#ok<DEFNU>
set(h.eegPlot, 'color', 'y')
h.setting_EEG_thr = true;
guidata(hObject, h)

%----------------------------------------------------- Abort marking event
function btnCancelEvent_Callback(hObject, ~, h) %#ok<DEFNU>
hObject.Visible = 'off';
del_event_patches(h)

%-------------------------------------------------- Modifying signal YLims
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


%=========================================================================
%==================================================== Capture mouse clicks
%=========================================================================

function hypno_ButtonDownFcn(hObject, eventdata)
% I do not know why the handles are not passed here!
h = guidata(hObject);
set(h.currEpoch, 'string', ceil(x_btn_pos(eventdata)));
draw_epoch(h)

function spectra_ButtonDownFcn(~, eventdata, h) %#ok<DEFNU>
sset(h.currEpoch, 'string', ceil(x_btn_pos(eventdata)-.5));
draw_epoch(h)

function eegPlot_ButtonDownFcn(~, eventdata, h) %#ok<DEFNU>
if h.setting_EEG_thr
   setting_EEG_thr(h, eventdata)
elseif h.setting_event
   finish_event(h, x_btn_pos(eventdata))
else % starting event
   start_event(h, x_btn_pos(eventdata))
end

function modify_event(pa, ~, ev, h)
set([pa h.events(ev).finish_patch], 'facecolor', [1 0.5 0])
s = inputdlg('Change event tag (accept empty to delete event)', 'Re-tag or delete event', 1);
if ~isempty(s) % OK was pressed so we need to take action
   if isempty(s{1})
      delete([h.events(ev).start_patch h.events(ev).finish_patch])
      h.events(ev) = [];
      h.ce = h.ce-1;
   else
      h.events(ev).tag = s{1};
   end
else % restore original marker color
   set([pa h.events(ev).finish_patch], 'facecolor', 'c')
end
guidata(h.window, h)

%=========================================================================
%====================================================== edit-box callbacks
%=========================================================================

%----------------------------------------------------> Set current segment
function currSeg_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.num_segments, t=h.num_segments; end
set_current_segment(h, t)

%------------------------------------------------------> Set current epoch
function currEpoch_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.epochs_in_seg, t=h.epochs_in_seg; end
set(hObject, 'String', t)
draw_epoch(h)

%-------------------------------------------------> Set epochs-per-segment
function txtEpInSeg_Callback(hObject, ~, h) %#ok<DEFNU>
h.epochs_in_seg = uivalue(hObject);
h = update_parameters(h);
guidata(hObject, h)
set_current_segment(h, 1)

%----------------------------------------------------> Set output filename
function txtHypnoFName_Callback(hObject, ~, h) %#ok<DEFNU>
% ensure that file name is only made of letters, numbers, underscores
m = regexp(hObject.String, '\W', 'once');
if isempty(m)
   h.btnSave.Enable = 'on';
else
   hObject.String = 'Invalid file name!';
   h.btnSave.Enable = 'off';
end

%=========================================================================
%======================================================== slider callbacks
%=========================================================================

%----------------------------------------------------> Set current segment
function segment_Callback(hObject, ~, h) %#ok<DEFNU>
v = round(get(hObject, 'Value'));
set(hObject, 'Value', v)
set_current_segment(h, v)

%-------------------------------------- Browsing events through the slider
function sldEvents_Callback(hObject, ~, h)
v = round(hObject.Value);
hObject.Value = v;
h.lblCurrEvent.String = sprintf('%d of %d events', v, hObject.Max);
epInSeg = uivalue(h.txtEpInSeg);
h.currSeg.String = floor(h.watch_epochs(v)/epInSeg)+1;
h.currEpoch.String = rem(h.watch_epochs(v), epInSeg)+1;
draw_spectra(h)
draw_epoch(h)

%=========================================================================
%================================================================ UPDATING
%=========================================================================

%----------------------------------------------------------> Update params
function h = update_parameters(h)
% spectro/hypnogram chart duration in seconds
h.segment_len   = h.scoring_epoch * h.epochs_in_seg;
% number of segments in the signal
h.num_segments = ceil(h.signal_len / h.segment_len);
% the width (in samples) of the spectrogram/hypnogram charts
h.segment_size = h.sampling_rate * h.segment_len;

%------------------------------------------------------------> Set segment
function set_current_segment(h, seg)
set(h.currSeg, 'String', seg)
draw_spectra(h)
set(h.currEpoch, 'string', 1)
draw_epoch(h)

%-------------------------------------------------------> Go to next epoch
function next_epoch(h)
e = uivalue(h.currEpoch) + 1;
s = uivalue(h.currSeg);
if e > h.epochs_in_seg && s < h.num_segments
   h.currEpoch.String = 1;
   h.currSeg.String = s+1;
   draw_spectra(h)
else
   h.currEpoch.String = min(e, h.epochs_in_seg);
end
draw_epoch(h)

%---------------------------------------------------> Go to previous epoch
function prev_epoch(h)
e = uivalue(h.currEpoch) - 1;
s = uivalue(h.currSeg);
if e < 1 && s > 1
   h.currEpoch.String = h.epochs_in_seg;
   h.currSeg.String = s-1;
   draw_spectra(h)
else
   h.currEpoch.String = max(uivalue(h.currEpoch)-1, 1);
end
draw_epoch(h)

%--------------------------------------------------------> Set epoch state
function set_state(h, state)
if state <= length(h.states)
   e = h.epochs_in_seg * (uivalue(h.currSeg) - 1) + uivalue(h.currEpoch);
   h.score(e) = state;
   guidata(h.window, h)
   next_epoch(h)
end

%=========================================================================
%========================================================== DRAWING THINGS
%=========================================================================

%---------------------------------------------------------- Redraw spectra
function draw_spectra(h)
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

%-------------------------------------------------------- Draw EEG and EMG
function draw_eeg(h, seg, epo)
axes(h.eegPlot)
plot(eeg_for(h, seg, epo))
h.eegPlot.YLim = [-h.eeg_peak h.eeg_peak];
h.eegPlot.XTickLabel = '';

% if this epoch contains event markers, draw them
if h.ce
   for ev = find(and([h.events.finish_seg]==seg, [h.events.finish_epoch]==epo))
      h.events(ev).finish_patch = draw_event_finish(h, h.events(ev).finish_ms);
   end
   for ev = find(and([h.events.start_seg]==seg, [h.events.start_epoch]==epo))
      p = draw_event_start(h, h.events(ev).start_ms, ev);
      h.events(ev).start_patch = p;
   end
end

if isempty(h.emg), return; end

axes(h.emgPlot)
plot(emg_for(h, seg, epo))
h.emgPlot.YLim = [-h.emg_peak h.emg_peak];
l = str2double(h.emgPlot.XTickLabel);
h.emgPlot.XTickLabel = l/h.sampling_rate;

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

function find_events(h)
over_thr = find(abs(h.eeg) > abs(h.event_thr));
h.watch_epochs = unique(floor(over_thr / h.epoch_size));
ne = length(h.watch_epochs);
guidata(h.window, h)
if ne==0
   h.sldEvents.Visible = 'off';
else
   set(h.sldEvents, ...
      'Visible', 'on', ...
      'Min', 1, ...
      'Max', ne, ...
      'SliderStep', [1/(ne-1), 10/(ne-1)], ...
      'Value', 1)
   h.lblEventThr.String = sprintf('EEG Thr: %f', h.event_thr);
   h.lblCurrEvent.Visible = 'on';
   h.lblCurrEvent.String = sprintf('1 of %d events', ne);
   sldEvents_Callback(h.sldEvents, 0, h)
end

function setting_EEG_thr(h, eventdata)
h.setting_EEG_thr = false;
cp = eventdata.IntersectionPoint(2);
h.event_thr = cp;
h.eegPlot.Color = 'w';
guidata(h.window, h)
x = inputdlg('Do you want to find events based on this threshold?', 'Finding events', 1, {num2str(cp)});
if ~isempty(x), find_events(h); end

function start_event(h, x)
h.ce = h.ce+1;
h.events(h.ce).start_seg = uivalue(h.currSeg);
h.events(h.ce).start_epoch = uivalue(h.currEpoch);
h.events(h.ce).start_ms = x;
h.events(h.ce).start_patch = draw_event_start(h, x, h.ce);
h.setting_event = true;
h.btnCancelEvent.Visible = 'on';
guidata(h.window, h)

function finish_event(h, x)
h.btnCancelEvent.Visible = 'off';
h.events(h.ce).finish_seg = uivalue(h.currSeg);
h.events(h.ce).finish_epoch = uivalue(h.currEpoch);
h.events(h.ce).finish_ms = x;
h.events(h.ce).finish_patch = draw_event_finish(h, x);
s = inputdlg('Assign tag to event or cancel', 'Tagging events', 1, {h.default_event_tag});
if isempty(s)
   delete([h.events(h.ce).start_patch h.events(h.ce).finish_patch]);
   h.ce = h.ce-1;
else
   h.events(end).tag = s{1};
   h.default_event_tag = s{1};
end
h.setting_event = false;
guidata(h.window, h)

function rv = draw_event_start(h, x, ev)
axes(h.eegPlot)
yl = h.eegPlot.YLim;
rv = patch([x x x+h.epoch_size/40 x+1 x+1], ...
           [yl(1) yl(2) yl(2) yl(2)/2 yl(1)], ...
           'c', 'linestyle', 'none', ...
           'ButtonDownFcn',{@modify_event, ev, h}, ...
           'PickableParts','all');

function rv = draw_event_finish(h, x)
axes(h.eegPlot)
yl = h.eegPlot.YLim;
rv = patch([x x x-h.epoch_size/40 x+1 x+1], [yl(1) yl(2)/2 yl(2) yl(2) yl(1)], 'c', 'linestyle', 'none');

%=========================================================================
% subfunctions/utilities
%=========================================================================
function del_event_patches(h, ev)
if nargin<2, ev = h.ce; end
delete(h.events(ev).start_patch)
if nargin>1
   delete(h.events(ev).finish_patch)
end
h.events(ev) = [];
h.ce = h.ce-1;
h.setting_event = false;
guidata(h.window, h)

function rv = eeg_for(h, seg, epo)
rv = h.eeg(signal_range_for(h, seg, epo));

function rv = emg_for(h, seg, epo)
rv = h.emg(signal_range_for(h, seg, epo));

function rv = signal_range_for(h, seg, epo)
first = (seg-1) * h.segment_size + (epo-1) * h.epoch_size + 1;
last  = first + h.epoch_size - 1;
rv = first:last;

function rv = x_btn_pos(eventdata)
rv = eventdata.IntersectionPoint(1);

function rv = global_eeg_position(h, x)
s1 = (uivalue(h.currSeg)-1) * h.epochs_in_seg;
s2 = uivalue(h.currEpoch)-1;
rv = (s1+s2)* h.epoch_size + x;
