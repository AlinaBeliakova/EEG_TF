function advanced_tf()
% 
% Used by GUI_CALLBACK(action)
% This function generates the windows for setting the advanced parameters
% for spectral analysis


% Global variables to store all the values
global g_EEG_dataset;
global g_params;
global hpm_method

% Handles to the advanced settings window STFT
global hcm_stft_default
global hpm_stft_windowing
global c_windowing_strD
global c_windowing_strV
global he_stft_win_length
global he_stft_step
% Handles to the advanced settings window Wavelets
global hcm_wavelets_default
% global hcm_wavelets_correct_nl
global he_wavelets_nb_cycles
global hpm_wavelets_log
global c_linear_strV
global c_linear_strD
% global c_binary_strV


c_windowing_strD = 'Hanning|Blackman|none';
c_windowing_strV = {'Hanning'; 'Blackman'; 'none'};
c_linear_strD = 'log|linear|const';
c_linear_strV = {'log';'linear';'const'};

% open the new dialog window
win_width = 350;
win_height = 220;
FIGURENAME = 'FT advanced settings';
FIGURETAG = 'f_FT_SETTINGS';
SCREENSIZE = get(0,'ScreenSize');
FIGURESIZE = [round(0.5*SCREENSIZE(3))-win_width/2 (SCREENSIZE(4)-round(0.5*SCREENSIZE(4))-win_height/2) win_width win_height];
a = figure('Color',[0.95 0.95 0.95], ...
'Name', FIGURENAME, 'NumberTitle', 'off', ...
'Tag', FIGURETAG, 'Position', FIGURESIZE, ...
'MenuBar', 'none');

margin = 4;
pos_l = margin+1;
pos_w = win_width - 2*margin;
pos_h = win_height - 2*margin;
pos_t = FIGURESIZE(4) - margin - pos_h;

b = uicontrol('Parent',a, ...
'BackgroundColor',[0.7 0.8 0.8], ...
'Position',[pos_l pos_t pos_w pos_h], ...
'Style','frame');
bgc = get(b, 'BackgroundColor');
pos_frame = get(b, 'Position');

% title
pos_h = 20;
pos_w = win_width - 20;
pos_l = pos_frame(1) + 6;
pos_t = pos_frame(2) + pos_frame(4) - pos_h - 6;
b = uicontrol('Parent',a, ...
  'BackgroundColor',bgc, ...
  'HorizontalAlignment','left', ...
  'Position',[pos_l pos_t pos_w pos_h], ...
  'String','Advanced settings of time-frequency analysis', ...
  'FontSize', 10, 'FontWeight', 'bold', ...
  'Style','text');

% default
[pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
    'BackgroundColor',bgc, ...
    'HorizontalAlignment','left', ...
    'Position',[pos_l pos_t pos_w pos_h], ...
    'String','Set default values:', ...
    'FontSize', 10, ...
    'Style','text');

if get(hpm_method, 'Value') == 1 
    % settings for STFT: windowing (hanning, blackman, hamming, none), window length and step
    % default settings: hanning window, fix(fs/10), fix(window_len/10)
	% default
    pos_l = pos_l + 200;
    pos_w = 100;
    hcm_stft_default = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'Callback','gui_callback_advanced STFT_default', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'Style','checkbox', ...
      'FontSize', 10, ...
      'Value',g_params.advanced_settings.stft.default);
  
    % set the enability of the menu options
    if g_params.advanced_settings.stft.default == 1
        enable = 'off';
    else
        enable = 'on';
    end
    
    % windowing
    [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'HorizontalAlignment','left', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'String','Windowing function:', ...
      'FontSize', 10,...
      'Style','text');

    pos_l = pos_l + pos_w;
    pos_w = 100;
    hpm_stft_windowing = uicontrol('Parent',a, ...
        'BackgroundColor',[1 1 1], ...
        'Callback','gui_callback_advanced STFT_windowing', ...
        'Position',[pos_l pos_t pos_w pos_h], ...
        'String',c_windowing_strD, ...
        'Style','popupmenu', ...
        'FontSize', 10, ...
        'Value',g_params.advanced_settings.stft.windowing,...
        'Enable',enable);
    
    % window length
    [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'HorizontalAlignment','left', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'String','Window length:', ...
      'FontSize', 10,...
      'Style','text');

    pos_l = pos_l + pos_w;
    pos_w = 100;
    he_stft_win_length = uicontrol('Parent',a, ...
        'BackgroundColor',[1 1 1], ...
        'HorizontalAlignment','right',...
        'Callback','gui_callback_advanced STFT_win_length', ...
        'Position',[pos_l pos_t pos_w pos_h], ...
        'String', num2str(g_params.advanced_settings.stft.window_length), ...
        'Style','edit', ...
        'FontSize', 10,...
        'Enable',enable);
    
    % step
    [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'HorizontalAlignment','left', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'String','Step:', ...
      'FontSize', 10,...
      'Style','text');

    pos_l = pos_l + pos_w;
    pos_w = 100;
    he_stft_step = uicontrol('Parent',a, ...
        'BackgroundColor',[1 1 1], ...
        'HorizontalAlignment','right',...
        'Callback','gui_callback_advanced STFT_step', ...
        'Position',[pos_l pos_t pos_w pos_h], ...
        'String', num2str(g_params.advanced_settings.stft.step), ...
        'Style','edit', ...
        'FontSize', 10,...
        'Enable',enable);

else
    % settings for wavelets: correct the tf-nonlinearity, set the number of cycles start and end, linear and non-linear
    % default settings: correct - non-linear from log10(4) to log10(15), if no correction - 8 cycles

    pos_l = pos_l + 200;
    pos_w = 100;
    hcm_wavelets_default = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'Callback','gui_callback_advanced wavelets_default', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'Style','checkbox', ...
      'FontSize', 10, ...
      'Value',g_params.advanced_settings.wavelets.default);
  
    % set the enability of the menu options
    if g_params.advanced_settings.wavelets.default == 1
        enable = 'off';
    else
        enable = 'on';
    end
%     % correct non-linearity
%     [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
%     b = uicontrol('Parent',a, ...
%         'BackgroundColor',bgc, ...
%         'HorizontalAlignment','left', ...
%         'Position',[pos_l pos_t pos_w pos_h], ...
%         'String','Correct tf non-linearity:', ...
%         'FontSize', 10, ...
%         'Style','text');
%     
%     pos_l = pos_l + 200;
%     pos_w = 100;
%     hcm_wavelets_correct_nl = uicontrol('Parent',a, ...
%       'BackgroundColor',bgc, ...
%       'Callback','gui_callback_advanced wavelets_correct_nl', ...
%       'Position',[pos_l pos_t pos_w pos_h], ...
%       'Style','checkbox', ...
%       'FontSize', 10, ...
%       'Value',g_params.advanced_settings.wavelets.correct_nl,...
%       'Enable',enable);
  
    % constant linear or log
    [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
      'BackgroundColor',bgc, ...
      'HorizontalAlignment','left', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'String','Type of correction:', ...
      'FontSize', 10,...
      'Style','text');

    pos_l = pos_l + pos_w;
    pos_w = 100;
    hpm_wavelets_log = uicontrol('Parent',a, ...
        'BackgroundColor',[1 1 1], ...
        'Callback','gui_callback_advanced wavelets_correction', ...
        'Position',[pos_l pos_t pos_w pos_h], ...
        'String',c_linear_strD, ...
        'Style','popupmenu', ...
        'FontSize', 10, ...
        'Value',g_params.advanced_settings.wavelets.log,...
        'Enable',enable);
    
    % number of cycles
    [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame);
    b = uicontrol('Parent',a, ...
        'BackgroundColor',bgc, ...
        'HorizontalAlignment','left', ...
        'Position',[pos_l pos_t pos_w pos_h], ...
        'String','Set number of cycles:', ...
        'FontSize', 10, ...
        'Style','text');
    pos_l = pos_l + 200;
    pos_w = 100;
    if length(g_params.advanced_settings.wavelets.nb_cycles) == 1
        nb_cycles = num2str(g_params.advanced_settings.wavelets.nb_cycles);
    else
        nb_cycles = strcat(num2str(g_params.advanced_settings.wavelets.nb_cycles(1)),':',...
            num2str(g_params.advanced_settings.wavelets.nb_cycles(end)));
    end
   he_wavelets_nb_cycles = uicontrol('Parent',a, ...
      'BackgroundColor',[1 1 1], ...
      'Callback','gui_callback_advanced wavelets_nb_cycles', ...
      'Position',[pos_l pos_t pos_w pos_h], ...
      'Style','edit', ...
      'FontSize', 10, ...
      'TooltipString', 'Acceptable format is 8 (if constant) or 1:15 (if linear or log)', ...
      'String',nb_cycles,...
      'Enable',enable);
    
end

% exit button
pos_t = pos_frame(2) + 6;
pos_l = pos_frame(1) + win_width/2 - 75;
b = uicontrol('Parent',a, ...
  'BackgroundColor',[0.9 0.9 0.9], ...
  'Callback','gui_callback_advanced exit', ...
  'Position',[pos_l pos_t 150 30], ...
  'String','OK', ...
  'FontSize', 10, 'FontWeight', 'bold');

function [pos_l, pos_t, pos_w] = set_position(pos_t, pos_h, pos_frame)
    pos_w = 200;
    pos_l = pos_frame(1) + 6;
    pos_t = pos_t - 10 - pos_h;
end

end
