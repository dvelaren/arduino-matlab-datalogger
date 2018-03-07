function varargout = arduinoMatlabGUI(varargin)
% ARDUINOMATLABGUI MATLAB code for arduinoMatlabGUI.fig
%      ARDUINOMATLABGUI, by itself, creates a new ARDUINOMATLABGUI or raises the existing
%      singleton*.
%
%      H = ARDUINOMATLABGUI returns the handle to a new ARDUINOMATLABGUI or the handle to
%      the existing singleton*.
%
%      ARDUINOMATLABGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ARDUINOMATLABGUI.M with the given input arguments.
%
%      ARDUINOMATLABGUI('Property','Value',...) creates a new ARDUINOMATLABGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before arduinoMatlabGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to arduinoMatlabGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help arduinoMatlabGUI

% Last Modified by GUIDE v2.5 06-Mar-2018 12:09:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @arduinoMatlabGUI_OpeningFcn, ...
    'gui_OutputFcn',  @arduinoMatlabGUI_OutputFcn, ...
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


% --- Executes just before arduinoMatlabGUI is made visible.
function arduinoMatlabGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to arduinoMatlabGUI (see VARARGIN)

% Choose default command line output for arduinoMatlabGUI
handles.output = hObject;

%Create Measurements and Time vectors handles
handles.started = 0;
handles.sp = 0;
handles.j = 1;
handles.dataT = 0;
handles.dataSP = 0;
handles.dataY = 0;
handles.time = datetime('now');
handles.readData = '';
% handles.axes1 = plot(NaN,NaN); % creates the graphics object with no data
handles.hSP = animatedline;
handles.hSP.Color = 'blue';
handles.hSP.LineWidth = 1;
handles.hY = animatedline;
handles.hY.Color = 'red';
handles.hY.LineWidth = 1;
handles.ax = gca;
handles.ax.XGrid = 'on';
handles.ax.YGrid = 'on';
handles.ax.XLim = datenum([seconds(-15) seconds(0)]);
handles.ax.YLim = [0 1023];
datetick('x','keeplimits')
legend('SP','Y');
xlabel('Time(secs)');
ylabel('Amplitude');

% Update handles structure
guidata(hObject, handles);

% Closes all Open Serial ports
if (isempty(instrfind) == 0)
    fclose(instrfind);
end

% This sets up the initial plot - only do when we are invisible
% so window can get raised using arduinoMatlabGUI.
% if strcmp(get(hObject,'Visible'),'off')
%     plot(rand(5));
% end

% UIWAIT makes arduinoMatlabGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = arduinoMatlabGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in btnStart.
function btnStart_Callback(hObject, eventdata, handles)
% hObject    handle to btnStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(handles.lstSerial,'String'); %Get all contents from popup menu
try
    if handles.started == 0
        handles.started = 1;
        %% Clear plot information and Data
        clearpoints(handles.hSP);
        clearpoints(handles.hY);
        handles.j = 1;
        handles.dataT = [];
        handles.dataSP = [];
        handles.dataY = [];
        %% Initialize serial communication
        handles.s=serial(contents{get(handles.lstSerial,'Value')},'BaudRate',9600); %Creates a new Serial object using selected COM
        % The serial port object must be opened for communication
        handles.s.readAsyncMode = 'continuous';
        handles.s.Timeout = 60;
        handles.s.Terminator='CR/LF';
        if strcmp(handles.s.Status,'closed'), fopen(handles.s); end
        pause(1)
        guidata(hObject, handles);
        %% Establish serial communication
        fprintf(handles.s, '%u\n', handles.sp);
        while isempty(fscanf(handles.s)) end
        flushinput(handles.s);
        
        %% Start timer job to acquire data
        handles.timer = timer('Name','MyTimer',                         ...
            'Period',str2double(handles.txtTS.String),    ...
            'StartDelay',0,                               ...
            'TasksToExecute',inf,                         ...
            'ExecutionMode','fixedSpacing',               ...
            'TimerFcn',{@timerCallback,handles.figure1});
        start(handles.timer);
        guidata(hObject, handles);
        %% Plot variables
        startTime = datetime('now');
        handles.time =  datetime('now') - startTime;
        while handles.started == 1
            handles = guidata(hObject);
            handles.time =  datetime('now') - startTime;
            if ~isempty(handles.readData)
                handles.txtY.String = handles.readData;
                handles.sldY.Value = handles.readData;
                addpoints(handles.hSP,datenum(handles.time),handles.sp)
                addpoints(handles.hY,datenum(handles.time),handles.readData)
                handles.ax.XLim = datenum([handles.time-seconds(15) handles.time]);
                datetick('x','keeplimits')
                drawnow
            end
        end
        guidata(hObject, handles);
    end
catch
    errordlg('Could not connect to selected COM port','Error');
end

function [] = timerCallback(hObj,~,guiHandle)
if ~isempty(guiHandle)
    % get the handles
    handles = guidata(guiHandle);
    if handles.started == 1
        fprintf(handles.s,'%u\n',round(handles.sp));
        handles.readData = fscanf(handles.s,'%u');
        flushinput(handles.s);
        handles.dataT(handles.j) = hObj.Period*handles.j;
        handles.dataSP(handles.j) = round(handles.sp);
        handles.dataY(handles.j) = handles.readData;
        handles.j = handles.j + 1;
        guidata(handles.figure1,handles)
    end
end

% --- Executes on button press in btnStop.
function btnStop_Callback(hObject, eventdata, handles)
% hObject    handle to btnStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(handles.started == 1)
    if isfield(handles, 'timer')
        stop(handles.timer);
    end
    fclose(handles.s);
    delete(handles.s);
    h = msgbox('Stopped successfully','Success');
end
handles.started = 0;
guidata(hObject, handles);

% --- Executes on selection change in lstSerial.
function lstSerial_Callback(hObject, eventdata, handles)
% hObject    handle to lstSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstSerial contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstSerial
if(isempty(seriallist)==1)
    hObject.String = 'No connected instr';
else
    hObject.String = cellstr(seriallist);
end

% --- Executes during object creation, after setting all properties.
function lstSerial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
if(isempty(seriallist)==1)
    hObject.String = 'No connected instr';
else
    hObject.String = cellstr(seriallist);
end
%set(hObject, 'Enable', 'Inactive');

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over lstSerial.
function lstSerial_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lstSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(isempty(seriallist)==1)
    hObject.String = 'No connected instr';
else
    hObject.String = cellstr(seriallist);
end

% --- Executes on slider movement.
function sldSP_Callback(hObject, eventdata, handles)
% hObject    handle to sldSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.txtSP.String = round(hObject.Value);
handles.sp = round(hObject.Value);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sldSP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function txtSP_Callback(hObject, eventdata, handles)
% hObject    handle to txtSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSP as text
%        str2double(get(hObject,'String')) returns contents of txtSP as a double
handles.sldSP.Value = round(str2double(hObject.String));
handles.sp = round(str2double(hObject.String));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function txtSP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on slider movement.
function sldY_Callback(hObject, eventdata, handles)
% hObject    handle to sldY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sldY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function txtY_Callback(hObject, eventdata, handles)
% hObject    handle to txtY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtY as text
%        str2double(get(hObject,'String')) returns contents of txtY as a double

% --- Executes during object creation, after setting all properties.
function txtY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes1



function txtTS_Callback(hObject, eventdata, handles)
% hObject    handle to txtTS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtTS as text
%        str2double(get(hObject,'String')) returns contents of txtTS as a double
% handles.timer.Period = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function txtTS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtTS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnExport.
function btnExport_Callback(hObject, eventdata, handles)
% hObject    handle to btnExport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    T = table(handles.dataT',handles.dataSP',handles.dataY','VariableNames',{'Time','SP','Y'});
    filename = strcat(pwd,filesep,'DataAcquisition.xlsx');
    if exist(filename, 'file')==2
      delete(filename);
    end
    % Write table to file 
    writetable(T,filename);
    msgbox(strcat('Saved succesfully to: ',filename),'Success');
catch
    errordlg('Could not save data','Error');
end
