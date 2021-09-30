function gui_callback_advanced(action)
% Used by ADVANCED_TF
% This file contains the callbacks to the tf transform settings window

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
% global c_linear_strV
% global c_linear_strD
% global c_binary_strV

% Global variables to store all the values
global g_params
global g_EEG_dataset

% c_windowing_strD = 'Hanning|Blackman|none';
% c_windowing_strV = {'Hanning'; 'Blackman'; 'none'};
% c_linear_strD = 'log|linear';
% c_linear_strV = {'log';'linear'};
% c_binary_strV = {'no'; 'yes'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
watchonInFigure = watchon;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch action
    %-------------------------------------
    case 'InitAll'
        g_params.advanced_settings.stft.default = 1; % 1 = yes, 2 = no
        g_params.advanced_settings.stft.windowing = 1; % 1 = Hanning, 2 = Blackman, 3 = none
        if ~isempty(g_EEG_dataset)
%             g_params.advanced_settings.stft.window_length = fix(g_EEG_dataset.fs/10);
%             g_params.advanced_settings.stft.step = fix(g_EEG_dataset.fs/100);
            g_params.advanced_settings.stft.window_length = fix(g_EEG_dataset.fs/4);
            g_params.advanced_settings.stft.step = 1;
        else
            g_params.advanced_settings.stft.window_length = 0;
            g_params.advanced_settings.stft.step = 0;
        end
        
        g_params.advanced_settings.wavelets.default = 1; % 1 = yes, 2 = no
%         g_params.advanced_settings.wavelets.correct_nl = 0; % 1 = yes, 2 = no
        g_params.advanced_settings.wavelets.nb_cycles = 8;
        g_params.advanced_settings.wavelets.log = 3; % 1 = log, 2 = linear, 3 = const
        
    case 'STFT_default'
        g_params.advanced_settings.stft.default = get(hcm_stft_default, 'Value');
        if get(hcm_stft_default, 'Value') == 1 % checked
            g_params.advanced_settings.stft.default = 1; % yes
            g_params.advanced_settings.stft.windowing = 1;
            g_params.advanced_settings.stft.window_length = fix(g_EEG_dataset.fs/4);
            g_params.advanced_settings.stft.step = fix(g_EEG_dataset.fs/100);
            set(hpm_stft_windowing,'Value',1);
            set(he_stft_win_length,'String',num2str(fix(g_EEG_dataset.fs/4)));
            set(he_stft_step,'String',num2str(fix(g_EEG_dataset.fs/100)));
            set(hpm_stft_windowing,'Enable','off');
            set(he_stft_win_length,'Enable','off');
            set(he_stft_step,'Enable','off');
        else  % enable all the settings if default is not checked
            set(hpm_stft_windowing,'Enable','on');
            set(he_stft_win_length,'Enable','on');
            set(he_stft_step,'Enable','on');
        end
        
    case 'STFT_windowing'
        g_params.advanced_settings.stft.windowing = get(hpm_stft_windowing, 'Value');
        
    case 'STFT_win_length'
        g_params.advanced_settings.stft.window_length = str2double(get(he_stft_win_length, 'String'));
        
    case 'STFT_step'
        g_params.advanced_settings.stft.step = str2double(get(he_stft_step, 'String'));
        
    case 'wavelets_default'
        g_params.advanced_settings.wavelets.default = get(hcm_wavelets_default, 'Value');
        if get(hcm_wavelets_default, 'Value') == 1 % checked
            g_params.advanced_settings.wavelets.default = 1; % yes
%             g_params.advanced_settings.wavelets.correct_nl = 0;
            g_params.advanced_settings.wavelets.nb_cycles = 8;
            g_params.advanced_settings.wavelets.log = 3;
%             set(hcm_wavelets_correct_nl,'Value',1);
            set(he_wavelets_nb_cycles,'String','8');
            set(hpm_wavelets_log,'Value', 3);
%             set(hcm_wavelets_correct_nl,'Enable','off');
            set(he_wavelets_nb_cycles,'Enable','off');
            set(hpm_wavelets_log,'Enable','off');
        else  % enable all the settings if default is not checked
%             set(hcm_wavelets_correct_nl,'Enable','on');
            set(he_wavelets_nb_cycles,'Enable','on');
            set(hpm_wavelets_log,'Enable','on');
        end
        
    case 'wavelets_correct_nl'
        % if we don't correct non-linearity, then wa cannot choose the
        % function, the number of cycles will be a single value
        g_params.advanced_settings.wavelets.correct_nl = get(hcm_wavelets_default, 'Value');
        if get(hcm_wavelets_default, 'Value') == 0
            set(hpm_wavelets_log,'Enable','off');
            g_params.advanced_settings.wavelets.log = 3;
            set(he_wavelets_nb_cycles,'String','8'); % default nb_cycles is 8
            g_params.advanced_settings.wavelets.nb_cycles = 8;
        end
        
    case 'wavelets_correction'
        g_params.advanced_settings.wavelets.log = get(hpm_wavelets_log, 'Value');
        % set default recommeneded values accordingto the type ofcorrection
        if g_params.advanced_settings.wavelets.log == 1 % 1 = log, 2 = linear, 3 = const
            set(he_wavelets_nb_cycles, 'String', '2:9');
            g_params.advanced_settings.wavelets.nb_cycles = [2,9];
        elseif g_params.advanced_settings.wavelets.log == 2
            set(he_wavelets_nb_cycles, 'String', '2:9');
            g_params.advanced_settings.wavelets.nb_cycles = [2,9];
        else
            set(he_wavelets_nb_cycles, 'String', '8');
            g_params.advanced_settings.wavelets.nb_cycles = 8;
        end
        
    case 'wavelets_nb_cycles'
        lims = str2double(strsplit(get(he_wavelets_nb_cycles, 'String'),':'));
        if length(lims) == 1
            g_params.advanced_settings.wavelets.nb_cycles = lims(1);
        else
            g_params.advanced_settings.wavelets.nb_cycles = [lims(1),lims(2)];
        end
        
    case 'exit'
        close
        return;
        
end % switch

watchoff (watchonInFigure);