function out = triggerconfig(obj, varargin)

if ~isa(obj, 'imaqdevice')
    error(message('imaq:triggerconfig:invalidType'));
elseif ~all(isvalid(obj))
    error(message('imaq:triggerconfig:invalidOBJ'));
end

uddobj = imaqgate('privateGetField', obj, 'uddobject');
% If nargin > 1, verify OBJ is not running,
if (nargin > 1) && any(strcmp(get(uddobj, 'Running'), 'on'))
    error(message('imaq:triggerconfig:objRunning'));
end

% Define configuration order.
trigfields = {'TriggerType', 'TriggerCondition', 'TriggerSource'};

% Only allow arrays when configuring.
nObjects = length(uddobj);
if (nargin==1) && (nObjects > 1)
    error(message('imaq:triggerconfig:OBJ1x1'));
elseif nargin==1,
    out = cell2struct(get(uddobj, trigfields), trigfields, 2);
    return;
end

% Configure each object provided. 
prevConfig = cell(length(uddobj), 1);
for i=1:nObjects,
    try
        % Make sure to cache the previous configurations
        % before configuring the new one.
        prevConfig{i} = get(uddobj(i), trigfields);
        localConfig(trigfields, uddobj(i), varargin{:});
    catch exception
        % Attempt to configure back to previous settings.
        for p = 1:length(prevConfig),
            triggerconfig(uddobj(p), prevConfig{p}{:});
        end
        throw(exception);
    end
end

function localConfig(trigfields, uddobj, varargin)

% Parameter parsing.
userSettings = {};
switch nargin
    case 3,
        userInput = varargin{1};
        if isstring(userInput)
            userInput = char(userInput);
        end
        if (~isstruct(userInput) && ~ischar(userInput)) || ...
                (isstruct(userInput) && length(userInput)~=1),
            % Invalid input type.
            error(message('imaq:triggerconfig:invalidParamType'));
            
        elseif isstruct(userInput)
            % TRIGGERCONFIG(OBJ, S)
            validStruct = true;
            usersFields = fieldnames(userInput);
            if ( length(usersFields)~=length(trigfields) )
                validStruct = false;
            else
                for i=1:length(trigfields)
                    if ~isfield(userInput, trigfields{i})
                        validStruct = false;
                    else
                        userSettings{i} = userInput.(trigfields{i});  %#ok<AGROW>
                    end
                end
            end
            
            % Check if the MATLAB structure was correct.
            if ~validStruct
                error(message('imaq:triggerconfig:invalidStruct'));
            end            
        else
            userSettings{1} = userInput;
        end
        
    case 4,
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION)
        if ~imaq.internal.Utils.isCharOrScalarString(varargin{1}) || ...
                ~imaq.internal.Utils.isCharOrScalarString(varargin{2})
            % Invalid data type.
            error(message('imaq:triggerconfig:invalidString'));
        end
        userSettings{1} = char(varargin{1});
        userSettings{2} = char(varargin{2});
        
    case 5,
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION, SOURCE)
        if ~imaq.internal.Utils.isCharOrScalarString(varargin{1}) || ...
                ~imaq.internal.Utils.isCharOrScalarString(varargin{2}) || ...
                ~imaq.internal.Utils.isCharOrScalarString(varargin{3})
            % Invalid data type.
            error(message('imaq:triggerconfig:invalidString'));
        end
        userSettings{1} = char(varargin{1});
        userSettings{2} = char(varargin{2});
        userSettings{3} = char(varargin{3});
        
    otherwise,
        error(message('imaq:triggerconfig:tooManyInputs'));
end

% Get trigger information.
try
    configurations = triggerinfo(uddobj, userSettings{1});
catch exception
    throw(exception);
end

% Perform the configuration.
try
    if length(userSettings)==length(trigfields),
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION, SOURCE)
        userSettings = localFixGigeForNonStandardFeatures(uddobj, userSettings);
        triggerconfig(uddobj, userSettings{:});
        
    elseif (nargin==3),        
        % TRIGGERCONFIG(OBJ, TYPE)
        if (length(configurations)==1),
            % Configuration was unique
            configSettings = struct2cell(configurations);
            triggerconfig(uddobj, configSettings{:});
        else
            % Configuration is not unique
            error(message('imaq:triggerconfig:notUnique'));
        end
        
    else
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION)
        % Need to make sure configuration is unique
        %
        % If there is only 1 configuration with the given 
        % condition, it's unique.
        validConditions = {configurations.(trigfields{2})};
        conditionMatch = strmatch(lower(userSettings{2}), lower(validConditions));
        if length(conditionMatch)==1,
            configMatch = struct2cell(configurations(conditionMatch));
            triggerconfig(uddobj, configMatch{:});
        elseif isempty(conditionMatch)
            error(message('imaq:triggerconfig:notValid'));
        else
            error(message('imaq:triggerconfig:notUnique'));
        end
    end
catch exception
    throw(exception);
end

function [userSettingsOut] = localFixGigeForNonStandardFeatures(uddobj, userSettings)

hwinfo = imaqhwinfo(uddobj);
if ~strcmp(hwinfo.AdaptorName, 'gige') || ~strcmp(userSettings{1}, 'hardware')
    userSettingsOut = userSettings;
    return;
end

% is gige and is a hardware trigger setting
if strcmp(userSettings{2}, 'DeviceSpecific') && strcmp(userSettings{3}, 'DeviceSpecific')
    userSettingsOut = userSettings;
    return;
end

condition = userSettings{2}; % 'FallingEdge'
source = userSettings{3}; % 'Line1-AcquisitionStart'
hyphenIdx = strfind(source, '-');
if isempty(hyphenIdx)
    % not an old configuration, pass it on and let it error if need be
    userSettingsOut = userSettings;
    return;
end
hyphenIdx = hyphenIdx(end); % use last one
triggerSelector = source((hyphenIdx + 1): end); % 'AcquisitionStart'
triggerSource = source(1:(hyphenIdx - 1)); % 'Line1'
warning(message('imaq:triggerconfig:gige:obsoleteTriggerConfig'));
try
    set(uddobj.Source, [triggerSelector 'TriggerMode'], 'On');
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerMode', triggerSelector));
end

try
    set(uddobj.Source, [triggerSelector 'TriggerActivation'], condition);
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerActivation', triggerSelector, condition));
end

try
set(uddobj.Source, [triggerSelector 'TriggerSource'], triggerSource);
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerSource', triggerSelector, triggerSelector));
end

userSettingsOut{1} = userSettings{1};
userSettingsOut{2} = 'DeviceSpecific';
userSettingsOut{3} = 'DeviceSpecific';
