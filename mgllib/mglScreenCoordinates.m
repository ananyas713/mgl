% mglScreenCoordinates.m
%
%        $Id$
%      usage: mglScreenCoordinates()
%         by: justin gardner
%       date: 05/27/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set coordinate frame so that it is in pixels
%             with 0,0 in the top left hand corrner
%
function retval = mglScreenCoordinates()

% check arguments
if ~any(nargin == [0])
    help mglScreenCoordinates
    return
end

if mglGetParam('displayNumber') == -1
    disp(sprintf('(mglVisualAngleCoordinates) No open display'));
    return
end

% remember old settings
oldTransform = mglTransform('get');

% now set them for screen coordinates
mglTransform('set', eye(4));
mglTransform('scale', [2.0/mglGetParam('screenWidth'),2.0/mglGetParam('screenHeight'),1]);
mglTransform('translate', [-mglGetParam('screenWidth')/2.0,-mglGetParam('screenHeight')/2.0,0.0]);
mglFlush();

% set the globals appropriately
mglSetParam('xDeviceToPixels',1.0);
mglSetParam('yDeviceToPixels',1.0);
mglSetParam('xPixelsToDevice',1.0);
mglSetParam('yPixelsToDevice',1.0);
mglSetParam('deviceCoords','screenCoordinates');
mglSetParam('deviceRect',[0 0 mglGetParam('screenWidth') mglGetParam('screenHeight')]);
mglSetParam('deviceWidth',mglGetParam('screenWidth'));
mglSetParam('deviceHeight',mglGetParam('screenHeight'));
mglSetParam('screenCoordinates',1);
mglSetParam('deviceHDirection',1);
mglSetParam('deviceVDirection',1);

% check to see if textures need to be recreated
newTransform = mglTransform('get');
if mglGetParam('numTextures') > 0 && ~isequal(newTransform, oldTransform)
    disp(sprintf('(mglVisualAngleCoordinates) All previously created textures will need to be reoptimized with mglReoptimizeTexture'));
end
