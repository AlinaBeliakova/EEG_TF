function eeg_tf(varargin)
% EEG_TF - Time-Frequency Analysis, the Graphical User Interface
%
% EEG_TF() generates graphical user interface for performing
% time-frequency analysis of EEG or any 3D signals. No arguments are
% necessary in the function call.
%
% Optional arguments can be given in the form:
% EEG_TF(data, fs, time) where 
% - data:   3D or 2D signal with dimentions [channels, time, trials], the
%           last dimention can be omitted if data is not epoched
% - fs:     sampling frequency in Hz, e.g. 128 Hz
% - time:   start and end times in seconds, e.g. [-0.5, 1] sec, or full 
%           time vector in seconds
%
% The Matlab package is developped by Alina Beliakova (CRNS, France) in 2021. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Global values

% Handle to this main figure
global hf_MAIN;

% Check to see if GUI is already running and clear variables, otherwise 
% variables and handles can get mixed up.
if ~isempty(hf_MAIN)
    clearvars
end

% Handles to other controls in this main window
global ht_errorStatus
global ht_loadStatus
global ht_channelsStatus
global ht_samplesStatus
global ht_timerangeStatus
global ht_samplingrateStatus
global ht_weightsStatus
global hcm_electrode_space
global ht_eventsStatus
global hpm_individual
global hpm_compare
global he_chanOI
global he_freqOI
global he_timeOI
global hpm_method
global hcm_dB
global he_baseline
global he_timeLM
global he_freqLM

% Global variables to store all the values
global g_EEG_dataset
global g_params

% Initialize the global variables

% if the data is passed from the workspace, fill the dataset structure
if exist('varargin','var') && length(varargin) == 3
    data = varargin{1};
    fs = varargin{2};
    time = varargin{3};
    g_EEG_dataset.filenames = '-';
    g_EEG_dataset.pathname = '-';
    g_EEG_dataset.nb_files = 1;
    g_EEG_dataset.EEG = [];
    g_EEG_dataset.time = [time(1), time(end)];
    g_EEG_dataset.fs = fs;
    g_EEG_dataset.events = [];
    g_EEG_dataset.data = data;
    g_EEG_dataset.w = ones(size(data,1));
    clear data fs times
else
    g_EEG_dataset = [];
end
g_params.eventsOI = [];
g_params.individual = 1;
g_params.compare = 2;
g_params.chanOI = 1;
g_params.freqOI = 1:45;
g_params.timeOI = [0, 500];
g_params.method = 1;
g_params.dB = 1;
g_params.baseline = [-400, -200];
% g_params.accelerate = 1;
g_params.time_landmarks = 0;
g_params.freq_landmarks = [9,13,19,30,44];
% advanced setting for the tf transform
g_params.advanced_settings.stft.default = 1;
g_params.advanced_settings.stft.windowing = [];
g_params.advanced_settings.stft.window_length = [];
g_params.advanced_settings.stft.step = [];
g_params.advanced_settings.stft.previous_settings = [];

g_params.advanced_settings.wavelets.default = 1;
g_params.advanced_settings.wavelets.correct_nl = 1;
g_params.advanced_settings.wavelets.nb_cycles = [];
g_params.advanced_settings.wavelets.log = [];
g_params.advanced_settings.wavelets.previous_settings = [];

g_figures.open_figures = findobj(allchild(0), 'flat', 'Type', 'figure');
% These are regarded as constants and are used to store
% the strings for the popup menus the current value is
% seen in the variables above
% D - refers to strings that are displayed
% V - refers to string values that are used in FPICA
global c_Individual_strD
global c_Individual_strV
global c_Compare_strD
global c_Compare_strV
global c_Method_strD
global c_Method_strV
global c_dB_strD
global c_dB_strV

% All the values for these are set here - even for
% variables that are not used in this file
c_Individual_strD = 'Individual|Group';
c_Individual_strV = {'ind'; 'group'};
c_Compare_strD = 'Compare|Merge';
c_Compare_strV = {'compare'; 'merge'};
c_Method_strD = 'STFT|Wavelets';
c_Method_strV = {'stft'; 'wavelets'};
c_dB_strD = 'dB|Raw';
c_dB_strV = {'db'; 'raw'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration options
win_width = 600;
win_height = 780;
FIGURENAME = 'EEG_TF';
FIGURETAG = 'f_EEG_TF';
SCREENSIZE = get(0,'ScreenSize');
FIGURESIZE = [round(0.5*SCREENSIZE(3)) (SCREENSIZE(4)-round(0.1*SCREENSIZE(4))-win_height) win_width win_height];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the figure
a = figure('Color',[0.95 0.95 0.95], ...
	   'PaperType','a4letter', ...
	   'Name', FIGURENAME, ...
	   'NumberTitle', 'off', ...
	   'Tag', FIGURETAG, ...
	   'Position', FIGURESIZE, ...
	   'MenuBar', 'none');
% Resizing has to be denied after the window has been created -
% otherwise the window shows only as a tiny window in Windows XP.
set (a, 'Resize', 'off');

hf_MAIN = a;

set(hf_MAIN, 'HandleVisibility', 'callback');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the frames
% pos_l=2;
% pos_w=FIGURESIZE(3)-4;
% pos_h=FIGURESIZE(4)-4;
% pos_t=FIGURESIZE(4)-2-pos_h;
% h_f_background = uicontrol('Parent',a, ...
%   'BackgroundColor',[0.8 0.9 0.9], ...
%   'Position',[pos_l pos_t pos_w pos_h], ...
%   'Style','frame', ...
%   'Tag','f_background');
margin = 4;
pos_l = margin;
pos_w = 2*win_width/3;
pos_h = 220;
pos_t=FIGURESIZE(4)-margin-pos_h;
h_f_data = uicontrol('Parent',a, ...
  'BackgroundColor',[0.7 0.8 0.8], ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'Style','frame');

pos_h=pos_t - margin - margin/2;
pos_t=4;
h_f_params = uicontrol('Parent',a, ...
  'BackgroundColor',[0.7 0.8 0.8], ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'Style','frame');

pos_l = pos_l + pos_w + margin/2;
pos_w = win_width/3-8;
pos_h = FIGURESIZE(4)-2*margin;
pos_t = FIGURESIZE(4)-margin-pos_h;
h_f_side = uicontrol('Parent',a, ...
  'BackgroundColor',[0.6 0.7 0.7], ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'Style','frame');

%----------------------------------------------------------
bgc = get(h_f_data, 'BackgroundColor');
pos_frame = get(h_f_data, 'Position');

% Controls in f_data
pos_h = 20;
pos_w = 200;
pos_l = pos_frame(1) + 6;
pos_t = pos_frame(2) + pos_frame(4) - pos_h - 6;
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','EEG data', ...
  'FontSize', 10, 'FontWeight', 'bold', ...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_loadStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Not loaded yet', ...
  'FontSize', 10,...
  'Style','text');

% info about the data
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Number of channels:', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_channelsStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','-', ...
  'FontSize', 10,...
  'Style','text');

[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Number of time points:', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_samplesStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','-', ...
  'FontSize', 10,...
  'Style','text');

[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Time range:', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_timerangeStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','-', ...
  'FontSize', 10,...
  'Style','text');

[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Sampling rate:', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_samplingrateStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','-', ...
  'FontSize', 10,...
  'Style','text');

[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','BSS/gBSS weights:', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + pos_w;
pos_w = 100;
ht_weightsStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Not loaded yet', ...
  'FontSize', 10,...
  'Style','text');

[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Keep electrode space:', ...
  'Style','text', ...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
hcm_electrode_space = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'Callback','gui_callback KeepElectrodes', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'Style','checkbox', ...
  'FontSize', 10, ...
  'Value',0);

%-------------------------------------------------
% Controls in f_params
% title
pos_frame=get(h_f_params, 'Position');
pos_l = pos_frame(1) + 6;
pos_h = 20;
pos_t = pos_frame(2) + pos_frame(4) - pos_h - 6;
pos_w = 200;
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Parameters of the analysis', ...
  'FontWeight', 'bold', ...
  'Style','text', ...
  'FontSize', 10);

% which conditions
pos_l = pos_frame(1) + 6;
pos_t = pos_t - 10 - pos_h;
pos_w = 150;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback ChooseEvents', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'FontSize', 10,...
  'String','Choose events',...
  'Tag', 't_choose_events');

pos_l = pos_l + 200;
pos_w = 190;
ht_eventsStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Conditions are not chosen yet', ...
  'FontSize', 10,...
  'Style','text');

% merge or compare
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Merge or compare conditions:', ...
  'Style','text', ...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
hpm_compare = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeCompare', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String',c_Compare_strD, ...
  'Style','popupmenu', ...
  'FontSize', 10, ...
  'Value',g_params.compare,...
  'Tag', 't_compare');

% ind or group
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Individual or group:', ...
  'Style','text', ...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
hpm_individual = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeIndividual', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String',c_Individual_strD, ...
  'Style','popupmenu', ...
  'FontSize', 10, ...
  'Value',g_params.individual,...
  'Tag', 't_individual');

% which channels
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Which channels to include:', ...
  'TooltipString', 'Acceptable format is 1,2,3,.. or 1:3', ...
  'FontSize', 10,...
  'Style','text');

pos_l = pos_l + 200;
pos_w = 100;
he_chanOI = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeChanOI', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','1', ...
  'FontSize', 10,...
  'Style','edit');

% which frequencies
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Frequncy range of interest:', ...
  'FontSize', 10,...
  'TooltipString', 'Acceptable format is 1:45', ...
  'Style','text');

pos_l = pos_l + 200;
pos_w = 100;
he_freqOI = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeFreqOI', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','1:45', ...
  'Style','edit', ...
  'FontSize', 10);

% which time range
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Time range of interest, ms:', ...
  'FontSize', 10,...
  'TooltipString', 'Acceptable format is 0:500', ...
  'Style','text');

pos_l = pos_l + 200;
pos_w = 100;
he_timeOI = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeTimeOI', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','0:500', ...
  'Style','edit', ...
  'FontSize', 10);

%--------------------------------
% Spectral analysis parameters
pos_l = pos_frame(1) + 6;
pos_t = pos_t - 15 - pos_h;
pos_w = 300;
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Parameters of the spectral decomposition', ...
  'FontWeight', 'bold', ...
  'Style','text', ...
  'FontSize', 10);

% which transform
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Short-Time FT or Wavelets:', ...
  'Style','text', ...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
hpm_method = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeMethod', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String',c_Method_strD, ...
  'Style','popupmenu', ...
  'FontSize', 10, ...
  'Value',g_params.method);

% dB or raw
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Tansform data in dB:', ...
  'Style','text', ...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
hcm_dB = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'Callback','gui_callback ChangedB', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'Style','checkbox', ...
  'FontSize', 10, ...
  'Value',g_params.dB);

% baseline
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h*2, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h*2], ...
  'String','Baseline for dB convertion in ms:', ...
  'TooltipString', 'Acceptable format is -400:-200', ...
  'Style','text', ...
  'FontSize', 10,...
  'Tag', 't_baseline');

pos_l = pos_l + 200;
pos_w = 100;
pos_t = pos_t + pos_h;
he_baseline = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChangeBaseline', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','-400:-200', ...
  'Style','edit', ...
  'FontSize', 10);

pos_l = pos_frame(1) + 6;
pos_t = pos_t - 10 - pos_h;
pos_w = 150;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback AdvancedSettings', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'FontSize', 10,...
  'String','Advanced settings');

%--------------------------------
% Plotting parameters
pos_l = pos_frame(1) + 6;
pos_t = pos_t - 15 - pos_h;
pos_w = 300;
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Parameters of the plot(s)', ...
  'FontWeight', 'bold', ...
  'Style','text', ...
  'FontSize', 10);

% time landmarks
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h*2, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h*2], ...
  'String','Plot landmarks on the time axis at ... ms:', ...
  'TooltipString', 'Acceptable format is 0,200,...', ...
  'Style','text',...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
pos_t = pos_t + pos_h;
he_timeLM = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChooseTimeLM', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','0', ...
  'Style','edit', ...
  'FontSize', 10);

% frequency landmarks
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h*3, pos_frame);
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h*2], ...
  'String','Plot landmarks on the frequency axis at ... Hz:', ...
  'TooltipString', 'Acceptable format is 7,13,19,...', ...
  'Style','text',...
  'FontSize', 10);

pos_l = pos_l + 200;
pos_w = 100;
pos_t = pos_t + pos_h;
he_freqLM = uicontrol('Parent',a, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','gui_callback ChooseFreqLM', ...
  'HorizontalAlignment','right', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','7,13,19,30,44', ...
  'Style','edit', ...
  'FontSize', 10);

% Error and warning line
pos_l = pos_frame(1) + 6;
pos_t = pos_frame(2) + 6;
pos_h = 30;
pos_w = 350;
ht_errorStatus = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Callback','gui_callback Error', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','', ...
  'ForegroundColor', [1 1 1],...
  'FontWeight', 'bold', ...
  'Style','text',...
  'FontSize', 10);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Controls in f_side
pos_vspace = 6;
pos_hspace = 22;
pos_temp=get(h_f_side, 'Position');
pos_l=pos_temp(1)+pos_hspace;
pos_w=150;
pos_h=30;
pos_t=pos_temp(2)+pos_temp(4)-pos_vspace-pos_h;

b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback LoadData', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Load *.set data',...
  'FontWeight', 'bold','FontSize', 10);

pos_t=pos_t-pos_h-pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback LoadWeights', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Load BSS/gBSS weights',...
  'FontSize', 10);

pos_t=pos_t-pos_h-pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback PlotSpectra', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Plot spectrogram(s)',...
  'FontWeight', 'bold','FontSize', 10);

pos_t=pos_t-pos_h-pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback SaveImage', ...
  'Interruptible', 'off', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Save images',...
  'FontSize', 10);

pos_t=pos_t-pos_h-pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback Quit', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Quit',...
  'FontSize', 10);

% pos_t=pos_t-pos_h-pos_vspace;
% b = uicontrol('Parent',a, ...
%   'BackgroundColor',[0.9 0.9 0.9], ...
%   'Callback','gui_callback Interrupt', ...
%   'Position',[pos_l pos_t pos_w pos_h], ...
%   'String','Interrupt', ...
%   'Visible','off');

pos_t = pos_frame(2) + pos_vspace + pos_h + pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback About', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','About...', ...
  'FontSize', 10);

pos_t = pos_frame(2) + pos_vspace;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback Help', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Help', ...
  'FontSize', 10);
%--------------------------------------------
% Do rest of the initialization...
  gui_callback InitAll;
  gui_callback_advanced InitAll;


function [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame)
    pos_w = 200;
    pos_l = pos_frame(1) + 6;
    pos_t = pos_t - 10 - pos_h;
end

end