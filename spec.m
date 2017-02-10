%CREATES A SPECTROGRAM OF AN AUDIO FILE
%By: Faustin Carter, Yale University, 2010
%
%The spec function implements a short time fourier transform algorithm. It 
%chops an audio file up into segments, windows each segment, and then takes
%the FFT of that segment. Segments may be overlapped at the users
%discretion. The single-sided PSD is then computed for each segment,
%rescaled to account for window gain, and a contour plot is created.
%Frequency is on the y-axis in (kHz), time is on the x-axis in (s) and the
%color-map is assigned based on 10*log10(PSD).
%
%spec takes the following arguments:
%
%REQUIRED:
%audio = The path to 'somefile.wav' containing audio
%
%OPTIONAL:
%nfft = The length of the window. Defaults to 512.
%
%over = The overlap length. This must be less than nfft. Defaults to 0.
%
%win = @windowName where @windowName is a supported matlab window handle.
%Defaults to @hamming.
%
%scale = 'lin' for linear freq axis, or 'log' for log2 freq axis
%
%fig = an optional axis handle to plot in
%
%Calling spec(audio) is equivalent to calling spec(audio, 512, 0, @hamming).
%
function spec(audio, varargin)

    %Assign default values
    nfft = 512;
    over = 0;
    win = @hamming;
    scale = 'lin';
    fig = 0;

    %Parse the input arguments and assign defaults if any are missing
    switch size(varargin,2)
        case 0
        case 1
            nfft = varargin{1};
        case 2
            nfft = varargin{1};
            over = varargin{2};
        case 3
            nfft = varargin{1};
            over = varargin{2};
            win = varargin{3};
        case 4
            nfft = varargin{1};
            over = varargin{2};
            win = varargin{3};
            scale = varargin{4};
        case 5
            nfft = varargin{1};
            over = varargin{2};
            win = varargin{3};
            scale = varargin{4};
            fig = varargin{5};
        otherwise
            error='too many input arguments'
            return;
    end

    %Implement some basic error handling to try and minimize user errors
    if over >= nfft
        error='error, over must be < nfft'
        return;
    end

    
    %Read in the audio file. signal contains the audio data, and Fs
    %contains the sampling frequency (which is generally encoded in any
    %audio file)
    [signal, Fs]=wavread(audio);
    
    %Create a nfft point window of the @win type. Note: Future version
    %could have this as an optional parameter, but considering the fixed
    %resoluton, this returns a window size optimized for the best of both
    %worlds (t and f).
    w=(window(win, nfft));
    
    %Compute the gain of the window function for later power normalization
    g=w'*w;
    
    %Convert into column vectors
    signal=signal(:);
    w=w(:);
    
    %Define how far the window moves along the signal for each FFT
    step = nfft-over;
    
    %Calculate the number of time bins and frequency bins based off of the
    %length of the signal, nfft, and the overlap
    num_tbins = ceil(1+(length(signal)-nfft)/(step));
    new_length = nfft+(num_tbins-1)*step;
    
    %Add zeros to the end of the signal to make it evenly divisible when it
    %is chopped into separate time bins
    signal=padarray(signal,new_length-length(signal),0,'post');
    
    %Preallocate xfft (the matrix of FFT'd time bin segments) and psd (the
    %matrix of one-sided power spectral densities)
    xfft=zeros(num_tbins,nfft);
    psd=zeros(num_tbins,nfft/2); %<-- nfft/2 because this is single-sided
    
    
    %Now chop up the signal into chunks, FFT each chunk, and compute the
    %PSD of each FFT'd chunk
    for i = 1:num_tbins
        %Step to the next chunk
        chunk=signal(1+(i-1)*step:(i-1)*step+nfft);
        
        %Multiply the chunk by the window
        chunk = w.*chunk;
        
        %FFT the chunk and save it in the xfft matrix
        xfft(i,:)=fft(chunk,nfft);
        
        %Take the magnitude of each element of the FFT up to and including
        %the nyquist component and stuff that into the psd matrix
        psd(i,:)=xfft(i,1:nfft/2).*conj(xfft(i,1:nfft/2));
        
        %Divide by the window gain to get back the proper scale
        psd(i,:)=psd(i,:)./g;
        
        %Since the data is Real-valued, only need single-sided psd:
        %Multiply by 2, since this is the single-sided psd, and I threw out
        %the symmetric data earlier. However, don't multiply either the DC
        %component or the nyquist component by 2, as they are unique
        psd(i,2:nfft/2-1)=2*psd(i,2:end-1);
        
        %This bit just adds a progress bar so you know how long you'll have
        %to wait for the spectrogram to finish up
        if (rem(i,100)==0)
        
            abort = progressbar(i/num_tbins);
            if abort == 1
                error = 'aborting process'
                return;
            end
        end
    end
    
    %This closes up the progress bar because we are done now
    if (rem(num_tbins,100) ~= 0)
        progressbar(1);
    end
    
    %Compute the total time length of the audio segment
    t_time = length(signal)/Fs;
    
    %Compute the axis bin spacing
    dtbin = t_time/num_tbins;
    dfbin = Fs/nfft;
    
    %Specify the label vectors for the time (T) and frequency (F) axes
    T=0:dtbin:t_time;
    F=0:dfbin:Fs/2;
    
    %Scale frequency
    if strcmp(scale,'log')
        F = log2(F);
    elseif strcmp(scale,'lin')
        F=F./1000;
    end
    
    %Transpose the PSD so that time is on the x-axis
    psd=transpose(psd);
    
    if fig ~= 0
        figure(fig);
    end
    
    %Plot a contour surface of the log(PSD) in db
    surf(T(2:end),F(2:end),10*log10(psd),'EdgeColor','none');
    
    if strcmp(scale,'log')
        ylabel('Frequency (log2(Hz))','FontSize',14);
    elseif strcmp(scale,'lin')
        ylabel('Frequency (kHz)','FontSize',14);
    end
    
    xlabel('Time (s)','FontSize',14);
    axis tight;
    
    %Look at the surface from bird's eye, because I don't care about the
    %3-D aspect, as it is all encoded in the color anyhow.
    view(0,90);
end

