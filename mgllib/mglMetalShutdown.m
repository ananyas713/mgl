% mglMetalShutdown: Shutdown one or more running mglMetal processes
%
%        $Id$
%      usage: tf = mglMetalShutdown(socketInfo)
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Shutsdown one or more running mglMetal processes. Returns
%             true if there were mglMetal applications to shutdown.
%      usage: By default, this will shut down any mglMetal processes it can
%             find.
%
%             tf = mglMetalShutdown()
%
%             To shut down a specific process, pass in its socket info
%             struct, as returned from mglMetalStartup.
%
%             tf = mglMetalShutdown(socketInfo)
%
function tf = mglMetalShutdown(socketInfo)

if nargin < 1
    socketInfo = [];
end

[tf, pids] = mglMetalIsRunning(socketInfo);

if ~tf
    fprintf('(mglMetalShutdown) No mglMetal process is running\n');
    return
end

% Shut down all matching processes found.
for pid = pids
    fprintf('(mglMetalShutdown) mglMetal process: %i shutting down', pid);
    system(sprintf('kill -9 %i', pid));
end

% Wait for the processes to actually stop.
while(mglMetalIsRunning(socketInfo))
    fprintf('.');
end
fprintf('\n');

% Clean up the socket resources so they don't proliferate and/or interfere later.
mglSocketClose(socketInfo);
if isfile(socketInfo.address)
    delete(socketInfo.address);
end
