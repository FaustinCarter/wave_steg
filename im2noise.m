%im2noise
%By: Faustin Carter, Yale University, 2010
%
%This function takes an image and creates a .wav file that will return a
%grayscale version of the picture when analyzed with a spectrogram.
%
%im2noise takes the following input arguments:
%
%REQUIRED:
%imfile = 'fileName.jpg' which is the file name to your picture file.
%
%OPTIONAL:
%ttime = the length of time (in seconds) for the output noise. Default is
%5 seconds.
%
%fs = the sampling frequency desired for converting the output noise to an
%actual sound file. Default is 48 KHz. Units are Hz.
%
%nfft = the desired resolution of the spectrogram fft. Default is 512.
%
%im2noise takes the following output arguments:
%
%OPTIONAL:
%noise = what you would get if you used noise = wavread(nsfile).
%
%Fs = what you would get if you used [noise, Fs] = wavread(nsfile).
%
%Example: [noise, Fs] = im2noise('im.jpg', 'ns.wav', 10, 8000, 256) would 
%return a .wav file of noise 10 seconds long, sampled at 8 KHz. A
%spectrogram taken with 256 point fft's would return the original picture.
%
function [varargout]=im2noise(imfile, varargin)

    %Make sure file is a jpg
    [pathstr, name, ext] = fileparts(imfile);
    if ~strcmp(ext,'.jpg')
        error = 'error: this method only supports jpg files'
        return;
    end

    %Parse the input arguments and assign default values if any are missing
    switch size(varargin,2)
        
        case 0
            ttime = 5;
            fs = 48000;
            nfft = 512;
            
        case 1
            ttime = varargin{1};
            fs = 48000;
            nfft = 512;
            
        case 2
            ttime = varargin{1};
            fs = varargin{2};
            nfft = 512;
            
        case 3
            ttime = varargin{1};
            fs = varargin{2};
            nfft = varargin{3};
            
        otherwise
            error = 'error: too many input arguments'
            return;
    end
    
    %Check output args to make sure there aren't too many
    if nargout > 2
        error = 'error: too many output arguments'
        return;
    end
    
    %Calculate number of time bins to make the length of the final noise
    %file match the requested length
    numsamples = round(ttime*fs);
    tbins = floor(numsamples/nfft);
    
    %Read in the image file
    I = imread(imfile);
    
    %Rotate image so it will display correctly on the spectrogram
    I = imrotate(I,-90);
    
    %Resize the image so that the number of horizontal pixels equals the
    %number of time bins, and the number of verticle pixels is half the FFT
    %length. We want half the FFT length, because this picture is only half
    %of a symmetric FFT.
    I = imresize(I,[tbins nfft/2]);
    
    %Convert the picture to grayscale, and invert the colors since dB are
    %measured opposite other scale types.
    J = rgb2gray(I);
    J = mat2gray(J); %<-- rescales intensity to preserve detail
    J=1-J;
    
    %Flip the image, and then append it to the original image so that all
    %the FFTs are symmetric. This will allow the output of the inverse
    %transform to be real-valued.
    J=[J fliplr(J)];
    
    %Take the inverse FFT and force it to be symmetric
    invfft = ifft(J',nfft,'symmetric');
    
    %Convert from a matrix of time segments to a continuous vector of
    %samples
    output = invfft(:);
    
    %Rounding errors often means not getting "exactly" the amount of noise
    %requested in the function call. This pads the output noise with
    %silence at the end so it matches the correct time length
    if length(output)/fs < ttime
        output = padarray(output,round(ttime*fs)-length(output),0,'post');
    end
    
       
    %Parse the output arguments if there are any
    if nargout > 0
        %If outputs are specified, write to them
        outputargs = {output, fs};
        varargout = outputargs(1:nargout);
    else
        %Otherwise, write the new noise vector out to a sound file
        wavwrite(output,fs,[pathstr name '_noise.wav']);
    end
end