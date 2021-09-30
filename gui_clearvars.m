function gui_clearvars()
%
% function gui_clearvars()
% Used by GUI_CALLBACK
% 
% Clears global variables
clear global hf_MAIN;

% Handles to other controls in this main window
clear global ht_loadStatus;
clear global ht_weightsStatus
clear global ht_channelsStatus;
clear global ht_samplesStatus;
clear global ht_trialsStatus;
clear global ht_eventsStatus;
clear global ht_errorStatus
clear global hpm_individual
clear global hpm_compare
clear global he_chanOI;
clear global he_freqOI;
clear global hpm_method
clear global hcm_correct
clear global hcm_dB
clear global he_baseline;
clear global hcm_accelerate
clear global he_timeLM
clear global he_freqLM

% Global variables to store all the values
clear global g_EEG_dataset;
clear global g_params;
clear global c_Individual_strV;
clear global c_Compare_strV;
clear global c_Method_strV;
clear global c_binary_strV;
