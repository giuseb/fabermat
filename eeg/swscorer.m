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

% Last Modified by GUIDE v2.5 22-Dec-2015 19:59:30

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


% --- Executes just before swscorer is made visible.
function swscorer_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% h    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to swscorer (see VARARGIN)

if nargin > 3
   h.eeg = varargin{1};
end

if nargin > 4
   h.emg = varargin{2};
end

% will make these user-defined
h.sampling_rate = 500;
h.scoring_epoch = 10;
h.kernel_size = 1;

% EXTRACT THIS TO A CLASS
% the number of samples in a single epoch
spd = h.scoring_epoch * h.sampling_rate;
% the number of samples in a single kernel
spk = h.kernel_size * h.sampling_rate;

% the total number of available epochs in the data (note that any trailing
% samples will be ignored)
nepochs = floor(length(h.eeg)/spd);

% the frequencies; frequency resolution is the inverse of the kernel size;
% maximum frequency is always half of the sampling rate
f = 0:(1/h.kernel_size):h.sampling_rate/2;

% preallocate memory for the spectrogram
h.pxx = zeros(length(f), nepochs);

% generate the Hanning kernel
ha = hanning(spk);

% repeat for each epoch
for ep = 1:nepochs
   % find the indices along the data vector
   i1 = (ep-1)*spd+1;
   i2 = ep*spd;
   % compute the spectra
   h.pxx(:,ep) = pwelch(h.eeg(i1:i2), ha, 0, spk, h.sampling_rate);
end

redraw(h);

% Choose default command line output for swscorer
h.output = hObject;
% Update handles structure
guidata(hObject, h);

% UIWAIT makes swscorer wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = swscorer_OutputFcn(hObject, eventdata, h) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% h    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = h.output;


% --- Executes on mouse press over axes background.
function spectra_ButtonDownFcn(hObject, eventdata, h)
disp('hello world')



function srate_Callback(hObject, eventdata, h)

% Hints: get(hObject,'String') returns contents of srate as text
%        str2double(get(hObject,'String')) returns contents of srate as a double


% --- Executes during object creation, after setting all properties.
function srate_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function redraw(h)

axes(h.spectra)
d = 10*log10(h.pxx(1:30,:));
imagesc(d, [-60 -30] )
axis xy
colormap(jet)
