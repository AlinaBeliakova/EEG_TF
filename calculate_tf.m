function [tf, time, freq] = calculate_tf(data, fs, freq, time, params)
%
% Used by PLOT_SPECTROGRAM
%
% Returns the time-frequency matrix tf. 
% The size of tf is [Nb_chan, freq, time] (if conditions are merged) or a 
% cell containing two such matrices if conditions are compared


% extract parameters
to_dB = strcmp(params.dB, 'yes');
baseline = params.baseline;

[Nc, Nt, Ntr] = size(data);

% main spectrogramm calculation loop
if strcmp(params.method, 'wavelets')
    S = zeros(Nc,length(freq),Nt);
    % wavelet transform for each channel and trial
    for itrial = 1:Ntr
        s = zeros(Nc,length(freq),Nt); 
        for ichan = 1:Nc
            s(ichan,:,:) = cwt_cmorl_MXC(squeeze(data(ichan,:,itrial)), fs, freq, params.advanced_settings.wavelets);
        end
        S = S + s;
    end
    S = S/Ntr;      % dividing by the number of trials

    tf = S;

else % STFT
    % multitapers ml function pxx = pmtm(x,'Tapers',tapertype, freq(1):freq(end), fs)
%     window_len = fix(fs/2);
    window_len = params.advanced_settings.stft.window_length;
    step = params.advanced_settings.stft.step;
    overlap = window_len - step;
    if params.advanced_settings.stft.windowing == 3
        window = window_len;
    elseif params.advanced_settings.stft.windowing == 1
        window = hann(window_len);
    else
        window = blackman(window_len);
    end
    [~,f,t] = spectrogram(squeeze(data(1,:,1)),window,overlap,[],fs); % to know what are the dimentions of the final SDP matrix
    S = zeros(Nc,length(f),length(t));

    for itrial = 1:Ntr
        for ichan = 1:Nc 
            [~,~,~,s(ichan,:,:)] = spectrogram(squeeze(data(ichan,:,itrial)),window,overlap,[],fs);
            % note: this function returns figure = 10log10(ps),analogious to 10*log10(abs(Sx)) but another range of values
        end
        S = S + s; 
    end
    S = S/Ntr;

    foi_limits = dsearchn(f, [freq(1); freq(end)]);
    tf = S(:,foi_limits(1):foi_limits(2),:);
    fix_time = time(1); clear time;
    time = fix_time + t;
    freq = f(foi_limits(1):foi_limits(2));
end

% transform to dB
if to_dB
    for ichan = 1:Nc 
        tmp = squeeze(tf(ichan,:,:));
        % transform the raw power to dB - two options possible - with
        % baseline correction and without
        if size(baseline, 2)>1
            bsln_start = dsearchn(time',baseline(1)/1000);
            bsln_stop = dsearchn(time',baseline(end)/1000);
            baseline = mean(tmp(:,bsln_start:bsln_stop),2);
            tf(ichan,:,:) = 10*log10(tmp./repmat(baseline, [1, size(tf,3)]));
        else
            tf(ichan,:,:) = 10*log10(tmp);
        end
    end
end

end