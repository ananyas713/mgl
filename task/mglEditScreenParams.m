% mglEditScreenParams.m
%
%        $Id:$ 
%      usage: mglEditScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: This function can be used in conjunction with initScreen in the 
%             task directory to set your monitor parameters. You will first get
%             a dialog box which allows you to set which computer/display you
%             want to edit settings for. Note that the settings work by matching
%             the computer name that you are running from and also a display name
%             the display name is an optional parameter and is for when you have
%             more than one display associated with a single computer. Choose 
%             which computer/display you want to edit by hitting the arrow keys
%             on computerNum and then hit ok to edit.
%
%             You will then get a second dialog box which allows you to set parameters
%             for that computer. Click on help for more info on what the parameter
%             settings do. Once you are satisfied, hit OK to save the settings
%             into the file ~/.mglScreenParams.mat. 
%
%             To use the parameters, just run:
%
%             initScreen;
%
%             If you have more than one display, then choose which display that
%             you want, by doing:
%
%             initScreen('displayName');
%            
%
function retval = mglEditScreenParams()

% check arguments
if ~any(nargin == [0])
  help mglEditScreenParams
  return
end

% check for mrParamsDialog
if ~mglIsMrToolsLoaded
  disp(sprintf('(mglEditScreenParams) You must have mrTools in your path to run the GUI for this function.'));
  return
end

% get the screenParams
screenParams = mglGetScreenParams;
if isempty(screenParams)
  disp(sprintf('(mglEditScreenParams) No saved screen params found, creating a new one'));
  disp(sprintf('(mglEditScreenParams) This new params will only be saved if you click ok to the next two dialog boxes.'));
  screenParams{1} = mglDefaultScreenParams;
end

% get the hostname
hostname = mglGetHostName;

% get the name of the valid computers
hostnameList = {};displayNames = {};computerNum = 1;
defaultDisplayName = mglGetParam('defaultDisplayName');defaultDisplay = {};
for i = 1:length(screenParams)
  hostnameList{end+1} = screenParams{i}.computerName;
  displayNames{end+1} = screenParams{i}.displayName;
  if isempty(displayNames{end}) displayNames{end} = ' ';,end
  % check if this is one that should be checked on as default
  if ~isempty(defaultDisplayName) && isstr(defaultDisplayName) && isstr(screenParams{i}.displayName) && strcmp(lower(defaultDisplayName),lower(screenParams{i}.displayName))
    defaultDisplay{i} = 1;
    computerNum = i;
  else
    defaultDisplay{i} = 0;
  end
end

% set up params for choosing which computer to edit
paramsInfo{1} = {'computerNum',computerNum,sprintf('minmax=[1 %i]', length(hostnameList)),'incdec=[-1 1]'};
paramsInfo{end+1} = {'computerName',hostnameList,'type=string','group=computerNum','editable=0'};
paramsInfo{end+1} = {'displayName',displayNames,'type=string','group=computerNum','editable=0'};
paramsInfo{end+1} = {'defaultDisplay',defaultDisplay,'type=checkbox','group=computerNum','If this is checked it means that this display is the one that will come up by default when initScreen is run with no arguments','callback',@changeDefaultDisplay};
paramsInfo{end+1} = {'addDisplay',0,'type=pushButton','buttonString=Add Display','callback',@addDisplay,'passParams=1','Add a new display to the list'};
paramsInfo{end+1} = {'deleteDisplay',0,'type=pushButton','buttonString=Delete Display','callback',@deleteDisplay,'passParams=1','Delete this display from the screenParams'};

% bring up dialog box
params = mrParamsDialog(paramsInfo,'Choose display to edit','fullWidth=1');
if isempty(params),return,end

% add this display if asked for
if isequal(params.addDisplay,true) || (params.computerNum > length(screenParams))
  % see if user wants to use default settings or copy an existing one
  % get display info
  initTypeStrings = {};
  for i = 1:length(screenParams)
    initTypeStrings{end+1} = sprintf('Copy: %s: %s (%i %ix%i %i Hz)',screenParams{i}.computerName,screenParams{i}.displayName,screenParams{i}.screenNumber,screenParams{i}.screenWidth,screenParams{i}.screenHeight,screenParams{i}.framesPerSecond);
  end
  initTypeStrings = putOnTopOfList('Use default',initTypeStrings);
  paramsInfo = {{'initParamsType',initTypeStrings,'Choose whether to use default screen params or copy screen params from an exisiting screenParams as your starting point for the new screen settings'}};
  initTypeParams = mrParamsDialog(paramsInfo,'Choose how to init new screen');
  % user aborted
  if isempty(initTypeParams),return,end
  % find which one the user selected
  initParamsType = find(strcmp(initTypeParams.initParamsType,initTypeStrings));
  % if user asked for default
  if initParamsType == 1
    screenParams{end+1} = mglDefaultScreenParams;
  else
    % otherwise copy
    screenParams{end+1} = screenParams{initParamsType-1};
    screenParams{end}.displayName = '';
  end
end

% delete computers list
if params.deleteDisplay
  for i = 1:length(params.computerName)
    screenParams{i}.computerName = params.computerName{i};
  end
end

% get parameters for chosen computer
computerNum = params.computerNum;
thisScreenParams = screenParams{computerNum};

% get some parameters for the screen
useCustomScreenSettings = 1;
screenNumber = thisScreenParams.screenNumber;
if isempty(screenNumber),screenNumber = 1;useCustomScreenSettings=0;end
screenWidth = thisScreenParams.screenWidth;
if isempty(screenWidth),screenWidth = 800;end
screenHeight = thisScreenParams.screenHeight;
if isempty(screenHeight),screenHeight = 600;end
framesPerSecond = thisScreenParams.framesPerSecond;
if isempty(framesPerSecond),framesPerSecond = 60;end

% see if the calibration options should be enabled or not.
if strcmp(thisScreenParams.calibType,'Specify particular calibration')
  enableCalibFilename = 'enable=1';
else
  enableCalibFilename = 'enable=0';
end
% see if the calibration options should be enabled or not.
if strcmp(thisScreenParams.calibType,'Specify gamma')
  enableMonitorGamma = 'enable=1';
else
  enableMonitorGamma = 'enable=0';
end

% get backtick char
backtickChar = paramsNum2str(thisScreenParams.backtickChar);

% get responseKeys
responseKeys = '';
for i = 1:length(thisScreenParams.responseKeys)
  responseKeys = sprintf('%s%s ',responseKeys,paramsNum2str(thisScreenParams.responseKeys{i}));
end
displayDir = mglGetParam('displayDir');
if isempty(displayDir)
  displayDir = fullfile(fileparts(fileparts(which('moncalib'))),'task','displays');
end

% add some default fields if the exist.
% NOTE: To add fields to the screenParams, we need to add the field
% here and under params2screenParams and in mglValidateScreenParams
validatedScreenParams = mglValidateScreenParams(thisScreenParams);
addFields = {'calibProportion','squarePixels','simulateVerticalBlank','shiftOrigin','crop','cropScreen','scale','scaleScreen'};
for i= 1:length(addFields)
  if ~isfield(thisScreenParams,addFields{i})
    thisScreenParams.(addFields{i}) = validatedScreenParams.(addFields{i});
  end
end

% test for bad array values
if ~thisScreenParams.crop && (length(thisScreenParams.cropScreen) < 2)
  thisScreenParams.cropScreen = [0 0];
end
if ~thisScreenParams.scale && (length(thisScreenParams.scaleScreen) < 2)
  thisScreenParams.scaleScreen = [1 1];
end

% eye tracker types
eyeTrackerTypes = {'None','Eyelink','Calibrate','ASL'};

% ignore initial vols setting
ignoreInitialVols = mglGetParam('ignoreInitialVols');
if isempty(ignoreInitialVols) ignoreInitialVols = 0;end

%set up the paramsInfo
paramsInfo = {};
% note that enable changes will control any of the settings below that has a field enable in it (but wont change
% anything that has something like enable=0 for instance. So if you want to be able to have this setting
% enable/disable, then you have to add 'enable,thisScreenParams.enableChanges to its settings
paramsInfo{end+1} = {'enableChanges',thisScreenParams.enableChanges,'type=checkbox','callback',@enableChanges,'passParams=1','Check to enable changes. If this is unclicked then no parameters will be changed when you hit OK'};
paramsInfo{end+1} = {'computerName',thisScreenParams.computerName,'The name of the computer for these screen parameters','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displayName',thisScreenParams.displayName,'The display name for these settings. This can be left blank if there is only one display on this computer for which you will be using mgl. If instead there are multiple displays, then you will need screen parameters for each display, and you should name them appropriately. You then call initScreen(displayName) to get the settings for the correct display','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'useCustomScreenSettings',useCustomScreenSettings,'type=checkbox','If you leave this unchecked then mgl will open up with default screen settings (i.e. the display will be chosen as the last display in the list and the screenWidth and ScreenHeight will be whatever the current settings are). This is sometimes useful for when you are on a development computer -- rather than the one you are running experiments on','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'screenNumber',screenNumber,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','The screen number to use on this display. 0 is for a windowed contex. Transparent windowed context can be made when this is set to <1.','round=0','contingent=useCustomScreenSettings','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'screenWidth',screenWidth,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','The width in pixels of the screen','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'screenHeight',screenHeight,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','The height in pixels of the screen','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'framesPerSecond',framesPerSecond,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','Refresh rate of monitor','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displayDistance',thisScreenParams.displayDistance,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','Distance in cm to the display from the eyes. This is used for figuring out how many pixels correspond to a degree of visual angle','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displaySize',thisScreenParams.displaySize,'type=array','minmax=[0 inf]','Width and height of display in cm. This is used for figuring out how many pixels correspond to a degree of visual angle','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'calibProportion',thisScreenParams.calibProportion,'type=numeric','minmax=[0.0000001 1]','incdec=[-0.01 0.01]','Calibration proportion should be a value between 0 and 1 (usually set to 0.36). This number controls what proportion of the screen width and height is used to compute pix2deg scale factors. This is important because only at this screen position will visual angles be *exactly* correct. This is because using a linear scale factor to convert from screen positions to visual angles makes the incorrect assumption that the screen is spherical curved around the persons eye. While this is convenient, it is wrong and so some screen positions will have a slight error in the actual visual angle. This is rather small and usually not very important, but you may want to set this to some other percentage if you want to have a different screen location be exactly correct. Press display calib discrepancy to see what your actual discrepancy is.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'squarePixels',thisScreenParams.squarePixels,'type=checkbox','Calibrate x and y pixels to degree scale factors forcing these to be the same for both dimensions (i.e. forcing square voxels). This is useful if you want the number of pixels in any dimension to be forced to equally the same visual angle. See display calib discrepancy to see how much of a discrepancy this introduces in any position on the monitor','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'dispCalibDiscrepancy',0,'type=pushbutton','buttonString=display calib discrepancy','callback',@dispCalibDiscrepancy,'passParams=1','Click to see the calibration position discrepancy'};
paramsInfo{end+1} = {'shiftOrigin',thisScreenParams.shiftOrigin,'type=array','minmax=[0 inf]','Set this to shift the origin (in degrees). For example, if you want to shift the whole display up by 3 degrees then you should set this to [0 3]','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'crop',thisScreenParams.crop,'type=checkbox','Turns on or off cropping, see setting for cropScreen for more details','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'cropScreen',thisScreenParams.cropScreen,'type=array','contingent=crop','minmax=[0 inf]','Crop the screen - this simply will set imageWidth/imageHeight to the values set here. This is useful if your code bases the stimulus on the imageWidth/imageHeight (like mglRetinotopy) and you want to quickly set it to only display on a protion of the screen','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'scale',thisScreenParams.scale,'type=checkbox','Turns on or off scaling, see setting for scaleScreen for more details','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'scaleScreen',thisScreenParams.scaleScreen,'type=array','contingent=scale','minmax=[0 inf]','Scales the screen - This is useful if you want to shrink (or enlarge) the stimulus display of a program w/out changing that program - for example if a subject can only see a portion of the screen. For example, if you want to shrink by 1/2 in x and 1/4 in you would set this to [0.5 0.25]. Then drawing a stimulus at, say, [4 12] will actually display at [2 3] and a stimulus of size, say [3 8] will come out as [1.5 2].','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displayPos',thisScreenParams.displayPos,'type=array','minmax=[0 inf]','This is only relevant if you are using a windowed context (e.g. screenNumber=0). It will set the position of the display in pixels where 0,0 is the bottom left corner of your display.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'autoCloseScreen',thisScreenParams.autoCloseScreen,'type=checkbox','Check if you want endScreen to automatically do mglClose at the end of your experiment.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'flipHorizontal',thisScreenParams.flipHV(1),'type=checkbox','Click if you want initScreen to set the coordinates so that the screen is horizontally flipped. This may be useful if you are viewing the screen through mirrors','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'flipVertical',thisScreenParams.flipHV(2),'type=checkbox','Click if you want initScreen to set the coordinates so that the screen is vertically flipped. This may be useful if you are viewing the screen through mirrors','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'hideCursor',thisScreenParams.hideCursor,'type=checkbox','Click if you want initScreen to hide the mouse for this display.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'transparentBackground',thisScreenParams.transparentBackground,'type=checkbox','Click if you want a transparent background. This is useful if you want to display mgl over some other display.'};
paramsInfo{end+1} = {'backtickChar',backtickChar,'type=string','Set the keyboard character that is used a synch pulse from the scanner. At NYU this is the backtick character. If you use a different character enter it here. If you enter a number then this will be interpreted as a character code (see mglCharToKeycode).','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'responseKeys',responseKeys,'type=string','Sets which keys you want to use for response keys. This should be a space delimited string, for example: 1 2 3 4 5 6 7 8 9 -> is the default, which uses the number keys. If you want to use keycodes, for example to use the numberic key pay, you can do: k84 k85 k86 k87 k88 k89 k90 k92 k93. Note that if that the responses recorded will be integers associated with the order in the list you provides - so: 1 2 8 9 will give response 1 2 3 4. You can also use letter keys: a b for example, will return 1 and 2 for the letters a and b, respectively.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'eatKeys',thisScreenParams.eatKeys,'type=checkbox','Sets whether to eat keys. That is, any key that initScreen uses, for example the response keys and the backtickChar will not be sent to the terminal. See the function mglEatKeys for more details.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'saveData',thisScreenParams.saveData,'type=numeric','incdec=[-1 1]','minmax=[-1 inf]','Sets whether you want to save an stim file which stores all the parameters of your experiment. You will probably want to save this file for real experiments, but not when you are just testing your program. So on the desktop computer set it to 0. This can be 1 to always save a data file, 0 not to save data file,n>1 saves a data file only if greater than n number of volumes have been collected). If set to -1, it will ask you whether you want to save.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'calibType',putOnTopOfList(thisScreenParams.calibType,{'None','Find latest calibration','Specify particular calibration','Gamma 1.8','Gamma 2.2','Specify gamma'}),'Choose how you want to calibrate the monitor. This is for gamma correction of the monitor. Find latest calibration works with calibration files stored by moncalib, and will look for the latest calibration file in the directory task/displays that matches this computer and display name. If you want to specify a particular file then select that option and specify the calibration file in the field below. If you don''t have a calibration file created by moncalib then you might try to correct for a standard gamma value like 1.8 (mac computers) or 2.2 (PC computers). Or a gamma value of your choosing','callback',@calibTypeCallback,'passParams=1','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'calibFilename',thisScreenParams.calibFilename,'Specify the calibration filename. This field is only used if you use Specify particular calibration from above',enableCalibFilename,'enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displayDir',displayDir,'The name of the directory where your calibration files from moncalib are stored. Default is mgl/task directory','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'displayCalib',0,'type=pushbutton','buttonString=Display monitor calibration','callback',@displayCalib,'passParams=1','Click to display the monitor calibration done by moncalib'};
paramsInfo{end+1} = {'monitorGamma',thisScreenParams.monitorGamma,'type=numeric','Specify the monitor gamma. This is only used if you set Specify Gamma above',enableMonitorGamma,'enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'eyeTrackerType',putOnTopOfList(thisScreenParams.eyeTrackerType,eyeTrackerTypes),'Choose which eye tracker to use. Note that if you are using EyeLink and want to set parameters for that eye tracker, you can call the function mglEyelinkParams','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginUse',thisScreenParams.digin.use,'type=checkbox','Click this if you want to use the National Instruments cards digital io for detecting volume acquisitions and subject responses. If you use this, the keyboard will still work (i.e. you can still press backtick and response numbers. This uses the function mglDigIO -- and you will need to make sure that you have compiled mgl/util/mglPrivateDigIO.c','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginPortNum',thisScreenParams.digin.portNum,'type=numeric','This is the port that should be used for reading. For NI USB-6501 devices it can be one of 0, 1 or 2','incdec=[-1 1]','minmax=[0 inf]','contingent=diginUse','round=1','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginAcqLine',thisScreenParams.digin.acqLine,'type=numeric','This is the line from which to read the acquisition pulse (i.e. the one that occurs every volume','incdec=[-1 1]','minmax=[0 7]','contingent=diginUse','round=1','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginAcqType',num2str(thisScreenParams.digin.acqType),'type=string','This is how to interpert the digial signals for the acquisition. If you want to trigger when the signal goes low then set this to 0. If you want trigger when the signal goes high, set this to 1. If you want to trigger when the signal changes state (i.e. either low or high), set to [0 1]','contingent=diginUse','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginResponseLine',num2str(thisScreenParams.digin.responseLine),'type=string','This is the lines from which to read the subject responses. If you want to specify line 1 and line 3 for subject response 1 and 2, you would enter [1 3], for instance. You can have up to 7 different lines for subject responses.','minmax=[0 7]','contingent=diginUse','round=1','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'diginResponseType',num2str(thisScreenParams.digin.responseType),'type=string','This is how to interpert the digial signals for the responses. If you want to trigger when the signal goes low then set this to 0. If you want trigger when the signal goes high, set this to 1. If you want to trigger when the signal changes state (i.e. either low or high), set to [0 1]','contingent=diginUse','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'simulateVerticalBlank',thisScreenParams.simulateVerticalBlank,'type=checkbox','Click this if you want to simulate a vertical blank waiting period. Normally mglFlush waits till the vertical blank and so you will only refresh once every video frame. But with some video cards, notably ATI Radeon HD 5xxx series, this is broken. So by clicking this you can use the mglFlushAndWait rather than the mglFlush function which will just use mglWaitSecs to wait the appropriate amount of time after an mglFlush','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'testSettings',0,'type=pushbutton','buttonString=Test screen params','callback',@testSettings,'passParams=1','Click to test the monitor settings. This can be run as a standalone function: mglTestScreenParams'};
paramsInfo{end+1} = {'useScreenMask',thisScreenParams.useScreenMask,'type=checkbox','Turn on or off using a screen mask. A screen mask is s a stencil used to block out portions of the display. This is typically used because you are projecting on to a screen (like in an MRI system) in which the screen is not quite rectangular, and you dont want to project stray light outside the screen. So you create a function (set as screenMaskFunction) which puts white where you want to display and black where you do not. Then initScreen will make this a stencil, and mglClearScreen will set the stencil to be active forcing all drawing to not draw into the area where you want to stencil out','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'screenMaskFunction',thisScreenParams.screenMaskFunction,'Function that draws a screen mask - white where you want to draw, black elsewhere. This function should take one input value, myscreen, and not return anything - see help under useScreenMask for more info','contingent=useScreenMask','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'screenMaskStencilNum',thisScreenParams.screenMaskStencilNum,'type=numeric','minmax',[1 inf],'incdec',[-1 1],'contingent=useScreenMask','Sets which stencil to use for the screen mask - see useScreenMask for more info','enable',thisScreenParams.enableChanges};
if ~isfield(thisScreenParams,'screenMaskStencilNum')
  thisScreenParams.screenMaskFunction = 7;
end
paramsInfo{end+1} = {'setVolume',thisScreenParams.setVolume,'type=checkbox','Set volume to volumeLevel on initScreen','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'volumeLevel',thisScreenParams.volumeLevel,'type=numeric','minmax=[0 1]','incdec=[-0.1 0.1]','Set volume to specified level - only if setVolume is set','contingent=setVolume','enable',thisScreenParams.enableChanges};
% get info about subjectID
mustSetSID = mglGetParam('mustSetSID');
if isempty(mustSetSID),mustSetSID=false;end
sidDatabaseFilename = mglGetParam('sidDatabaseFilename');
if isempty(sidDatabaseFilename),sidDatabaseFilename='';end
sidRaceEthnicity = mglGetParam('sidRaceEthnicity');
if isempty(sidRaceEthnicity),sidRaceEthnicity=true;end
sidValidIntervalInHours = mglGetParam('sidValidIntervalInHours');
if isempty(sidValidIntervalInHours),sidValidIntervalInHours=1;end

% set subject ID info
paramsInfo{end+1} = {'mustSetSID',mustSetSID,'type=checkbox','This will set it so that you **have** to set a subject ID before running the experiment. This will keep a log of the subjectID in the stim file. See mglSetSID.','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'sidDatabaseFilename',sidDatabaseFilename,'contingent=mustSetSID','This sets where the sid database is stored','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'sidRaceEthnicity',sidRaceEthnicity,'type=checkbox','contingent=mustSetSID','Sets whether to collect race/ethnicity information from subjects for NIH reporting','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'sidValidIntervalInHours',sidValidIntervalInHours,'incdec=[-0.5 0.5]','minmax=[0 inf]','contingent=mustSetSID','Sets how long the subjectID that you set is valid for in hours. i.e. if you set it for 1 then it will keep valid any subjetID for 1 hour after that the subject ID will revert to not being set. This is so that when you set it on the experimental computer that when someone comes to use the computer a few hours later they have to reset the subject id','enable',thisScreenParams.enableChanges};

% get info about task log
writeTaskLog = mglGetParam('writeTaskLog');
if isempty(writeTaskLog),writeTaskLog = false;end
logpath = mglGetParam('logpath');
if isempty(logpath),logpath = '~/data/log';end
paramsInfo{end+1} = {'writeTaskLog',writeTaskLog,'type=checkbox','Set to write a task log. This will save a log of each experiment run in the location specified by logpath. The log can be viewed using mglTaskLog','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'logpath',logpath,'contingent=writeTaskLog','Location of task log for mglTaskLog','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'ignoreInitialVols',ignoreInitialVols,'minmax=[0 inf]','incdec=[-1 1]','Set this if you need to ignore some initial volume acquisition pulses from the magnet. The number that you set is the number that will get ignored','enable',thisScreenParams.enableChanges};
paramsInfo{end+1} = {'waitForPrescan',thisScreenParams.waitForPrescan,'type=checkbox','Set this if you need to ignore prescan triggers. When you set waitForBacktick it will not trigger the start until you manually hit ENTER','enable',thisScreenParams.enableChanges};

% display parameter choosing dialog
if ~isequal(thisScreenParams.computerName,'DELETE')
  params = mrParamsDialog(paramsInfo,'Set screen parameters');
  if isempty(params),return,end
  % if enableChanges is set to off, then only keep that parameter
  if ~params.enableChanges 
    screenParams{computerNum}.enableChanges = false;
    disp(sprintf('(mglEditScreenParams) Enable changes set to false. Not updating any changes to screen'));
  else
    screenParams{computerNum} = params2screenParams(params);
    % set the mglSetSID and mglTaskLog settings
    setSIDSettingsFromParams(params);
    setDisplayDir(params.displayDir);
    % set the ignoreInitialVols setting
    mglSetParam('ignoreInitialVols',params.ignoreInitialVols,1);
  end
end

% delete screen params
deleteScreenParams = screenParams;
screenParams = {};
for i = 1:length(deleteScreenParams)
  if ~isequal(deleteScreenParams{i}.computerName,'DELETE');
    screenParams{end+1} = deleteScreenParams{i};
  end
end

% save
mglSetScreenParams(screenParams);

%%%%%%%%%%%%%%%%%%%%%%%
%    enableChanges    %
%%%%%%%%%%%%%%%%%%%%%%%
function val = enableChanges(params)


% set enable
for iParam = 1:length(params.paramInfo)
  % see if the param is one that should be enabled/disabled, by
  % checking in paramInfo for an enable field
  changeEnable = false;
  for jField = 2:length(params.paramInfo{iParam})
    if isequal(params.paramInfo{iParam}{jField},'enable')
      changeEnable = true;
    end
  end
  % now enable / disable it if it should be
  if changeEnable
    mrParamsEnable(params.paramInfo{iParam}{1},params.enableChanges);
  end
end

% return the setting
val = params.enableChanges;

%%%%%%%%%%%%%%%%%%%%%%%%%
%%   testOpenDisplay   %%
%%%%%%%%%%%%%%%%%%%%%%%%%
function msc = testOpenDisplay(params)

if ~params.enableChanges 
  params = mrParamsGet('getUnenabled=1');
end

msc = [];
disp(sprintf('(mglEditScreenParams:testSettings) Testing settings for %s:%s',params.computerName,params.displayName));

setDisplayDir(params.displayDir);

% test to see if the screenNumber is valid
if params.screenNumber > length(mglDescribeDisplays)
  msgbox(sprintf('(mglEditScreenParams) Screen number %i is out of range for %s: [0 %i]',params.screenNumber,params.computerName,length(mglDescribeDisplays)));
  return
end

% check if the screen number is 0 since for that we can't change the dimensions
if params.screenNumber == 0
  global mglEditScreenParamsScreenWidth;
  global mglEditScreenParamsScreenHeight;
  if ~isempty(mglEditScreenParamsScreenWidth) || ~isempty(mglEditScreenParamsScreenHeight) 
    if (~isequal(mglEditScreenParamsScreenWidth,params.screenWidth) || ~isequal(mglEditScreenParamsScreenHeight,params.screenHeight))
      % Warning for windowed contexts (if we set mglPrivateClose.c to close the context, we don't need this) - but 
      % need to check the stability of that.
      %      msgbox(sprintf('(mglEditScreenParams) For windowed contexts, you cannot change the width/height of the window after you have opened it once, so this screen will not accurately reflect the current parameters. So, rather than [%i %i], this window will display as [%i %i]. To try the new parameters, you will need to restart matlab. ',params.screenWidth,params.screenHeight,mglEditScreenParamsScreenWidth,mglEditScreenParamsScreenWidth));
    end
  else
    mglEditScreenParamsScreenWidth = params.screenWidth;
    mglEditScreenParamsScreenHeight = params.screenHeight;
  end
end

% convert the params returned by the dialog into
% screen params
msc.screenParams{1} = params2screenParams(params);
msc.computer = params.computerName;
msc.displayName = params.displayName;
msc.allowpause = 0;

% trun off movie mode for screen test
movieMode = mglGetParam('movieMode');
mglSetParam('movieMode',0);

% now call initScreen with these parameters
% setting SID to test
sid = mglGetSID;
mglSetSID('test');
msc = initScreen(msc);
mglSetSID(sid);

% reset movie mode
mglSetParam('movieMode',movieMode);

%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = dispCalibDiscrepancy(params)

val = 0;

mglClose;
msc = testOpenDisplay(params);
if isempty(msc),return,end
mglDispVisualAngleDiscrepancy;
mglClose;


%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = testSettings(params)

val = 0;

% close any open screen
mglClose;

% open the display with the params
msc = testOpenDisplay(params);

% and test it.
mglTestScreenParams(msc);

%%%%%%%%%%%%%%%%%%%
%%   testDigin   %%
%%%%%%%%%%%%%%%%%%%
function retval = testDigin(params)

retval = 0;

% how long to wait for
waitTime = 60;

% open screen for textVersion
screenParams = params2screenParams(params);
if ~screenParams.digin.use
  disp(sprintf('(mglEditScreenParams:testDigin) Digin is not being used'));
  return
end

% get start time
startTime = mglGetSecs;

% start digin (set digout port to just be whatever digin is not)
if mglDigIO('init',screenParams.digin.portNum,mod(screenParams.digin.portNum+1,3)) == 0
  disp(sprintf('(mglEditScreenParams:testDigin) Failed to initialize digital IO port'));
  return
end

disp(sprintf('(mglEditScreenParams:testDigin) Testing settings for %s:%s',params.computerName,params.displayName));
disp(sprintf('(mglEditScreenParams:testDigin) PortNum: %i acqLine: %i acqType: %s responseLine: %s responseType: %s',screenParams.digin.portNum,screenParams.digin.acqLine,num2str(screenParams.digin.acqType),num2str(screenParams.digin.responseLine),num2str(screenParams.digin.responseType)));
disp(sprintf('(mglEditScreenParams:testDigin) To quit hit ESC'));

% init keyboard listener and clear events
mglListener('init');
  
% get any pending events
[keyCode when charCode] = mglGetKeyEvent(0,1);

volNum = 0;volTime = startTime;nums = [];times = [];
while ((mglGetSecs-startTime) < waitTime)
  [keyCode when charCode] = mglGetKeyEvent(0,1);
  if ~isempty(charCode)
    % check for return or space or ESC
    if any(keyCode == 37) || any(charCode == ' ') || any(keyCode == 54)
      retval = 1;
      disp(sprintf('(mglEditScreenParams:testDigin) End digin test'));
      mglDigIO('quit');
      mglListener('quit');
      return
    end
  end
  % get status of digital ports
  digin = mglDigIO('digin');
  if ~isempty(digin)
    % see if there is an acq pulse
    acqPulse = find(screenParams.digin.acqLine == digin.line);
    if ~isempty(acqPulse)
      acqPulse = find(ismember(digin.type(acqPulse),screenParams.digin.acqType));
      if ~isempty(acqPulse)
	volTime = digin.when(acqPulse(1));
	volNum = volNum+1;
	disp(sprintf('Volume number: %i Time of last volume: %0.3f',volNum,volTime-startTime));
      end
    end
    % see if one of the response lines has been set 
    [responsePulse whichResponse] = ismember(digin.line,screenParams.digin.responseLine);
    responsePulse = ismember(digin.type(responsePulse),screenParams.digin.responseType);
    nums =  whichResponse(responsePulse);
    times = digin.when(responsePulse);
    if ~isempty(nums)
      disp(sprintf('Response: %s (time: %s)',num2str(nums),num2str(times-startTime)));
    end
  end
end

retval = 1;
disp(sprintf('(mglEditScreenParams:testDigin) End digin test'));
mglDigIO('quit');
mglListener('quit');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   params2screenParams   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function screenParams = params2screenParams(params)

% get host/display name
screenParams.computerName = params.computerName;
screenParams.displayName = params.displayName;

% get screen settings
if params.useCustomScreenSettings
  screenParams.screenNumber = params.screenNumber;
  screenParams.screenWidth = params.screenWidth;
  screenParams.screenHeight = params.screenHeight;
  screenParams.framesPerSecond = params.framesPerSecond;
else
  screenParams.screenNumber = [];
  screenParams.screenWidth = [];
  screenParams.screenHeight = [];
  screenParams.framesPerSecond = 60;
end

% get display settings
screenParams.displayDistance = params.displayDistance;
screenParams.displaySize = params.displaySize;
screenParams.displayPos = params.displayPos;
screenParams.flipHV = [params.flipHorizontal params.flipVertical];
screenParams.autoCloseScreen = params.autoCloseScreen;
screenParams.hideCursor = params.hideCursor;
screenParams.calibProportion = params.calibProportion;
screenParams.squarePixels = params.squarePixels;
screenParams.shiftOrigin = params.shiftOrigin;
screenParams.scale = params.scale;
screenParams.scaleScreen = params.scaleScreen;
screenParams.crop = params.crop;
screenParams.cropScreen = params.cropScreen;
screenParams.transparentBackground = params.transparentBackground;

% get file saving settings
screenParams.saveData = params.saveData;

% calibration info
screenParams.calibType = params.calibType;
screenParams.calibFilename = params.calibFilename;
screenParams.monitorGamma = params.monitorGamma;

% keyboard parameters
screenParams.eatKeys = params.eatKeys;
screenParams.backtickChar = paramsStr2num(params.backtickChar);
responseKeys = regexp(strtrim(params.responseKeys),'\s+','split');
for i = 1:length(responseKeys)
  screenParams.responseKeys{i} = paramsStr2num(responseKeys{i});
end

% digio
screenParams.digin.use = params.diginUse;
screenParams.digin.portNum = params.diginPortNum;
screenParams.digin.acqLine = params.diginAcqLine;
if ~isempty(params.diginAcqType)
  screenParams.digin.acqType = str2num(params.diginAcqType);
else
  screenParams.digin.acqType = [];
end
if ~isempty(params.diginResponseLine) 
  screenParams.digin.responseLine = str2num(params.diginResponseLine);
else
  screenParams.digin.responseLine = [];
end
if ~isempty(params.diginResponseType)
  screenParams.digin.responseType = str2num(params.diginResponseType);
else
  screenParams.digin.responseType = [];
end  

% eye tracker type
screenParams.eyeTrackerType = params.eyeTrackerType;

% simulate vertical blank
screenParams.simulateVerticalBlank = params.simulateVerticalBlank;

% screenMask
screenParams.useScreenMask = params.useScreenMask;
if params.useScreenMask
  screenParams.screenMaskFunction = params.screenMaskFunction;
  screenParams.screenMaskStencilNum = params.screenMaskStencilNum;
else
  % default back to orignal
  for i = 1:length(params.paramInfo)
    if strcmp(params.paramInfo{i}{1},'screenMaskFunction')
      screenParams.screenMaskFunction = params.paramInfo{i}{2};
    end
    if strcmp(params.paramInfo{i}{1},'screenMaskStencilNum')
      screenParams.screenMaskStencilNum = params.paramInfo{i}{2};
    end
  end
end


% set volume
screenParams.setVolume = params.setVolume;
if params.setVolume
  screenParams.volumeLevel = params.volumeLevel;
end

screenParams.waitForPrescan = params.waitForPrescan;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    setSIDSettingsFromParams    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setSIDSettingsFromParams(params)

% set the sid paramteres
if isfield(params,'mustSetSID')
  mglSetParam('mustSetSID',params.mustSetSID,2);
  if params.mustSetSID
    mglSetParam('sidDatabaseFilename',params.sidDatabaseFilename,2);
    mglSetParam('sidRaceEthnicity',params.sidRaceEthnicity,2);
    mglSetParam('sidValidIntervalInHours',params.sidValidIntervalInHours,2);
  end
end
if isfield(params,'writeTaskLog')
  mglSetParam('writeTaskLog',params.writeTaskLog,2);
  if params.writeTaskLog
    mglSetParam('logpath',params.logpath,2);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   calibTypeCallback   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calibTypeCallback(params)

% this is used to gray out the calibFilename and monitorGamma settins depending
% on what option the user selects for calibType
if strcmp(params.calibType,'Specify particular calibration')
  mrParamsEnable('calibFilename',1);
else
  mrParamsEnable('calibFilename',0);
end
if strcmp(params.calibType,'Specify gamma')
  mrParamsEnable('monitorGamma',1);
else
  mrParamsEnable('monitorGamma',0);
end

%%%%%%%%%%%%%%%%%%%%
%%   addDisplay   %%
%%%%%%%%%%%%%%%%%%%%
function retval = addDisplay(params)

retval = 'add';
if ~isequal(params.addDisplay,'add')
  params.computerName = {params.computerName{:},mglGetHostName};
  params.displayName = {params.displayName{:},''};
  params.defaultDisplay(end+1) = 0;
  params.computerNum = length(params.computerName);
  params.addDisplay = true;
  mrParamsSet(params);
end
mrParamsClose(true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   changeDefaultDisplay  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = changeDefaultDisplay(params)

retval = false;
mrParamsClose;
% save for all users the setting
mglSetParam('defaultDisplayName',params.displayName{params.computerNum},2);

%%%%%%%%%%%%%%%%%%%%%%%
%%   deleteDisplay   %%
%%%%%%%%%%%%%%%%%%%%%%%
function retval = deleteDisplay(params)

retval = true;
% make sure the user wants to do this
if strcmp('Yes',questdlg(sprintf('Are you sure you want to delete the display %s:%s?',params.computerName{params.computerNum},params.displayName{params.computerNum}),'Delete Display','Yes','No','No'))
  params.computerName{params.computerNum} = 'DELETE';
  params.displayName{params.computerNum} = 'DELETE';
  params.deleteDisplay = true;
  mrParamsSet(params);
  mrParamsClose(true);
end

%%%%%%%%%%%%%%%%%%%%%%%%
%%   params2Str2num   %%
%%%%%%%%%%%%%%%%%%%%%%%%
function c = paramsStr2num(c)

if regexp(c,'^k\d+$')
  c = str2num(c(2:end));
elseif length(c) > 1
  disp(sprintf('(mglEditScreenParams) Unrecogonized format for character %s (should be either a single character or kdd (e.g. k40) for a key code)',c));
end

%%%%%%%%%%%%%%%%%%%%%%%
%%   paramsNum2str   %%
%%%%%%%%%%%%%%%%%%%%%%%
function c = paramsNum2str(c)

if isnumeric(c)
  c = sprintf('k%i',c);
end

%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = displayCalib(params)

val = 0;

mglClose;
msc = testOpenDisplay(params);
if isempty(msc),return,end
mglClose;

if ~isfield(msc,'calibFullFilename') 
  disp(sprintf('(mglEditScreenParams) Calibration not found or not set in calibType above'));
  return
else
  c = load(msc.calibFullFilename);
  if ~isfield(c,'calib')
    disp(sprintf('(mglEditScreenParams) Calib file %s does not contain the calib variable. Was it created by moncalib?',msc.calibFullFilename));
    return
  else
    moncalib(c.calib);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%
%    setDisplayDir    %
%%%%%%%%%%%%%%%%%%%%%%%
function setDisplayDir(displayDir)

% set the display dir (where the calibrations should live
if isdir(displayDir)
  mglSetParam('displayDir',displayDir,1);
else
  if askuser(sprintf('(mglEditScreenParams) Display dir %s does not exist. Ok to create',displayDir))
    mkdir(displayDir);
    mglSetParam('displayDir',displayDir,1);
  end
end
  
