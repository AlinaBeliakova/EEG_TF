function gui_callback(action)
% This function is called by EEG_TF
% This file contains the callbacks to the main window

% Handles to other controls in this main window
global ht_loadStatus
global ht_weightsStatus
global ht_channelsStatus
global hcm_electrode_space
global ht_samplesStatus
global ht_timerangeStatus
global ht_samplingrateStatus
global ht_eventsStatus
global ht_errorStatus
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
global g_EEG_dataset;
global g_params;
global c_Individual_strV;
global c_Compare_strV;
global c_Method_strV;
global c_binary_strV;

c_Individual_strV = {'individual'; 'group'};
c_Compare_strV = {'compare'; 'merge'};
c_Method_strV = {'stft'; 'wavelets'};
c_binary_strV = {'no'; 'yes'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
watchonInFigure = watchon;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch action
    %-------------------------------------
    case 'InitAll'
        % if the data is initiated
        if ~isempty(g_EEG_dataset)
            % if EEGlab set is loaded
            if ~isempty(g_EEG_dataset.EEG)
                set(ht_loadStatus, 'String', '');
                g_EEG_dataset.data = [];
                if iscell(g_EEG_dataset.filenames)
                    set(ht_loadStatus, 'String', strcat(num2str(length(g_EEG_dataset.filenames)),' dataset(s)'));
                else
                    set(ht_loadStatus, 'String', '1 dataset(s)');
                end
                
                set(ht_channelsStatus, 'String', num2str(g_EEG_dataset.EEG.nbchan));
                set(ht_samplesStatus, 'String', num2str(g_EEG_dataset.EEG.pnts));
                set(ht_timerangeStatus, 'String', strcat('[',num2str(round(g_EEG_dataset.EEG.xmin*1000)),...
                    ':', num2str(round(g_EEG_dataset.EEG.xmax*1000)), ']ms'));
                set(ht_samplingrateStatus, 'String', num2str(g_EEG_dataset.EEG.srate));
                % set timeOI and freqOI according the data
                set(he_freqOI, 'String', strcat('1:', num2str(round(g_EEG_dataset.EEG.srate/2))));
                g_params.freqOI = [1:round(g_EEG_dataset.EEG.srate/2)];
                set(he_timeOI, 'String', strcat(num2str(round(g_EEG_dataset.EEG.xmin*1000)),...
                    ':', num2str(round(g_EEG_dataset.EEG.xmax*1000))));
                g_params.timeOI = [round(g_EEG_dataset.EEG.xmin*1000),round(g_EEG_dataset.EEG.xmax*1000)];
                g_params.timeOI = [g_EEG_dataset.EEG.xmin*1000, g_EEG_dataset.EEG.xmax*1000];
                
                if ~isempty(g_EEG_dataset.EEG.icaweights)
                    set(ht_weightsStatus, 'String', 'Included');
                    g_EEG_dataset.w = g_EEG_dataset.EEG.icaweights;
                else
                    set(ht_weightsStatus, 'String', 'Not included');
                    g_EEG_dataset.w = ones(g_EEG_dataset.EEG.nbchan, g_EEG_dataset.EEG.nbchan);
                end
                
                g_params.baseline = [g_EEG_dataset.EEG.xmin*1000, g_EEG_dataset.EEG.xmax*1000];
                if g_EEG_dataset.EEG.xmin < 0
                    g_params.baseline(2) = 0;
                end
                set(he_baseline, 'String', strcat(num2str(round(g_params.baseline(1))),...
                    ':', num2str(round(g_params.baseline(2)))));
                
            else
                % if data is passed in the function from the workspace
                if ~isempty(g_EEG_dataset.data)
                    data_sz = size(g_EEG_dataset.data);
                    set(ht_loadStatus, 'String', 'Loaded');
                    set(ht_channelsStatus, 'String', num2str(data_sz(1)));
                    set(ht_samplesStatus, 'String', num2str(data_sz(2)));
                    set(ht_timerangeStatus, 'String', ...
                        sprintf('[%i:%i]ms',round(g_EEG_dataset.time(1)*1000), round(g_EEG_dataset.time(end)*1000)));
                    set(ht_samplingrateStatus, 'String', num2str(g_EEG_dataset.fs));
                    % set timeOI and freqOI according the data
                    set(he_freqOI, 'String', strcat('1:', num2str(round(g_EEG_dataset.fs/2))));
                    g_params.freqOI = [1:round(g_EEG_dataset.fs/2)];
                    set(he_timeOI, 'String', strcat(num2str(round(g_EEG_dataset.time(1)*1000)),...
                        ':', num2str(round(g_EEG_dataset.time(2)*1000))));
                    g_params.timeOI = [g_EEG_dataset.time(1)*1000, g_EEG_dataset.time(2)*1000];
                    
                    % set baseline - all the timeperiod by default, if
                    % there is prestimulus period - take it
                    g_params.baseline = [g_EEG_dataset.time(1)*1000, g_EEG_dataset.time(2)*1000];
                    
                    if g_EEG_dataset.time(1) < 0
                        g_params.baseline(2) = 0;
                    end
                    set(he_baseline, 'String', strcat(num2str(round(g_params.baseline(1))),...
                        ':', num2str(round(g_params.baseline(2)))));

                    % disable the chose of conditions, merge and individual
                    set(hpm_compare,'Enable','off');
                    set(hpm_individual,'Enable','off');
                end
            end
        
            % initiate the settings with string values in the workspace
            gui_callback ChangeIndividual
            gui_callback ChangeCompare
            gui_callback ChangeMethod
            gui_callback ChangedB

            set(ht_errorStatus, 'String', 'Ready', 'ForegroundColor', [1 1 1]);
        
        end
     %---------------------------------------  
     case 'LoadData'
         % in the beginning, we do not load all the data at the same time - 
         % we 'preload' the first dataset to get info about events, the rest 
         % of the data is uploaded later   
        [g_EEG_dataset.filenames, g_EEG_dataset.pathname] = uigetfile('*.set', 'Select the individual or group .set files.','MultiSelect','on');
        % uigetfile() returns cell if there is multiselect and simple char if there is only one name selected
        if iscell(g_EEG_dataset.filenames)
            g_EEG_dataset.nb_files = size(g_EEG_dataset.filenames, 2);
            first_filename = g_EEG_dataset.filenames{1, 1};
        else
            g_EEG_dataset.nb_files = 1;
            first_filename = g_EEG_dataset.filenames;
        end
        % try to read the first file, check if EEGlab is in the path, addpath if not
        try
            g_EEG_dataset.EEG = pop_loadset(strcat(g_EEG_dataset.pathname,'\',first_filename));
        catch ME
            if (strcmp(ME.identifier,'MATLAB:UndefinedFunction'))
                warning('EEGLAB is not in the path');
                set(ht_errorStatus, 'String', 'EEGLAB is not in the path', 'ForegroundColor', [1 0 0]);
                selpath = uigetdir(path,'Select the path to EEGLAB library');
                addpath(genpath(selpath));
                g_EEG_dataset.EEG = pop_loadset(strcat(g_EEG_dataset.pathname,'\',first_filename));
            end
        end
        
        % cast the data in double precision
        g_EEG_dataset.EEG.data = double(g_EEG_dataset.EEG.data);
        
        g_EEG_dataset.time = [g_EEG_dataset.EEG.xmin, g_EEG_dataset.EEG.xmax];
        g_EEG_dataset.fs = g_EEG_dataset.EEG.srate;
        
        for event = 1:length(g_EEG_dataset.EEG.event)
            all_events{event} = g_EEG_dataset.EEG.event(event).type;
        end
        all_events = unique(all_events);
        g_EEG_dataset.events = all_events;
        clear all_events
        
        % enable all the settings
        set(hpm_compare,'Enable','on');
        set(hpm_individual,'Enable','on');
        
        gui_callback InitAll;
        gui_callback_advanced InitAll;

    case 'LoadWeights'
        [weight_filenames, weight_pathname] = uigetfile('*.mat', 'Select the (g)BSS w weights .mat file.');
        q = load(strcat(weight_pathname,'\',weight_filenames));
        fields = fieldnames(q);
        name = strcat('q.',fields{1});
%         name = strcat('q.',weight_filenames(1:end-4));
        g_EEG_dataset.w = eval(name);
        set(ht_weightsStatus, 'String', 'Loaded');
        set(ht_errorStatus, 'String', 'Ready', 'ForegroundColor', [1 1 1]);
        
    case 'KeepElectrodes' % initially it is off
        if isempty(g_EEG_dataset) % if there is no EEG dataset it won't work
            set(ht_errorStatus, 'String', 'Please, load the data first!', 'ForegroundColor', [1 0 0]);
            set(hcm_electrode_space, 'Value', 0);
        elseif get(hcm_electrode_space, 'Value') == 1 % keep electrode space
            g_EEG_dataset.w = ones(g_EEG_dataset.EEG.nbchan);
            set(ht_errorStatus, 'String', 'Ready', 'ForegroundColor', [1 1 1]);
        elseif (get(hcm_electrode_space, 'Value') == 0) && ~isempty(g_EEG_dataset.EEG.icaweights)
            % if the setting was off, then on, then off again, use the
            % included weights
            g_EEG_dataset.w = g_EEG_dataset.EEG.icaweights; 
            set(ht_weightsStatus, 'String', 'Included');
            set(ht_errorStatus, 'String', 'Load the (g)BSS weigths if you do not want use the uncluded ones', 'ForegroundColor', [1 1 1]);
        else
            set(ht_errorStatus, 'String', 'Load the (g)BSS weigths as there are no uncluded ones!', 'ForegroundColor', [1 0 0]);
        end
    
    case 'ChooseEvents'
        % if some events were chosen before, remove them the params
        if ~isempty(g_params.eventsOI)
            g_params.eventsOI = [];
        end
        % events can be chosen only after some data is loaded, otherwise
        % there is no list of events available
        if isempty(g_EEG_dataset)
            set(ht_errorStatus, 'String', 'Please, load the data first!', 'ForegroundColor', [1 0 0]);
        elseif isempty(g_EEG_dataset.events)
            % this is the case for the data from workspace
            set(ht_errorStatus, 'String', 'There is no information about events in this dataset!', 'ForegroundColor', [1 0 0]);
        else
            indx = listdlg('PromptString','Include condition(s)','ListString', g_EEG_dataset.events);
            eventsOI = '';
            if length(indx) == length(g_EEG_dataset.events)
                g_params.eventsOI = g_EEG_dataset.events;
                eventsOI = 'all';
            else
                for num_indx = 1:length(indx)
                    g_params.eventsOI{1,num_indx} = g_EEG_dataset.events{indx(num_indx)};
                    eventsOI = strcat(eventsOI, g_params.eventsOI{1,num_indx}, '; ');
                end
            end
            clear indx
            set(ht_eventsStatus, 'String', eventsOI);
        end
        gui_callback ChangeCompare
        
    case 'ChangeCompare' % compare = 1, merge = 2
        g_params.compare = c_Compare_strV{get(hpm_compare, 'Value')};
        % there has to be 2 events for comparison
        if size(g_params.eventsOI,2) ~= 2 && strcmp(g_params.compare, 'compare')
            g_params.compare = c_Compare_strV{2};
        end
        
    case 'ChangeIndividual' % individual = 1, group = 2
        g_params.individual = c_Individual_strV{get(hpm_individual, 'Value')};
        % if there is only one file, only individual amalysis is possible
        if g_EEG_dataset.nb_files == 1
            g_params.individual = c_Individual_strV{1};
        end
        
    case 'ChangeChanOI'
        % in case they are written in the form of '1,2,3'
        g_params.chanOI = str2double(strsplit(get(he_chanOI, 'String'), ','));
        %in case they are written in the form '1:5'
        if isnan(g_params.chanOI)
            lims = str2double(strsplit(get(he_chanOI, 'String'),':'));
            g_params.chanOI = lims(1):lims(2);
        end
        
    case 'ChangeFreqOI'
        lims = str2double(strsplit(get(he_freqOI, 'String'),':'));
        g_params.freqOI = lims(1):lims(2);
        
    case 'ChangeTimeOI'
        lims = str2double(strsplit(get(he_timeOI, 'String'),':'));
        g_params.timeOI = [lims(1),lims(2)];
        
    case 'ChangeMethod' % STFT = 1, wavelets = 2
        g_params.method = c_Method_strV{get(hpm_method, 'Value')};
   
    case 'ChangedB' % dB = 1, raw = 2
        g_params.dB = c_binary_strV{get(hcm_dB, 'Value')+1};
        if get(hcm_dB, 'Value')
            set(he_baseline,'Enable','on');
            g_params.baseline = str2double(strsplit(get(he_baseline, 'String'),':'));
        else % otherwise put to zero
            set(he_baseline,'Enable','off');
            g_params.baseline = 0;
        end
        
    case 'ChangeBaseline'
        % if dB transformation is checked use the baseline
        g_params.baseline = str2double(strsplit(get(he_baseline, 'String'),':'));
      
    case 'AdvancedSettings'
        if isempty(g_EEG_dataset) % if there is no EEG dataset it won't work
            set(ht_errorStatus, 'String', 'Please, load the data first!', 'ForegroundColor', [1 0 0]);
        else
            advanced_tf()
            set(ht_errorStatus, 'String', 'Ready', 'ForegroundColor', [1 1 1]);
        end
        
%     case 'ChangeAccelerate'
%         g_params.accelerate = c_binary_strV{get(hcm_accelerate, 'Value')+1};
        
    case 'ChooseTimeLM'
        g_params.time_landmarks = str2double(strsplit(get(he_timeLM, 'String'), ','));
        
    case 'ChooseFreqLM'
        g_params.freq_landmarks = str2double(strsplit(get(he_freqLM, 'String'), ','));
        
    case 'PlotSpectra'
        % check if the data is loaded
        try
%             isempty(g_EEG_dataset.EEG);
            isempty(g_EEG_dataset.data);
        catch ME
            if (strcmp(ME.identifier,'MATLAB:nonExistentField')) || (strcmp(ME.identifier,'MATLAB:structRefFromNonStruct'))
                set(ht_errorStatus, 'String', 'Please, load the data first!', 'ForegroundColor', [1 0 0]);
                return
            end
        end 
        
        % go on to the analysis if the data is ready
        [g_params, g_EEG_dataset] = perform_analysis(g_params, g_EEG_dataset);
        
        % save the settings for the case of repeated analysis
        g_params.previous_settings = g_params;

    case 'SaveImage'
        save_to = uigetdir(cd,'Navigate to the folder where the pictures will be saved');
        FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
        image_count = 0;
        for iFig = length(FigList):-1:1
            FigHandle = FigList(iFig);
%             image_count = image_count + 1;
            if ~strcmp(FigHandle.Name,'EEG_TF') && ~strcmp(FigHandle.Name,'f_FT_SETTINGS') % save and close all the figures except the main GUI and possibly advanced settings
                image_count = image_count + 1;
                savefig(FigHandle, strcat(save_to, '\EEG_TF_Image', num2str(image_count), '.fig'));
                saveas(FigHandle, strcat(save_to, '\EEG_TF_Image', num2str(image_count), '.jpg'));
%                 savefig(FigHandle, strcat(save_to, '\',g_EEG_dataset.filenames{1,FigList(iFig).Number - image_count}(1:end-4),'_EEGTF_Image', '.fig'));
%                 saveas(FigHandle, strcat(save_to, '\',g_EEG_dataset.filenames{1,FigList(iFig).Number - image_count}(1:end-4),'_EEGTF_Image', '.jpg'));
                close(FigHandle)
            end
        end
        
    case 'Quit'
%         % close all the figures open, incliding the gui
%         FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
%         for iFig = 1:length(FigList)
%             close(FigList(iFig))
%         end
        close all
        % clear the used global variables.
        gui_clearvars;
        clearvars
        % Use return to avoid reaching the watchoff statement at the end
        return;
         
    case 'About'
        gui_help('gui_cb_about');

    case 'Help'
        gui_help('gui_cb_help');

end % switch

watchoff (watchonInFigure);