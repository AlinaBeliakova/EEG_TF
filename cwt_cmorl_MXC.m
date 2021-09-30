function  tf = cwt_cmorl_MXC(signal, srate, frex, params)
%
% function  tf = cwt_cmorl_MXC(signal, srate, frex, params)
% Used by CALCULATE_TF
%
% Computes the complex Morlet wavelet transform.
% The algorithm is taken from Mike X Cohen lectures, 
% Mike X Cohen (2014) Fundamentals of Time-Frequency Analyses in 
% Matlab/Octave. 1st ed, sinc(x) Press
% 
% INPUT
% - signal:     1-D timeseries
% - srate:      data sampling rate in Hz
% - frex:       frequencies at which causality, coherence and power are computed (vector)
% - params:     parameters in the special structure
% OUTPUT
% - tf:         absolute Morlet wavelet transform (nb_freq by nb_pnts)

wavtime = -1/frex(1):1/srate:1/frex(1)-1/srate; % goes from -2 to 2ms to assure that even lowest frequencies are detected
nData   = length(signal);               % minimum scale: 2/fs
nKern   = length(wavtime);
nConv   = nData + nKern - 1;
halfwav = ceil((length(wavtime)-1)/2);
numfrex = length(frex);

% number of cycles is the key parameter
if params.log == 1
    % nuber of cycles is non-linear and not constant to acheieve more
    % linear time-frequency resolution
    numcyc = logspace(log10(params.nb_cycles(1)),log10(params.nb_cycles(end)),numfrex);
elseif  params.log == 2
    numcyc = linspace(params.nb_cycles(1),params.nb_cycles(end),numfrex);
else
    % number of cycles maybe constant then the time-frequency resolution wont be linear
    numcyc = params.nb_cycles*ones(1,numfrex);
end

% compute Fourier coefficients of EEG data (doesn't change over frequency!)
eegX = fft(signal ,nConv);
% loop over frequencies
for fi=1:numfrex
    % create wavelet
    twoSsquared = 2 * (numcyc(fi)/(2*pi*frex(fi))) ^ 2;
    cmw = exp(2*1i*pi*frex(fi).*wavtime) .* exp( (-wavtime.^2) / twoSsquared );
    % compute fourier coefficients of wavelet and normalize
    cmwX = fft(cmw,nConv);
    cmwX = cmwX ./ max(cmwX);
    % second and third steps of convolution
    buf = ifft( cmwX.*eegX ,nConv );
    % cut wavelet back to size of data
    as(fi,:) = buf(halfwav:end-halfwav);
end
tf = abs(as).^2;

end