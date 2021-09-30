function data = gather_two_conditions(EEG, cur_event, w, nb_chanOI)
%
% function data = gather_two_conditions(EEG, cur_event, w, nb_chanOI)
% Used by PERFORM_ANALYSIS
%
% Returns cell with two matrices corresponding to each condition. Each
% matrix has dimentions [nb_chanOI, nb_pnts, nb_trials]. BSS/gBSS weights
% are applied here.
%

global ht_NeuroSpectra_errorStatus

for cond = 1:2
    EEG_cond = pop_selectevent(EEG,'type', cur_event{1,cond});
    if ~isempty(EEG_cond.data)
        [nb_chan, nb_pnts, nb_trials] = size(EEG_cond.data);
        cur_data = reshape(EEG_cond.data,nb_chan, nb_pnts*nb_trials);
        data{cond} = reshape(w*cur_data, [nb_chanOI, nb_pnts, nb_trials]);
    else
        set(ht_NeuroSpectra_errorStatus, 'String', 'Choose events separately for the current dataset', 'ForegroundColor', [1 0 0]);
    end
end