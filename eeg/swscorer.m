function varargout = swscorer(varargin)
% SWSCORER MATLAB code for swscorer.fig
%      SWSCORER, by itself, creates a new SWSCORER or raises the existing
%      singleton*.
%
%      H = SWSCORER returns the handle to a new SWSCORER or the handle to
%      the existing singleton*.
%
%      SWSCORER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SWSCORER.M with the given input arguments.
%
%      SWSCORER('Property','Value',...) creates a new SWSCORER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before swscorer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to swscorer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help swscorer

% Last Modified by GUIDE v2.5 04-Jan-2016 09:14:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @swscorer_OpeningFcn, ...
                   'gui_OutputFcn',  @swscorer_OutputFcn, ...
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
function varargout = swscorer_OutputFcn(~, ~, h) 
varargout{1} = h.output;


function rv = the_hypnogram(h)
h = guidata(h);
rv = h.score;

% --- Executes just before swscorer is made visible.
function swscorer_OpeningFcn(hObject, ~, h, eeg, varargin)
%-------------------------------------------------------- Parse input args
p = inputParser;
p.addRequired('EEG', @isnumeric)
p.addOptional('EMG', [], @isnumeric)
p.addParameter('Hz', 500)
p.addParameter('Epoch', 10)
p.addParameter('EpInSeg', 180)
p.addParameter('Hypno', [], @isnumeric)
p.parse(eeg, varargin{:})
h.p = p.Results; % the 'p' field contains all parameters
%-------------------------------------------------------- set up params
update_parameters(h)

h.eeg = r.EEG;


if nargin > 4
   h.emg = varargin{2};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% will make these user-defined
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.sampling_rate =  500; % in Hz
h.scoring_epoch =    4; % in seconds
h.kernel_len    =    1; % in seconds
h.hz_min        =    0; % only plot spectra above this
h.hz_max        =   30; % only plot spectra below this
h.segment_len   = 1800; % spectro/hypnogram chart duration in seconds
h.eeg_peak      =   1; % the eeg charts' initial ylim
h.emg_peak      = 0.5; % the emg charts' initial ylim

%%%%%%%%%%%%%%%%%%%%%
% computed parameters
%%%%%%%%%%%%%%%%%%%%%
% size of currEpoch in samples
h.epoch_size = h.sampling_rate * h.scoring_epoch;
% total signal samples after trimming excess
h.signal_size = length(h.eeg)-rem(length(h.eeg), h.epoch_size);
% signal duration in seconds, after rounding to whole scoring epochs
h.signal_len = h.signal_size/h.sampling_rate;
% number of segments in the signal
h.num_segments = ceil(h.signal_len / h.segment_len);
% number of epochs in the segment
h.epochs_per_segment = h.segment_len / h.scoring_epoch;
% number of epochs in the signal
h.tot_epochs = h.signal_len / h.scoring_epoch;
% the width (in samples) of the spectrogram/hypnogram charts
h.segment_size = h.sampling_rate * h.segment_len;
% set up signal time slider; the 12-segment increment is based on the
% assumption that the segment will usually last one segment
set(h.segment, ...
   'Min', 1, ...
   'Max', h.num_segments, ...
   'Value', 1, ...
   'SliderStep', [1/(h.num_segments-1), 12/(h.num_segments-1)]);


%------------------------------------------------ Setting up the hypnogram
if nargin > 5
   h.score = varargin{3};
else
   h.score = nan(h.tot_epochs, 1);
end

%---------------------------------------------- Setting up the spectrogram
h.pow = EEpower(h.eeg);
h.pow.setHz(h.sampling_rate);
h.pow.setEpoch(h.scoring_epoch);
h.pow.setKsize(h.kernel_len);
h.pow.setHzMin(h.hz_min);
h.pow.setHzMax(h.hz_max);

draw_spectra(h, 1)
draw_epoch(h)

% Choose default command line output for swscorer
h.output = hObject;
% Update handles structure
guidata(hObject, h);

function update_parameters(h)

%---------------------------------------------------------- Custom methods
function set_current_segment(h, seg)
% set(h.window, 'pointer', 'watch')
drawnow
draw_spectra(h, seg)
% set(h.window, 'pointer', 'arrow')
set(h.currEpoch, 'string', 1)
draw_epoch(h)

function next_epoch(h)
set(h.currEpoch, 'string', min(uivalue(h.currEpoch)+1, h.epochs_per_segment))
draw_epoch(h)

function prev_epoch(h)
set(h.currEpoch, 'string', max(uivalue(h.currEpoch)-1, 1))
draw_epoch(h)

function set_state(h, state)
e = h.epochs_per_segment * (uivalue(h.currSeg) - 1) + uivalue(h.currEpoch);
h.score(e) = state;
guidata(h.window, h)
next_epoch(h)

%----------------------------------------------------- Redraw spectra
function draw_spectra(h, s)
axes(h.spectra);
h.spectra.XTick = '';
first = (s-1) * h.epochs_per_segment+1;
last  = s * h.epochs_per_segment;
h.pow.spectrogram(first:last);


%----------------------------------------------------- Redraw epoch charts
function draw_epoch(h)
seg = uivalue(h.currSeg);
epo = uivalue(h.currEpoch);

draw_eeg(h, seg, epo)
draw_hypno(h, seg, epo)
draw_power(h, seg, epo)

function draw_eeg(h, seg, epo)
axes(h.eegPlot)
% signal range
first = (seg-1) * h.segment_size + (epo-1) * h.epoch_size + 1;
last  = first + h.epoch_size - 1;
plot(h.eeg(first:last))
h.eegPlot.YLim = [-h.eeg_peak h.eeg_peak];
h.eegPlot.XTickLabel = '';
% h.eegPlot.YLim = h.eeg_peak;


function draw_hypno(h, seg, epo)
axes(h.hypno)
x = 0:h.epochs_per_segment-1;
l = fill([epo-1 epo epo epo-1], [0 0 6 6], 'y');
set(l, 'linestyle', 'none')
hold on
y = h.score(h.epochs_per_segment * (seg - 1) +1:h.epochs_per_segment*seg);
s = stairs(x, y);
set(gca, ...
   'tickdir', 'out', ...
   'ylim', [0 6], ...
   'ydir', 'reverse', ...
   'ytick', 1:5, ...
   'xlim', [0 h.epochs_per_segment], ...
   'yticklabel', {'AW' 'QW' 'SS' 'RS' 'Th'}, ...
   'layer', 'top', ...
   'ButtonDownFcn', @hypno_ButtonDownFcn);
% set(s, 'ButtonDownFcn', @hypno_ButtonDownFcn);
hold off

function draw_power(h, seg, epo)
axes(h.power)
e = (seg-1)*h.epochs_per_segment + epo;
h.pow.power_density_curve(e);
h.power.YLim = [10e-8 10e-4];


% --- Executes on key press with focus on window and none of its controls.
function window_KeyPressFcn(~, key, h)

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
   case '0'
      set_state(h, nan)
end


%=============================================================== CALLBACKS


function currEpoch_Callback(hObject, ~, h)
t = uivalue(hObject);
if t<1, t=1; end
if t>h.epochs_per_segment, t=h.epochs_per_segment; end
set(hObject, 'String', t)
draw_epoch(h)


% --- Executes on mouse press over axes background.
function spectra_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to spectra (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('hello')


function srate_Callback(hObject, ~, h)
% Hints: get(hObject,'String') returns contents of srate as text
%        str2double(get(hObject,'String')) returns contents of srate as a double


% --- Executes on slider movement.
function segment_Callback(hObject, ~, h)
% when user clicks on the segment slider, round to the closest segment, then
% update the currSeg textbox, the spectrogram and the hypnogram
v = round(get(hObject, 'Value'));
set(hObject, 'Value', v)
set(h.currSeg, 'String', v)
set_current_segment(h, v)

function currSeg_Callback(hObject, ~, h)
t = uivalue(hObject);
if t<1, t=1; end
if t>h.num_segments, t=h.num_segments; end
set(hObject, 'string', t)
set_current_segment(h, t)


% --- Executes on button press in moreEEGpeak.
function moreEEGpeak_Callback(~, ~, h)
set_ylim(h, .9, 1)
function lessEEGpeak_Callback(~, ~, h)
set_ylim(h, 1.1, 1)
function moreEMGpeak_Callback(~, ~, h)
set_ylim(h, 1, .9)
function lessEMGpeak_Callback(~, ~, h)
set_ylim(h, 1, 1.1)

% hObject    handle to moreEEGpeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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

% hObject    handle to hypno (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
