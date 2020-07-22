function varargout = testing(varargin)

% Begin initialization code
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @testing_OpeningFcn, ...
                   'gui_OutputFcn',  @testing_OutputFcn, ...
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
% End initialization code


% --- Executes just before testing is made visible.
function testing_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;
axes(handles.axes1);
imshow('blank.jpg');
axis off;
% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = testing_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
handles.vid = videoinput('winvideo' , 1, 'YUY2_640X480');
guidata(hObject, handles);

% --- Executes on button press in face.
function face_Callback(hObject, eventdata, handles)
triggerconfig(handles.vid ,'manual');
set(handles.vid, 'TriggerRepeat',inf);
set(handles.vid, 'FramesPerTrigger',1);
handles.vid.ReturnedColorspace = 'rgb';
 handles.vid.Timeout = 5;
start(handles.vid);
while(1)

facedetector = vision.CascadeObjectDetector;                                                 
trigger(handles.vid); 
handles.im = getdata(handles.vid, 1);
bbox = step(facedetector, handles.im);
hello = insertObjectAnnotation(handles.im,'rectangle',bbox,'Face');
imshow(hello);
end
guidata(hObject, handles);


% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
handles.output = hObject;
stop(handles.vid),clear handles.vid %, ,delete(handles.vid)
guidata(hObject, handles);


% --- Executes on button press in eyes.
function eyes_Callback(hObject, eventdata, handles)
triggerconfig(handles.vid ,'manual');
set(handles.vid, 'TriggerRepeat',inf);
set(handles.vid, 'FramesPerTrigger',1);
handles.vid.ReturnedColorspace = 'rgb';
 handles.vid.Timeout = 2;
start(handles.vid);
while(1)
bodyDetector = vision.CascadeObjectDetector('EyePairBig');
bodyDetector.MinSize = [11 45];                                                
trigger(handles.vid); 
handles.im = getdata(handles.vid, 1);
bbox = step(bodyDetector, handles.im);
hello = insertObjectAnnotation(handles.im,'rectangle',bbox,'EYE');
imshow(hello);
end
guidata(hObject, handles);


% --- Executes on button press in upperbody.
function upperbody_Callback(hObject, eventdata, handles)
% hObject    handle to upperbody (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
triggerconfig(handles.vid ,'manual');
set(handles.vid, 'TriggerRepeat',inf);
set(handles.vid, 'FramesPerTrigger',1);
handles.vid.ReturnedColorspace = 'rgb';
 handles.vid.Timeout = 5;
start(handles.vid);
while(1)
bodyDetector = vision.CascadeObjectDetector('UpperBody');
bodyDetector.MinSize = [60 60]; 
bodyDetector.ScaleFactor = 1.05;                                                 
trigger(handles.vid); 
handles.im = getdata(handles.vid, 1);
bbox = step(bodyDetector, handles.im);
hello = insertObjectAnnotation(handles.im,'rectangle',bbox,'UpperBody');
imshow(hello);
end
guidata(hObject, handles);
