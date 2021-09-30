function plot_spectrogram(data, fs, freq, time, params, nb_file)
%
% function plot_spectrogram(data, fs, freq, time, name, params, nb_files)
% Used by PERFORM_ANALYSIS
% 
% Calculates and plots the spectrogram(s)

global ht_errorStatus
global g_EEG_dataset;

windowing_str = {'Hanning'; 'Blackman'; 'none'};
log_str = {'log';'linear';'const'};
binary_str = {'no'; 'yes'};

% check that the frequency of interest does not exceed the Nyquist frequency
if freq(end)>fs/2
    freq = 1:fs/2;
end

time = time(1):1/fs:time(end);
% additional check up to assure that the data is compatible 
if iscell(data)
    time = time(1:size(data{1,1},2));
else
    time = time(1:size(data,2)); % additional check up to assure that the data is compatible 
end

% Calculate the time-frequency matrix (spectrogram)
% status update
set(ht_errorStatus, 'String', 'Calculating the spectrogram...');

if iscell(data)
    [tf{1},~,~] = calculate_tf(data{1}, fs, freq, time, params);
    [tf{2},t,freq] = calculate_tf(data{2}, fs, freq, time, params);
else
    [tf,t,freq] = calculate_tf(data, fs, freq, time, params);
end

% cut the map according to the time of interest
timeOI_ind = [dsearchn(t', params.timeOI(1)/1000), dsearchn(t', params.timeOI(end)/1000)];
if iscell(data)
    tf{1} = tf{1}(:,:,timeOI_ind(1):timeOI_ind(2));
    tf{2} = tf{2}(:,:,timeOI_ind(1):timeOI_ind(2));
    t = t(timeOI_ind(1):timeOI_ind(2));
else
    tf = tf(:,:,timeOI_ind(1):timeOI_ind(2));
    t = t(timeOI_ind(1):timeOI_ind(2));
end

% prepare the parameters to present in the summary
if ~iscell(g_EEG_dataset.filenames) % if only one dataset is loaded
    subjectID = g_EEG_dataset.filenames;
    subjectID(subjectID == '_') = '-';
elseif iscell(g_EEG_dataset.filenames) && strcmp(params.individual, 'individual')
    subjectID = g_EEG_dataset.filenames{nb_file};
    subjectID(subjectID == '_') = '-';
else
    subjectID = 'Merged data';
end

eventsOI = '-';
if ~isempty(params.eventsOI) % it is empty when the data is passed from the workspace
    for i = 1:length(params.eventsOI)
        eventsOI = strcat(eventsOI,', ', params.eventsOI{i});
    end
    eventsOI(1:2) = ''; % remove the -, from the beginning
end
eventsOI(eventsOI == '_') = '-';

trials = '';
if iscell(data) % if only one dataset is loaded
    for i = 1:length(data)
        trials = strcat(trials, ',', num2str(size(data{i},3)));
    end
    trials(1) = ''; % remove the , from the beginning

else
    trials = num2str(size(data,3));
end

if strcmp(params.method, 'wavelets')
    if length(params.advanced_settings.wavelets.nb_cycles) == 1
        nb_cycles = num2str(params.advanced_settings.wavelets.nb_cycles);
    else
        nb_cycles = strcat(num2str(params.advanced_settings.wavelets.nb_cycles(1)),':',num2str(params.advanced_settings.wavelets.nb_cycles(end)));
    end
    TF_settings = ['         Detailed settings of wavelets transfrom:', newline,...
        strcat('         Number of cycles = ', nb_cycles), newline,...
        strcat('         Number of cycles distribution function = ', log_str{params.advanced_settings.wavelets.log})];
else
     TF_settings = ['        Detailed settings of Short-Time Fourier transfrom:', newline,...
        strcat('         Window function = ', windowing_str{params.advanced_settings.stft.windowing}), newline,...
        strcat('         Window length = ', num2str(params.advanced_settings.stft.window_length)), newline,...
        strcat('         Step = ', num2str(params.advanced_settings.stft.step))];
end

Parameters = [newline,'    Parameters:', newline, newline,...
        strcat('    Subject = ',subjectID), newline,...
        strcat('    Type of the analysis = ', params.individual), newline,...
        strcat('    Events of interest = ', eventsOI), newline,...
        strcat('    Number of trials per event = ', trials), newline,...
        strcat('    Compare or merge the conditions? = ', params.compare), newline,...
        strcat('    Frequency range = ',num2str(params.freqOI(1)), ':', num2str(params.freqOI(end)), ' Hz'), newline,...
        strcat('    Time range = ',num2str(round(params.timeOI(1))), ':', num2str(round(params.timeOI(end))), ' ms'), newline,...
        strcat('    Method (Short-Time FT or Wavelets) = ', params.method), newline,...
        TF_settings, newline,...
        strcat('    Power is transformed to dB? = ', params.dB), newline,...
        strcat('    Baseline for dB correction = [', num2str(params.baseline(1)),':',num2str(params.baseline(end)),'] ms'), newline,...
        strcat('    Sampling rate = ',num2str(fs), 'Hz')];

% plotting for each channel
for ichan = 1:length(params.chanOI) 
    if strcmp(params.compare, 'compare') && iscell(tf)
        % add the third cell - the difference between the conditions 
        params.eventsOI{1,3} = strcat(params.eventsOI{1,1},'-', params.eventsOI{1,2});     
        tf_cur{1} = squeeze(tf{1}(ichan,:,:));
        tf_cur{2} = squeeze(tf{2}(ichan,:,:));
        tf_cur{3} = tf_cur{1} - tf_cur{2};

        % range needed to have the same range of color values on the plots
        range = [min(min(min(tf_cur{1})),min(min(tf_cur{2}))), max(max(max(tf_cur{1})),max(max(tf_cur{2})))];

        % plot conditions and their difference in the same loop
        f = figure('units', 'normalized','outerposition',[.05 .05 .95 .95]);
        ha = tight_subplot(2,2,[.08 .08],[.05 .05],[.05 .05]);
        for cond = 1:3
            set(gcf,'CurrentAxes',ha(cond));
%             subplot(2,2,cond)
            imagesc(t,freq,tf_cur{cond})
            if cond == 1 || cond == 2
                caxis manual
                caxis(range);
            end
            colorbar
            hcb = colorbar;
            hcb.FontSize = 13;
            if strcmp(params.dB, 'yes')
                hcb.Label.String = "Power/Frequency (dB/Hz)";
%                     ylim([freq(1) freq(end - round(0.1*length(freq)))]) % hide the edge effects
            else
                hcb.Label.String = "Raw Power/Frequency";
            end
            set(gca,'YDir','normal', 'fontsize', 13)
            cur_cond_name = params.eventsOI{1,cond};
            cur_cond_name(cur_cond_name == '_') = '-';
            cur_name = sprintf('channel %i, condition %s ', params.chanOI(ichan), cur_cond_name);
            title(sprintf('Time-frequency plot, %s', cur_name), 'FontSize', 15)
            ylabel('Frequency, Hz', 'FontSize', 15); xlabel('Time, sec', 'FontSize', 15);

            % add the time landmarks
            for time_i = 1:length(params.time_landmarks)
                line(repmat(params.time_landmarks(time_i)/1000,1,length(freq)),freq,'Color', 'k','LineWidth',2);
            end
            % add the frequency landmarks
            for freq_i = 1:length(params.freq_landmarks)
                line(t,repmat(params.freq_landmarks(freq_i),1,length(t)),'Color', 'k','LineStyle','--');
            end
%             % restrain the map with the indicated time OI
%             xlim(params.timeOI)
        end
        % add the annotation
        annotation('textbox', [.54, .05, .41, .41], 'String', Parameters, 'FontSize', 12);
        set (f, 'Resize', 'off');

    else % if conditions are not compared
        f = figure('units', 'normalized','outerposition',[0 .3 1 .7]);
        imagesc(t,freq,squeeze(tf(ichan,:,:)))
        colorbar
        hcb = colorbar;
        hcb.FontSize = 13;
        if strcmp(params.dB, 'yes')
            hcb.Label.String = "Power/Frequency (dB/Hz)";
%                 ylim([freq(1) freq(end - round(0.1*length(freq)))]) % hide the edge effects
        else
            hcb.Label.String = "Raw Power/Frequency";
        end
        set(gca,'YDir','normal', 'fontsize', 13)
%         cur_name = sprintf('%s, channel %i', name, params.chanOI(ichan));
        title(sprintf('Time-frequency plot, channel %i', params.chanOI(ichan)), 'FontSize', 15)
        ylabel('Frequency', 'FontSize', 15); xlabel('Time', 'FontSize', 15);

        % add the time landmarks
        for time_i = 1:length(params.time_landmarks)
            line(repmat(params.time_landmarks(time_i)/1000,1,length(freq)),freq,'Color', 'k','LineWidth',2);
        end
        % add the frequency landmarks
        for freq_i = 1:length(params.freq_landmarks)
            line(t,repmat(params.freq_landmarks(freq_i),1,length(t)),'Color', 'k','LineStyle','--');
        end

        a = gca; % get the current axis;
        a.Position(3) = 0.5; % make the image half-window
        annotation('textbox', [.7, .1, .27, .83], 'String', Parameters, 'FontSize', 12);
        set (f, 'Resize', 'off');
    end
end

set(ht_errorStatus, 'String', 'Ready',  'ForegroundColor', [1 1 1]);
end