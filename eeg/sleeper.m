function varargout = sleeper(varargin)
% SLEEPER - sleep scoring system
%      Sleeper is a GUI tool aimed at facilitating vigilance state scoring
%      based on one EEG and (optionally) one EMG signal.
%
%      SLEEPER(EEG) opens the sleeper GUI to display and score the signal
%      in EEG

% Last Modified by GUIDE v2.5 20-Jan-2016 15:20:56

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
p.addParameter('Markers', mrkstr, @isstruct)
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
h.markers = r.Markers;
h.cm = length(h.markers); % current marker

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
h.lblSegNum.String = sprintf('of %d', h.num_segments);
%---------------------------------------------- Setting up the spectrogram
h.pow = EEpower(h.eeg);
h.pow.setHz(h.sampling_rate);
h.pow.setEpoch(h.scoring_epoch);
h.pow.setKsize(h.kernel_len);
h.pow.setHzMin(h.hz_min);
h.pow.setHzMax(h.hz_max);

h.spectrarrow = 0;

jump_to(h, 1)

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
markers = h.markers; %#ok<NASGU>
save(t, 'hypnogram', 'markers')
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
function btnCancelMarker_Callback(hObject, ~, h) %#ok<DEFNU>
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

%------------------------------------------------> Deleting current marker
function btnDelMarker_Callback(~, ~, h) %#ok<DEFNU>
x = questdlg('Delete this marker?', 'EEG Markers', 'No', 'Yes', 'Yes');
switch x
   case 'No'
   case 'Yes'
      mrk = h.sldMarkers.Value;
      h.markers(mrk) = [];
      h.cm = h.cm-1;
      guidata(h.window, h)
      set_marker_info(h, min(mrk, h.cm))
end

%----------------------------------------------> Manually setting EEG YLim
function btnEEGuV_Callback(~, ~, h) %#ok<DEFNU>
curr_YLim = num2str(h.eegPlot.YLim(2));
x = inputdlg('Set Y limit in microvolts', 'EEG plot', 1, {curr_YLim});
if ~isempty(x)
   l = str2double(x{1});
   h.eegPlot.YLim = [-l l];   
end

%----------------------------------------------> Manually setting EMG YLim
function btnEMGuV_Callback(~, ~, h) %#ok<DEFNU>
curr_YLim = num2str(h.emgPlot.YLim(2));
x = inputdlg('Set Y limit in microvolts', 'EMG plot', 1, {curr_YLim});
if ~isempty(x)
   l = str2double(x{1});
   h.emgPlot.YLim = [-l l];   
end


%=========================================================================
%==================================================== Capture mouse clicks
%=========================================================================

function hypno_ButtonDownFcn(hObject, eventdata)
% I do not know why the handles are not passed here!
h = guidata(hObject);
set(h.currEpoch, 'string', ceil(x_btn_pos(eventdata)));
draw_epoch(h)

function spectra_ButtonDownFcn(~, eventdata, h) %#ok<DEFNU>
set(h.currEpoch, 'string', ceil(x_btn_pos(eventdata)-.5));
draw_epoch(h)

function eegPlot_ButtonDownFcn(~, eventdata, h) %#ok<DEFNU>
if h.setting_EEG_thr
   setting_EEG_thr(h, eventdata)
elseif h.setting_event
   finish_marker(h, x_btn_pos(eventdata))
else % starting event
   start_marker(h, x_btn_pos(eventdata))
end


%=========================================================================
%====================================================== edit-box callbacks
%=========================================================================

%----------------------------------------------------> Set current segment
function currSeg_Callback(hObject, ~, h) %#ok<DEFNU>
t = uivalue(hObject);
if t<1, t=1; end
if t>h.num_segments, t=h.num_segments; end
jump_to(h, t)

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
jump_to(h, 1)

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

%---------------------------------------------------------> Set marker tag
function txtMarkerTag_Callback(hObject, ~, h) %#ok<DEFNU>
mrk = h.sldMarkers.Value;
h.markers(mrk).tag = hObject.String;
guidata(hObject, h)

%=========================================================================
%======================================================== slider callbacks
%=========================================================================

%----------------------------------------------------> Set current segment
function segment_Callback(hObject, ~, h) %#ok<DEFNU>
jump_to(h, uisnapslider(hObject))

%-------------------------------------- Browsing events through the slider
function sldEvents_Callback(hObject, ~, h)
v = uisnapslider(hObject);
set_event_thr_label(h, v)
h.lblCurrEvent.String = sprintf('%d of %d events', v, hObject.Max);
epInSeg = uivalue(h.txtEpInSeg);
jump_to(h, floor(h.watch_epochs(v)/epInSeg)+1, rem(h.watch_epochs(v), epInSeg)+1)

%-------------------------------------- Browsing markers through the slider
function sldMarkers_Callback(hObject, ~, h) %#ok<DEFNU>
uisnapslider(hObject);
set_marker_info(h)

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

%--------------------------------------------------> Set segment and epoch
function jump_to(h, seg, epo)
if nargin<3, epo=1; end
h.currSeg.String = seg;
h.currEpoch.String = epo;
draw_spectra(h)
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

%--------------------------------------------------------> Set marker info
function set_marker_info(h, mno)

if h.cm == 0
   h.txtMarkerTag.String = '';
   h.sldMarkers.Enable = 'off';
   h.lblMarkers.String = 'no markers';
   draw_eeg(h, uivalue(h.currSeg), uivalue(h.currEpoch))
else
   if h.cm==1 % disable the slider
      mno = 1;
      h.sldMarkers.Value = 1;
      h.sldMarkers.Enable = 'off';
   else
      if nargin < 2, mno = h.sldMarkers.Value; end
      h.sldMarkers.Enable     = 'on';
      h.sldMarkers.Max        = h.cm;
      h.sldMarkers.Value      = mno;
      h.sldMarkers.SliderStep = [1/(h.cm-1), 10/(h.cm-1)];
   end
   mrk = h.markers(mno);
   jump_to(h, mrk.start_seg, mrk.start_epoch)
   h.txtMarkerTag.String = mrk.tag;
   h.lblMarkers.String = sprintf('%d of %d', mno, h.cm);
   highlight_marker(h, mno)
end

%=========================================================================
%========================================================== DRAWING THINGS
%=========================================================================

%-----------------------------------------------------------> Draw spectra
function draw_spectra(h)
axes(h.spectra)
sg = h.pow.spectrogram(seg_range(h, uivalue(h.currSeg)));
sg.HitTest = 'off';
h.spectra.XLim = [0.5 h.epochs_in_seg+0.5];
h.spectra.YLim = [h.hz_min h.hz_max]+0.5;
h.spectra.XTick = 0.5:10: h.epochs_in_seg+0.5;
h.spectra.XTickLabel = 0:10:h.epochs_in_seg;
h.spectra.TickLength = [.007 .007];
box on
% hold on
% epo = uivalue(h.currEpoch);
% disp(h.spectra.Layer)
% h.spectrarrow = fill([epo-.5 epo+.5 epo+.5 epo-.5], [-5 -5 10 10], [1 .7 1]);
% guidata(h.window, h)
% hold off

%------------------------------------------------------> Draw epoch charts
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
plot(eeg_for(h, seg, epo), 'k')
h.eegPlot.YLim = [-h.eeg_peak h.eeg_peak];
h.eegPlot.XTickLabel = '';

% if this epoch contains event markers, draw them
if h.cm
   for ev = find(and([h.markers.finish_seg]==seg, [h.markers.finish_epoch]==epo))
      h.markers(ev).finish_patch = draw_marker_finish(h, h.markers(ev).finish_ms);
   end
   for ev = find(and([h.markers.start_seg]==seg, [h.markers.start_epoch]==epo))
      p = draw_marker_start(h, h.markers(ev).start_ms, ev);
      h.markers(ev).start_patch = p;
   end
   guidata(h.window, h)
end

if isempty(h.emg), return; end

axes(h.emgPlot)
plot(emg_for(h, seg, epo))
h.emgPlot.YLim = [-h.emg_peak h.emg_peak];
l = str2double(h.emgPlot.XTickLabel);
h.emgPlot.XTickLabel = l/h.sampling_rate;

set([h.eegPlot, h.emgPlot], 'ticklength', [.007 .007])

%-----------------------------------------------------> Draw the hypnogram
function draw_hypno(h, seg, epo)
axes(h.hypno)
ns = length(h.states);
l = fill([epo-1 epo epo epo-1], [0 0 ns+1 ns+1], [1 .7 1]);
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
   'xticklabel', '', ...
   'yticklabel', h.states, ...
   'layer', 'top', ...
   'ButtonDownFcn', @hypno_ButtonDownFcn);
hold off

%set(h.spectrarrow, 'XData', [epo-.5 epo+.5 epo+.5 epo-.5])
% axes(h.spectra)
% hold on
% epo = uivalue(h.currEpoch);
% fill([epo-1 epo epo epo-1], [-5 -5 10 10], [1 .7 1]);
% hold off



%---------------------------------------------------> Draw the power curve
function draw_power(h, seg, epo)
axes(h.power)
e = ep1(h, seg) + epo -1;
h.pow.power_density_curve(e);
set(h.power, ...
   'ylim', [h.pow.MinPwr h.pow.MaxPwr], ...
   'ticklen', [.05 .05])

%--------------------------------------------------> Draw the marker start
function rv = draw_marker_start(h, x, mkr)
axes(h.eegPlot)
yl = h.eegPlot.YLim;
rv = patch([x x x+h.epoch_size/40 x+1 x+1], ...
           [yl(1) yl(2) yl(2) yl(2)/2 yl(1)], ...
           'c', 'linestyle', 'none', ...
           'ButtonDownFcn',{@modify_event, mkr, h}, ...
           'PickableParts','all');

%----------------------------------------------------> Draw the marker end
function rv = draw_marker_finish(h, x)
axes(h.eegPlot)
yl = h.eegPlot.YLim;
rv = patch([x x x-h.epoch_size/40 x+1 x+1], [yl(1) yl(2)/2 yl(2) yl(2) yl(1)], 'c', 'linestyle', 'none');

%=========================================================================
%========================================== Actions executed via callbacks
%=========================================================================

function setting_EEG_thr(h, eventdata)
h.setting_EEG_thr = false;
cp = eventdata.IntersectionPoint(2);
h.event_thr = cp;
h.eegPlot.Color = 'w';
guidata(h.window, h)
x = inputdlg('Do you want to find events based on this threshold?', 'Finding events', 1, {num2str(cp)});
if ~isempty(x), find_events(h); end

function find_events(h)
over_thr = find(abs(h.eeg) > abs(h.event_thr));
h.watch_epochs = unique(floor(over_thr / h.epoch_size));
ne = length(h.watch_epochs);
guidata(h.window, h)
if ne==0
   h.sldEvents.Enabled = 'off';
else
   set(h.sldEvents, ...
      'Enable', 'on', ...
      'Min', 1, ...
      'Max', ne, ...
      'SliderStep', [1/(ne-1), 10/(ne-1)], ...
      'Value', 1)
   set_event_thr_label(h, 1)
   sldEvents_Callback(h.sldEvents, 0, h)
end

function start_marker(h, x)
h.cm = h.cm+1;
h.markers(h.cm).start_seg = uivalue(h.currSeg);
h.markers(h.cm).start_epoch = uivalue(h.currEpoch);
h.markers(h.cm).start_ms = x;
h.markers(h.cm).start_patch = draw_marker_start(h, x, h.cm);
h.setting_event = true;
h.btnCancelMarker.Visible = 'on';
guidata(h.window, h)

function finish_marker(h, x)
% make sure finish occurs after start!
m = h.markers(h.cm);
if m.start_seg > uivalue(h.currSeg) || ...
      m.start_epoch > uivalue(h.currEpoch) || ...
      (m.start_ms > x && m.start_epoch==uivalue(h.currEpoch))
   beep
   return
end
h.btnCancelMarker.Visible = 'off';
h.markers(h.cm).finish_seg = uivalue(h.currSeg);
h.markers(h.cm).finish_epoch = uivalue(h.currEpoch);
h.markers(h.cm).finish_ms = x;
h.markers(h.cm).finish_patch = draw_marker_finish(h, x);
s = inputdlg('Assign tag to event or cancel', 'Tagging events', 1, {h.default_event_tag});
if isempty(s) % never mind... ignore this marker
   delete([h.markers(h.cm).start_patch h.markers(h.cm).finish_patch]);
   h.cm = h.cm-1;
else % we do have a new marker
   h.markers(h.cm).tag = s{1};
   h.default_event_tag = s{1};
   set_marker_info(h, h.cm)
end
h.setting_event = false;
guidata(h.window, h)

%=========================================================================
% subfunctions/utilities
%=========================================================================
function highlight_marker(h, mrk)
h = guidata(h.window); % not sure why this is necessary
m = h.markers(mrk);
p = m.start_patch;
if ishandle(m.finish_patch), p = [p m.finish_patch]; end
set(p, 'facecolor', [1 0.5 0])

function set_event_thr_label(h, curr)
s = sprintf('Event #%d of %d @ %f mV', curr, h.sldEvents.Max, h.event_thr);
h.lblEventThr.String = s;

function rv = seg_range(h, seg)
rv = ep1(h, seg):epN(h, seg);

function rv = ep1(h, seg)
rv = (seg-1) * h.epochs_in_seg + 1;

function rv = epN(h, seg)
rv = min(seg * h.epochs_in_seg, h.tot_epochs);

function del_event_patches(h, ev)
if nargin<2, ev = h.cm; end
delete(h.markers(ev).start_patch)
if nargin>1
   delete(h.markers(ev).finish_patch)
end
h.markers(ev) = [];
h.cm = h.cm-1;
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

function rv = mrkstr
rv = struct( ...
   'start_seg', {}, ...
   'start_epoch', {}, ...
   'start_ms', {}, ...
   'start_patch', {}, ...
   'finish_seg', {}, ...
   'finish_epoch', {}, ...
   'finish_ms', {}, ...
   'finish_patch', {}, ...
   'tag', '');
   
function modify_event(pa, ~, ev, h)
set_marker_info(h, ev)
% highlight_marker(h, ev)
% s = inputdlg('Change event tag (empty string to delete)', 'Re-tag or delete event', 1);
% if ~isempty(s) % OK was pressed so we need to take action
%    if isempty(s{1})
%       delete([h.markers(ev).start_patch h.markers(ev).finish_patch])
%       h.markers(ev) = [];
%       h.cm = h.cm-1;
%    else
%       h.markers(ev).tag = s{1};
%    end
% else % restore original marker color
%    set([pa h.markers(ev).finish_patch], 'facecolor', 'c')
% end
% guidata(h.window, h)

% 
%            'ButtonDownFcn',{@modify_event, ev, h}, ...
%            'PickableParts','all'
