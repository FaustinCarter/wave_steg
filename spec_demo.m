function varargout = spec_demo(varargin)
% SPEC_DEMO MATLAB code for spec_demo.fig
% This is a graphical user interface for spec.m
%
% There is also a very basic audio player included so you can listen to the
% sound files that you are looking at.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spec_demo_OpeningFcn, ...
                   'gui_OutputFcn',  @spec_demo_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%The next six functions just make sure everything is the proper color for
%the operating system and computer that it is runing on

% --- Executes just before spec_demo is made visible.
function spec_demo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spec_demo (see VARARGIN)

% Choose default command line output for spec_demo
handles.output = hObject;
handles.player = NaN;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spec_demo wait for user response (see UIRESUME)
% uiwait(handles.spec_demo);

% --- Outputs from this function are returned to the command line.
function varargout = spec_demo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function txt_current_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_current (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edt_nfft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_nfft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edt_overlap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_overlap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function pop_window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%------------Everything below handles user interactions with the form----

% --- Executes on button press in btn_load.
function btn_load_Callback(hObject, eventdata, handles)
% hObject    handle to btn_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    %Load in an audio file and link it to the audio player
    [filename, filepath] = uigetfile('*.wav');
    if filename ~= 0
        cd(filepath);
        set(handles.txt_current,'String',filename);
        [sig, fs] = wavread(filename);
        handles.player = audioplayer(sig,fs);
        handles.player.StopFcn = {@player_stop,handles};
        guidata(handles.spec_demo,handles);
    end
    

% --- Executes on button press in btn_stop.
function btn_stop_Callback(hObject, eventdata, handles)
% hObject    handle to btn_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    %Stops playback
    player = handles.player;
    if isplaying(player)
        stop(player);
        set(handles.btn_play,'String','Play');
    end
    handles.player = player;
    guidata(handles.spec_demo,handles);

% --- Executes on button press in btn_play.
function btn_play_Callback(hObject, eventdata, handles)
% hObject    handle to btn_play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % If stopped or paused, then start playback. Otherwise, pause.
    player = handles.player;
    if isplaying(player)
        pause(player);
        set(hObject,'String','Resume');
    else
        resume(player);
        set(hObject,'String','Pause');
    end
    handles.player = player;
    guidata(handles.spec_demo,handles);
    

% --- Executes on button press in btn_spec.
function btn_spec_Callback(hObject, eventdata, handles)
% hObject    handle to btn_spec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    %Grabs all the data from the different fields
    nfft = str2num(get(handles.edt_nfft,'String'));
    overlap = str2num(get(handles.edt_overlap,'String'));
    wincontents = cellstr(get(handles.pop_window,'String'));
    win = eval(['@' wincontents{get(handles.pop_window,'Value')}]);
    aud_file = get(handles.txt_current,'String');
    islog = get(handles.chk_scale,'Value');
    
    if islog == 1
        scale = 'log';
    elseif islog == 0
        scale = 'lin';
    end
    
    %Set up the axis and plot the spectrogram
    axis(handles.axs_spec);
    spec(aud_file,nfft,overlap,win,scale,handles.spec_demo);
    colorbar;

function player_stop(hObject, eventdata, handles)
% This just changes the text on the play button from Pause to Play
    set(handles.btn_play,'String','Play');
    
%These functions have no purpose, but their existence keeps matlab from
%throwing some errors when certain controls are used.
function edt_nfft_Callback(~,~,~)
%Not used
function chk_scale_Callback(~,~,~)
%Not used
function pop_window_Callback(~,~,~)
%Not used
function edt_overlap_Callback(~,~,~)
%Not used
function btn_spec_ButtonDownFcn(~,~,~)
%Not used       
