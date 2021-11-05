function varargout = VEP_UDP(varargin)
% VEP_UDP MATLAB code for VEP_UDP.fig
%      VEP_UDP, by itself, creates a new VEP_UDP or raises the existing
%      singleton*.
%
%      H = VEP_UDP returns the handle to a new VEP_UDP or the handle to
%      the existing singleton*.
%
%      VEP_UDP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VEP_UDP.M with the given input arguments.
%
%      VEP_UDP('Property','Value',...) creates a new VEP_UDP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VEP_UDP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VEP_UDP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help VEP_UDP
% Last Modified by GUIDE v2.5 10-Mar-2018 16:20:51
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VEP_UDP_OpeningFcn, ...
                   'gui_OutputFcn',  @VEP_UDP_OutputFcn, ...
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



% --- Executes just before VEP_UDP is made visible.
function VEP_UDP_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VEP_UDP (see VARARGIN)
global Started t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header ErrorCode
% Initialiing
Started = false; 
t=[]; Averaged_Signal_Odd=[]; Averaged_Signal_Even=[]; Averaged_Signal_All=[]; Header=[]; ErrorCode=[];
LoadDefault(handles);% Load and apply default parameters
checkbox_BP_Callback(handles.checkbox_BP, [], handles);% disable parameter for disabled filter
ReviewOfflineSignal(handles);
% Choose default command line output for VEP_UDP
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes VEP_UDP wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VEP_UDP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

function checkbox_BP_Callback(hObject, eventdata, handles)
if get(handles.checkbox_BP,'value')
    set(handles.popupmenu_LowCut,'enable','on');
    set(handles.popupmenu_HighCut,'enable','on');
else
    set(handles.popupmenu_LowCut,'enable','off');
    set(handles.popupmenu_HighCut,'enable','off');
end




% --- Executes on button press in pushbutton_StartStop.
function pushbutton_StartStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_StartStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Started t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header ErrorCode
if ~Started
    set(handles.pushbutton_AdvSet,'enable','off');
    set(handles.checkbox_Notch,'enable','off');
    set(handles.checkbox_BP,'enable','off');
    set(handles.popupmenu_TriggerCount,'enable','off');
    set(handles.popupmenu_LowCut,'enable','off');
    set(handles.popupmenu_HighCut,'enable','off');
    set(handles.pushbutton_StartStop,'ForegroundColor',[0.5, 0, 0]);
    set(handles.pushbutton_StartStop,'BackgroundColor',[0.9, 0.8, 0.8]);
    set(handles.pushbutton_StartStop,'String','STOP');    
    drawnow;
    Started = true;
    cla 
    [Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
          PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate] ...
     = ReadGUIParameters(handles);
 
    VEP_UDP2(Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
        PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,handles,RefreshRate);
    Started = ~Started;
    switch ErrorCode
        case {1}
            p=warndlg('No data is received from the main EEG software.','Warning!');
            waitfor(p);
        case {2}
            p=warndlg({'VEP is stopped or "Sending Mark" is not enabled' 'in the main EEG software.'},'Warning!');
            waitfor(p);
        case {3}
            p=warndlg('VEP is stopped in the main EEG software.','Warning!');
            waitfor(p);        
        case {4}
            p=warndlg('Structure of the data sent by the main EEG software is changed.','Warning!');
            waitfor(p);                      
    end
else
    Started = false;  
end
reset_popupmenu_ChannelName(Header, handles);
ReviewOfflineSignal(handles);
set(handles.pushbutton_AdvSet,'enable','on');
set(handles.checkbox_Notch,'enable','on');
set(handles.checkbox_BP,'enable','on');
set(handles.popupmenu_TriggerCount,'enable','on');
checkbox_BP_Callback(handles.checkbox_BP, eventdata, handles); 
set(handles.pushbutton_StartStop,'ForegroundColor',[0, 0.5, 0]);
set(handles.pushbutton_StartStop,'BackgroundColor',[0.8, 0.9, 0.8]);
set(handles.pushbutton_StartStop,'String','START'); 
drawnow;



function ReviewOfflineSignal(handles)
global t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header ErrorCode
[Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
      PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate] ...
= ReadGUIParameters(handles);
Current_Signal = []; PlotLastSignal = false;
if PlotOddEvenAll(1) % Plotting odd cases
    DoPlotting(t, Current_Signal, Averaged_Signal_Odd, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, 1, handles);
end
if PlotOddEvenAll(2) % Plotting all cases
    DoPlotting(t, Current_Signal, Averaged_Signal_Even, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, 2, handles);
end
if PlotOddEvenAll(3) % Plotting all cases
    DoPlotting(t, Current_Signal, Averaged_Signal_All, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, 3, handles);
end
reset_popupmenu_ChannelName(Header, handles);
 
 


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
%%%% Save Data %%%%
global Started t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header
if ~Started    
    [AddName,path] = uiputfile('*.mat','Save signal'); 
    if AddName
        save([path AddName],'-mat','t', 'Averaged_Signal_Odd', 'Averaged_Signal_Even', 'Averaged_Signal_All', 'Header');
    end
    ReviewOfflineSignal(handles);
end

% --------------------------------------------------------------------
function uipushtool2_ClickedCallback(hObject, eventdata, handles)
%%%% Load Data %%%%
global Started t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header
if ~Started    
    [AddName,path] = uigetfile('*.mat','Load stored signal'); 
    if AddName
        load([path AddName],'-mat');
    end
    ReviewOfflineSignal(handles);
end


% --- Executes on button press in pushbutton_AdvSet.
function pushbutton_AdvSet_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_AdvSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(handles.uipanel2,'visible');
if strcmpi(val,'ON')
    set(handles.uipanel2,'visible','off');
    set(handles.pushbutton_AdvSet,'string','Hide Advanced Setting');
    set(handles.pushbutton_StartStop,'enable','off');
else
    set(handles.uipanel2,'visible','on');
    set(handles.pushbutton_AdvSet,'string','Show Advanced Setting');
    set(handles.pushbutton_StartStop,'enable','on');
end






function pushbuttonDefault_Callback(hObject, eventdata, handles)
[Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
          PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate] ...
        = ReadGUIParameters(handles);
    save('config.mat','-mat','Normalized','HeaderIndex','SampleRate','PlotRange','TrigDelay','PlotOddEvenAll',...
          'PlotLastSignal','BPFilter','BPFreq','BP_Order','NotchFilter','NotchFreq','TrigCount','AmpLim','RefreshRate');
    p=msgbox('Parameters are saved.');
    waitfor(p);  
    
function LoadDefault(handles)% Load and apply default parameters
configAdd = 'config.mat';
if exist(configAdd)
    load('config.mat','-mat');
    ApplyGUIParameters(handles, Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
          PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate);
end

function About_Callback(hObject, eventdata, handles)
    p=msgbox({'EEG Trigger Reader & Averager' 'Negar Andishgan Co. Ltd.' 'March 2018'},'About');
    waitfor(p); 


function checkbox_OddTrig_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function checkbox_EvenTrig_Callback(hObject, eventdata, handles)
global Started  
if ~Started    ReviewOfflineSignal(handles);    end
function checkbox_AllTrig_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function popupmenu_Sens_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function popupmenu_Ch1_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function popupmenu_Ch2_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function popupmenu_Ch3_Callback(hObject, eventdata, handles)
global Started    
if ~Started    ReviewOfflineSignal(handles);    end
function popupmenu_Ch2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_Ch1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_Ch3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_TrigDelayOdd_Callback(hObject, eventdata, handles)
function edit_TrigDelayOdd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_PlotStartTime_Callback(hObject, eventdata, handles)
function edit_PlotStartTime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_PlotEndTime_Callback(hObject, eventdata, handles)
function edit_PlotEndTime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function checkbox_Normalized_Callback(hObject, eventdata, handles)
function edit_TrigDelayEven_Callback(hObject, eventdata, handles)
function edit_TrigDelayEven_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_SampleRate_Callback(hObject, eventdata, handles)
function edit_SampleRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbutton2_Callback(hObject, eventdata, handles)
function pushbutton_StartStop_KeyPress(hObject, eventdata, handles)
function pushbutton_StartStop_ButtonDown(hObject, eventdata, handles)
function popupmenu_Sens_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function checkbox_Notch_Callback(hObject, eventdata, handles)
function popupmenu_LowCut_Callback(hObject, eventdata, handles)
function popupmenu_LowCut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_HighCut_Callback(hObject, eventdata, handles)
function popupmenu_HighCut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function checkbox_PlotLastSignal_Callback(hObject, eventdata, handles)
function popupmenu_TriggerCount_Callback(hObject, eventdata, handles)
function popupmenu_TriggerCount_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_NotchLowCut_Callback(hObject, eventdata, handles)
function edit_NotchLowCut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_NotchHighCut_Callback(hObject, eventdata, handles)
function edit_NotchHighCut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_FIRBPOrder_Callback(hObject, eventdata, handles)
function edit_FIRBPOrder_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function figure1_SizeChangedFcn(hObject, eventdata, handles)



function edit_RefreshRate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_RefreshRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_RefreshRate as text
%        str2double(get(hObject,'String')) returns contents of edit_RefreshRate as a double


% --- Executes during object creation, after setting all properties.
function edit_RefreshRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_RefreshRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
