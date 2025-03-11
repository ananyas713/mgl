%load stimfile
s = load('240611_stim03.mat');

%returns data on trial
exp = getTaskParameters(s.myscreen, s.task);

%get reaction time
rt = exp.reactionTime;

%get trial correctness
tc = s.stimulus.trialCorrectness;

%get tilt values for staircase 1
%replace with "stair{2}" to get values for staircase 2
tilt = s.stimulus.stair{1}.strength;

%get participant responses
resp = exp.response;