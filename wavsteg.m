%USES IM2NOISE TO MERGE ANY JPG PICTURE INTO ANY WAV AUDIO FILE
%By: Faustin Carter, Yale University, 2010
%
%The wavesteg function will automatically rescale the image so that it will
%have the optimal parameters for im2noise. It then adds the noisy file into
%the existing audio file. Output is a wav file of the form
%'steg_imfile_wavfile.wav'. Optionally, you may specify a gain for the
%noise so that it will stand out more clearly in a spectrogram.
%
%wavesteg takes the following arguments:
%
%REQUIRED:
%imfile = The path to 'somefile.jpg' containing the image
%
%wavfile = The path to 'somefile.wav' containing the audio
%
%OPTIONAL:
%gain = Some number which will be multiplied against the noise.
%
function wavsteg(imfile,wavfile,varargin)
    
    %Parse the input arguments for optional inputs
    if nargin > 2
        gain = varargin{1};
    else
        gain = 1;
    end
    
    %Get the filenames for the image and audio files
    [~, imname, ~] = fileparts(imfile);
    [~, wvname, wvext] = fileparts(wavfile);
    [signal, fs] = wavread(wavfile);
    
    %Get the image info (width, height, etc)
    info = imfinfo(imfile);
    
    %Calculate amount of noise in seconds
    ttime = length(signal)/fs;
    
    %Use a nfft point fft where nfft is close to the image height in
    %pixels. This makes sure there is very little degradation in image
    %resolution.
    nfft = 2^(nextpow2(info.Height));
    
    %Call im2noise to convert the image to noise
    noise = im2noise(imfile,ttime,fs,nfft);
    
    %Apply some gain to magnify the image against the existing audio
    noise = noise*gain;
    
    %Pad either the audio or the noise to ensure they are the same length
    %before adding them.
    if length(signal) > length(noise)
        noise = padarray(noise,length(signal)-length(noise),0,'post');
    elseif length(signal) < length(noise)
        signal = padarray(signal,length(noise)-length(signal),0,'post');
    end
    
    %Add the noise to the audio and write out to a file
    steg = signal + noise;
    wavwrite(steg,fs,['steg_' imname '_' wvname wvext]);    
end
    