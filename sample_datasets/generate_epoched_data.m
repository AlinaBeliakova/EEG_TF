%% This code is used to generate the sample dataset 'epoched_data.set' which 
% is utilizaed as the sample dataset for the EEG_TF toolbox
% Note: To launch this code you need to have EEGLAB toolbox, SEREEGA toolbox 
% (https://github.com/lrkrol/SEREEGA) and the lead field of the New York 
% Head 'sa_nyhead.mat' (https://www.parralab.org/nyhead/) in the path.
 
%%
% set the parameters of the activation signals
srate = 500;
nb_epoch = 10;
nb_pts = 500;
epochs = struct('n', nb_epoch, 'srate', srate, 'length', nb_pts); % the number of epochs to simulate % their sampling rate in Hz% their length in ms

% generate the leadfield
leadfield   = lf_generate_fromnyhead('montage', 'S64');

% define the first activation at 60-80Hz in the first half of the epoch 
% coming from around eyes, add noise
source1 = lf_get_source_nearest(leadfield, [-10 45 -25]);
ersp1 = struct('type', 'ersp', ...
        'frequency', [60 63 77 79], 'amplitude', 1, ...
        'modulation', 'burst', 'modLatency', 100, 'modWidth', 100, 'modTaper',.9);
ersp1 = utl_check_class(ersp1);
noise = struct('type', 'noise','color', 'pink','amplitude', .1);
noise = utl_check_class(noise);
components = utl_create_component(source1, {ersp1, noise}, leadfield);

% define the second activation at 20-30Hz in the second half of the epoch 
% coming from around cuneus area, add noise
source2 = lf_get_source_nearest(leadfield, [-20 -75 20]);
ersp2 = struct('type', 'ersp', ...
        'frequency', [20 22 28 30], 'amplitude', 1, ...
        'modulation', 'burst', 'modLatency', 350, 'modWidth', 200, 'modTaper',.5);
ersp2 = utl_check_class(ersp2);
components(end+1) = utl_create_component(source2, {ersp2, noise}, leadfield);
scalpdata = generate_scalpdata(components, leadfield, epochs); 

% make some visualization to control the result on the channel 12
plot_data(scalpdata, srate, 12)

% save the data in the EEGLAB format
EEG = utl_create_eeglabdataset(scalpdata, epochs, leadfield);
EEG = utl_add_icaweights_toeeglabdataset(EEG, components, leadfield); % save the true forward model weights
pop_saveset(EEG)


%% FUNCTIONS
function plot_data(data, srate, channelOI)
%% check the result
%single channel
figure('Name', num2str(channelOI)), 
subplot(2,2,1), plot(data(channelOI,:,1)), 
title('Single channel'), axis tight
% grand average
subplot(2,2,2), plot(mean(data(channelOI,:,:),3)), 
title('Grand average'), axis tight
% static spectrum
SS = mean(abs(fft(data(channelOI,:,:))),3);
SS = SS/length(SS);
hz = linspace(0, srate/2, floor(length(SS)/2)+1);
subplot(2,2,3), plot(hz, SS(1:round(length(hz)))), 
title('Static spectrum'), axis tight
% spectrogram
[s,w,t] = spectrogram(data(channelOI,:,1),[],[],[], srate);
subplot(2,2,4), imagesc(t,w,abs(s)), title('Spectrogram')
end