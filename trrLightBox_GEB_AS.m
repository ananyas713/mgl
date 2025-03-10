% trrLightbox_new.m
%      usage: trrLightBox_new()
%         by: eli & charlie & min & ananya
%       date: 10/24/2023
%    purpose:
%
% trrLightBox_new('threshStair1=0', 'threshStair2=5', 'lightBox=1', 'calibrate=0');
% trrLightBox_new('threshStair1=0', 'threshStair2=5', 'lightBox=3', 'calibrate=0');
% trrLightBox_new('threshStair1=0', 'threshStair2=5', 'lightBox=4', 'calibrate=0');
% trrLightBox_new('threshStair1=0', 'threshStair2=5', 'lightBox=8', 'calibrate=0');
%
% calibration:
% trrLightBox_New('calibrate=1');
%
% practice run:
% trrLightBox_new('threshStair1=30', 'threshStair2=30', 'lightBox=9', 'calibrate=0',
% 'numTrials=20', 'stimDisp=4');
%
% training run:
% trrLightBox_new('threshStair1=20', 'threshStair2=20', 'lightBox=9', 'calibrate=0',
% 'numTrials=60');


function [] = trrLightbox(varargin)

% check arguments
if ~any(nargin == [0:10])                                                                                                                                                                                                                                                           am
    help trrLightbox
    return
end

getArgs(varargin,[],'verbose=1');

if ieNotDefined('initStair'), initStair = 0; end
if ieNotDefined('lightBox'), lightBox = 3; end
if ieNotDefined('threshStair1'), threshStair1 = 0; end
if ieNotDefined('threshStair2'), threshStair2 = 5; end
if ieNotDefined('stepsize'), stepsize = 1; end
if ieNotDefined('contrast'), contrast = 1; end
%if ieNotDefined('easyTilt'), easyTilt = 20; end
%if ieNotDefined('easyhard'), easyhard = 'hard'; end
if ieNotDefined('displayName'), displayName = '5sw'; end
if ieNotDefined('synchToVol'), synchToVol = 0; end
if ieNotDefined('useStair'), useStair = 1; end
if ieNotDefined('calibrate'), calibrate = 0; end
if ieNotDefined('vertOffset'), vertOffset = 6; end
if ieNotDefined('numTrials'), numTrials = 60; end
if ieNotDefined('stimDisp'), stimDisp = 0.2; end
if ieNotDefined('doPause'), doPause = 1; end
if ieNotDefined('pauseDuration'), pauseDuration = 15; end
if ieNotDefined('lightboxOff'), lightboxOff = 0; end
%if ieNotDefined('useEyeTracker'), useEyeTracker = 1; end
%if ieNotDefined('useLightbox'), useLightbox = 1; end


% init screen and open up the window
myscreen.background = [127 127 127];
myscreen.autoCloseScreen = 0;
myscreen.saveData = 1;
myscreen.displayName = displayName;
myscreen = initScreen(myscreen);

mglMetalFullscreen;

% init the task
task{1}.waitForBacktick = 1;
task{1}.numTrials = numTrials;

task{1}.segmin = [stimDisp 4];
task{1}.segmax = [stimDisp 4];
task{1}.synchToVol = [0 synchToVol];

task{1}.getResponse = [0 1];
task{1}.random = 1;

% Stim2 is the RIGHT stimulus
task{1}.randVars.uniform.tiltStim = [-1 1];

mglFixationCross(0.7, 2, [1 1 1], [0 0]) % green fixation is cue

for phaseNum = 1:length(task)
    [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);
end

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);
stimulus.contrast = contrast;
stimulus.trialCounter = 0;
stimulus.trialCorrectness = [];
stimulus.trialResponse = [];
stimulus.trialRT = [];
stimulus.useStair = useStair;
stimulus.vertOffset = vertOffset;
stimulus = myInitStimulus(stimulus,myscreen,task);

% init a 2 down 1 up staircase
if initStair == 1 | ieNotDefined('stimulus.stair{1}.threshold') | ieNotDefined('stimulus.stair{2}.threshold')
    disp(sprintf('\nATTENTION: Initalizing new staircase: threshold1 = %0.2f, threshold2 = %0.2f\n', threshStair1, threshStair2));
    stimulus.stair{1} = upDownStaircase(1,2,threshStair1,stepsize,1);
    stimulus.stair{1}.minThreshold = 0;
    stimulus.stair{2} = upDownStaircase(1,2,threshStair2,stepsize,1);
    stimulus.stair{2}.minThreshold = 0;
else
    disp(sprintf('\nATTENTION: Continuing old staircase: threshold1 = %0.2f, threshold2 = %0.2f\n', stimulus.stair{1}.threshold, stimulus.stair{2}.threshold));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % run the eye calibration
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if calibrate == 1
    myscreen = eyeCalibDisp(myscreen);
    %mglWaitSecs(1);
    mglEyelinkRecordingStop();
    mglClearScreen;mglFlush;
    mglClearScreen;mglFlush;
    %mglClose();
    myscreen.fliptime = inf;
    % turn lightbox off
    setLightboxSpectrum(9)
    return
else
    myscreen = eyeCalibDisp(myscreen);
end

% myscreen = eyeCalibDisp(myscreen);


%initial screen
mglClearScreen;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main display loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% draw fixation cross
mglFixationCross(0.7, 2, [255 0 0], [0 0+vertOffset])
mglFlush;

if doPause
    mglWaitSecs(pauseDuration);
end

% set the lightbox appropriatly
setLightboxSpectrum(lightBox)

phaseNum = 1;
while (phaseNum <= length(task)) && ~myscreen.userHitEsc
%     if (mod(stimulus.trialCounter,60)==0) && (stimulus.trialCounter < numTrials) && (stimulus.trialCounter > 0)
%         mglWaitSecs(20);
%     end
    % update the task
    [task myscreen phaseNum] = updateTask(task,myscreen,phaseNum);
    % flip screen
    myscreen = tickScreen(myscreen,task);
    % rest
    %disp(stimulus.trialCounter);
end

% print out command for next run
stimulus.percentCorrect = nansum(stimulus.trialCorrectness)/length(stimulus.trialCorrectness); disp('Percent Correct:'); disp(stimulus.percentCorrect*100);
stimulus.avgRT = nanmean(stimulus.trialRT); disp('Average RT:'); disp(stimulus.avgRT)

mglClearScreen;
mglTextSet('Helvetica',50,[0 0.5 1 1],0,0,0,0,0,0,0);
text = sprintf('You got %0.2f%% correct', stimulus.percentCorrect*100);
mglTextDraw(text,[0 0]);
mglFlush;
mglWaitSecs(1);

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

if lightboxOff
    setLightboxSpectrum(9)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)
global stimulus;

if task.thistrial.thisseg == stimulus.stimulusSegments
    stimulus.trialCounter = stimulus.trialCounter + 1;
end

% is this a segment in which a stimulus will be displayed
if any(task.thistrial.thisseg == stimulus.stimulusSegments)
    % pick a random stimulus phase
    stimulus.thisPhase = randperm(length(stimulus.phases));
    % which staircase will be updated
    stimulus.whichStair = round(rand)+1;
    % this is for a hard block
    task.thistrial.thisOrientationStim = stimulus.orientation + stimulus.stair{stimulus.whichStair}.threshold * task.thistrial.tiltStim;
end
stimulus.fixColor = [255 255 255];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)

global stimulus;
% clear the screen
mglClearScreen;

if any(task.thistrial.thisseg == 2)
    mglFixationCross(0.7, 2, stimulus.fixColor, [0 0+stimulus.vertOffset]) % green fixation is cue
end

if any(task.thistrial.thisseg == stimulus.stimulusSegments)
    mglBltTexture(stimulus.tex(stimulus.thisPhase(1)), [stimulus.x stimulus.y+stimulus.vertOffset], 0, 0, task.thistrial.thisOrientationStim);
    mglFixationCross(0.7, 2, stimulus.fixColor, [0 0+stimulus.vertOffset]) % green fixation is cue
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets subject response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task, myscreen)
global stimulus;

% convert tilt direction(-1,1) into button responses (1,2)
whichTilt = -task.thistrial.tiltStim/2 + 1.5;

stimulus.trialResponse(stimulus.trialCounter) = task.thistrial.whichButton;
stimulus.trialCorrectness(stimulus.trialCounter) = task.thistrial.whichButton==whichTilt;
NumIncorrect = length(stimulus.trialCorrectness) - nansum(stimulus.trialCorrectness);
stimulus.trialRT(stimulus.trialCounter) = round(task.thistrial.reactionTime*1000);

% make sure we have not already received a response
if task.thistrial.gotResponse==0
    if (task.thistrial.whichButton==whichTilt)
        % play the correct sound
        mglPlaySound('Tink');  
        % update staircase
        if stimulus.useStair
            % update HARD block performance and staircase
            stimulus.stair{stimulus.whichStair} = upDownStaircase(stimulus.stair{stimulus.whichStair}, 1);
        end
    else
        % play the incorrect sound
        mglPlaySound('Pop');
        % update staircase
        if stimulus.useStair 
            % update HARD block performance
            stimulus.stair{stimulus.whichStair} = upDownStaircase(stimulus.stair{stimulus.whichStair}, 0);
        end
    end
    disp(sprintf('%i HARD: Tilt %0.2f, RT: %0.3f, Staircase: %i, Reversals: %i', stimulus.trialCounter, -stimulus.stair{stimulus.whichStair}.threshold*task.thistrial.tiltStim, round(task.thistrial.reactionTime*1000), stimulus.whichStair, stimulus.stair{stimulus.whichStair}.reversaln));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stimulus = myInitStimulus(stimulus, myscreen, task)

% keep an array that lists which of the segments we
% are presenting the stimulus in.
stimulus.stimulusSegments = 1;

% which phases we will have
stimulus.phases = [0:45:180];

% stimulus size properties (in deg)
stimulus.size = 1;
stimulus.transition = 0.25;
stimulus.textureSize = 1.5;

% make the window for the raised cosine
xDeg2pix = mglGetParam('xDeviceToPixels');
yDeg2pix = mglGetParam('yDeviceToPixels');
widthPixels = round(stimulus.textureSize*xDeg2pix);
heightPixels = round(stimulus.textureSize*yDeg2pix);
widthPixels = widthPixels + mod(widthPixels+1,2);
heightPixels = heightPixels + mod(heightPixels+1,2);
% remember, x and y are flipped
disc = mkDisc([heightPixels widthPixels], ... % matrix size
    stimulus.size*xDeg2pix/2, ... % radius
    [heightPixels widthPixels]/2, ... % origin
    stimulus.transition * xDeg2pix); % transition

% spatial frequency
stimulus.sf = 4;

% stim location
[stimulus.x, stimulus.y] = pol2cart(-pi/4, 5);
stimulus.orientation = 90;
stimulus.duration = 200;

for i = 1:length(stimulus.phases)
    % make a gabor patch
    grating = mglMakeGrating(stimulus.textureSize, stimulus.textureSize, stimulus.sf, 0, stimulus.phases(i));
    % multiple by the contrast
    grating = grating*stimulus.contrast;
    % multiple by a raised cosine disc
    grating = grating.*disc;
    % scale it to be between 0 and 255
    grating = 255*(grating+1)/2;
    % make it into a texture
    stimulus.tex(i) = mglCreateTexture(grating);
end