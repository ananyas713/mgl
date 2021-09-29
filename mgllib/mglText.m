% mglText.m
%
%        $Id$
%      usage: tex = mglText('string')
%         by: justin gardner
%       date: 09/28/2021 Based on version from 05/10/06
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns a texture for a string
%
%       e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextSet('Helvetica',32,[1 1 1],0,0,0);
%thisText = mglText('Hello')
%mglBltTexture(thisText,[0 0],'left','top');
%mglFlush;
function tex = mglText(str)

if (nargin ~= 1) || ~isstr(str)
  help mglText;
  return
end

% get the image of the text
im = mglPrivateText(str);

% need to reshape
im.textImage = reshape(im.textImage,im.imageHeight,im.imageWidth,4);
im.textImage = permute(im.textImage,[2 1 3]);

% create the texture
tex = mglMetalCreateTexture(im.textImage);
