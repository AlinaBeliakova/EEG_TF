function [params, EEG_dataset] = perform_analysis(params, EEG_dataset)
%
% function data = perform_analysis(params, EEG_dataset)
% Used by GUI_CALLBACK
%
% Plots the spectrograms and returns the data matrix containing the
% spectrogrmas for the further use
% When conditions are compared the data is a cell which contains two fields 
% for each condition, if conditions are merged the data is a usual 
% 3D matrix with dimentions [nb_chanOI, nb_pnts, nb_trials]
% The BSS/gBSS weights are applied here, therefore, if 
% - the channel of interest
% - or/and conditions of interest
% - or/and setting merge/compare
% change all EEG datasets have to be reloaded. Other settings can change
% without reloading the EEG datasets.

global ht_errorStatus;

% duplicate variables for easier access 
w = EEG_dataset.w(params.chanOI,:);
% time = EEG_dataset.time;
% fs = EEG_dataset.fs;
freq = params.freqOI;
nb_chanOI = length(params.chanOI);
% if user did not choose any event explicitly, take all events
if isempty(params.eventsOI)
    params.eventsOI = EEG_dataset.events;
end

% % variable 'cond' is used int he plot's name
% cond = '';
% for i = 1:length(params.eventsOI)
%     cond = sprintf('%s%s_',cond, params.eventsOI{1,i});
% end
cur_event = params.eventsOI;

%----------------------------------------------------------------------
% if analysis is performed for the first time data is empty
if isempty(EEG_dataset.data)
    % check that the EEG is uploaded and upload the first file if not
    % (case when the analysis is redone after previous tries)
    if isempty(EEG_dataset.EEG) && iscell(EEG_dataset.filenames)
        EEG_dataset.EEG = pop_loadset(strcat(EEG_dataset.pathname,'\',EEG_dataset.filenames{1, 1}));
    elseif isempty(EEG_dataset.EEG) && ~iscell(EEG_dataset.filenames)
        EEG_dataset.EEG = pop_loadset(strcat(EEG_dataset.pathname,'\',EEG_dataset.filenames));
    end
    time = [EEG_dataset.EEG.xmin, EEG_dataset.EEG.xmax];
    fs = EEG_dataset.EEG.srate;
    % process the EEG data whch is already uploaded, the trials corresponding to the events has to be separated for the comparison
    if strcmp(params.compare, 'compare') && length(cur_event) == 2 % if conditions have to be compared
        EEG_dataset.data = gather_two_conditions(EEG_dataset.EEG, cur_event, w, nb_chanOI);
    else
        EEG_dataset.EEG = pop_selectevent(EEG_dataset.EEG,'type', cur_event);
        [nb_chan, nb_pnts, nb_trials] = size(EEG_dataset.EEG.data);
        cur_data = reshape(EEG_dataset.EEG.data,nb_chan, nb_pnts*nb_trials);
        EEG_dataset.data = reshape(w*cur_data, [nb_chanOI, nb_pnts, nb_trials]);
    end
    % upload other files and calculate tf maps
    if ~(strcmp(params.individual, 'individual')) && EEG_dataset.nb_files > 1
        % if there are several subjects which should be grouped
        for files = 2:EEG_dataset.nb_files
            EEG_dataset.EEG = pop_loadset(strcat(EEG_dataset.pathname,'\',EEG_dataset.filenames{1, files}));
            % check if the datasets are consistent 
            if time(1) == EEG_dataset.EEG.xmin && time(2) == EEG_dataset.EEG.xmax && fs == EEG_dataset.EEG.srate
                % if conditions have to be compared
                if strcmp(params.compare, 'compare') && length(cur_event) == 2
                    cur_data = gather_two_conditions(EEG_dataset.EEG, cur_event, w, nb_chanOI);
                    EEG_dataset.data{1} = cat(3, EEG_dataset.data{1}, cur_data{1});
                    EEG_dataset.data{2} = cat(3, EEG_dataset.data{2}, cur_data{2});
                else
                    EEG_dataset.EEG = pop_selectevent(EEG_dataset.EEG,'type', cur_event);
                    % check that the EEG is not empty
                    [nb_chan, nb_pnts, nb_trials] = size(EEG_dataset.EEG.data);
                    cur_data = reshape(EEG_dataset.EEG.data,nb_chan, nb_pnts*nb_trials);
                    EEG_dataset.data = cat(3,EEG_dataset.data,reshape(w*cur_data, [nb_chanOI, nb_pnts, nb_trials]));
                end
            else
                set(ht_errorStatus, 'String', 'The datasets are not consistent!', 'ForegroundColor', [1 0 0]);
                return
            end
        end
        EEG_dataset.EEG = []; % release the memory
%         name = sprintf('group_condition%s', cond);
        plot_spectrogram(EEG_dataset.data, fs, freq, time, params, files)
    elseif (strcmp(params.individual, 'individual')) && EEG_dataset.nb_files > 1
        % if there are several subjects for individual analysis
        plot_spectrogram(EEG_dataset.data, fs, freq, time, params, 1)
        for files = 2:EEG_dataset.nb_files
            EEG_dataset.EEG = pop_loadset(strcat(EEG_dataset.pathname,'\',EEG_dataset.filenames{1, files}));
            time = [EEG_dataset.EEG.xmin,EEG_dataset.EEG.xmax];
            fs = EEG_dataset.EEG.srate;
            if strcmp(params.compare, 'compare') && length(cur_event) == 2 % if conditions have to be compared
                EEG_dataset.data = gather_two_conditions(EEG_dataset.EEG, cur_event, w, nb_chanOI);
            else
                EEG_dataset.EEG = pop_selectevent(EEG_dataset.EEG,'type', cur_event);
                [nb_chan, nb_pnts, nb_trials] = size(EEG_dataset.EEG.data);
                cur_data = reshape(EEG_dataset.EEG.data, nb_chan, nb_pnts*nb_trials);
                EEG_dataset.data = reshape(w*cur_data, [nb_chanOI, nb_pnts, nb_trials]);
            end
%             name = sprintf('%s_condition%s', EEG_dataset.filenames{1, files}, cond);
%             name = EEG_dataset.filenames{1, files}(1:end-4);
            plot_spectrogram(EEG_dataset.data, fs, freq, time, params, files)
        end
        EEG_dataset.EEG = []; % release the memory
    else
        % if there is just one subject or already grouped data
%         name = sprintf('%s_condition%s', EEG_dataset.filenames, cond);
        plot_spectrogram(EEG_dataset.data, fs, freq, time, params, 1)
    end
%-----------------------------------------------------------------------    
% if the analysis is repeated or if the data is passed to the main function
% Note: This is a large code but it is needed to avoid reloading the data every
% time the analysis is repeated because the loading sometimes takes a lot of time
% Also, it is directly used if the data is passed to the main function
else 
    if isempty(EEG_dataset.EEG)&&isempty(EEG_dataset.events) % if the data is passed from the workspace then there are no EEG and events fields
        plot_spectrogram(EEG_dataset.data(params.chanOI,:,:), EEG_dataset.fs, freq, EEG_dataset.time, params, 1)
    elseif(strcmp(params.individual, 'individual')) && EEG_dataset.nb_files > 1 
        % if there are several subjects for individual analysis they
        % will have to be reloaded because the personal tfs are not saved
        EEG_dataset.data = [];
        [params, EEG_dataset] = perform_analysis(params, EEG_dataset);
    elseif ~strcmp(params.individual,params.previous_settings.individual)
        % have to redo everything if settings 'individual/group'
        % changed
        EEG_dataset.data = [];
        [params, EEG_dataset] = perform_analysis(params, EEG_dataset);
    else % if there is only one file for individual analysis or the grouped data
        if strcmp(params.compare,'merge') && iscell(EEG_dataset.data)
            % if previously the data was compared and now it has to be
            % merged, then merge it and call the function again
            EEG_dataset.data = cat(3, EEG_dataset.data{1}, EEG_dataset.data{2});
            [params, EEG_dataset] = perform_analysis(params, EEG_dataset);
        elseif strcmp(params.compare,'compare') && ~iscell(EEG_dataset.data) 
            % if previously the data was merged and now it has to be compared, it will be reloaded
            EEG_dataset.data = [];
            [params, EEG_dataset] = perform_analysis(params, EEG_dataset);        
        else
            % check if the conditions has changed
            same_conditions = true;
            for i = 1:length(params.eventsOI)
                same_conditions = strcmp(params.eventsOI{i}, params.previous_settings.eventsOI{i}) && same_conditions;
            end
            % check if the channels has changed
            if length(params.chanOI) == length(params.previous_settings.chanOI)
                same_channels = true;
                for i = 1:length(params.chanOI)
                    same_channels = (params.chanOI(i) == params.previous_settings.chanOI(i)) && same_channels;
                end
            else
                same_channels = false;
            end
            
                
            if same_channels && same_conditions
                % if channelsOI and condiions are not changed reuse the data
                time = [EEG_dataset.time(1), EEG_dataset.time(end)];
                fs = EEG_dataset.fs;
                plot_spectrogram(EEG_dataset.data, fs, freq, time, params, 1)
            else % otherwise reload
                EEG_dataset.data = [];
                [params, EEG_dataset] = perform_analysis(params, EEG_dataset);            
            end
        end
    end
end

end
