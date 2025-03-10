

% load the task parameters
% e = getTaskEyeTraces('240425_stim01.mat');

% load the EDF file
edf3 = mglEyelinkEDFRead('24042503.edf');
edf4 = mglEyelinkEDFRead('24042504.edf'); 

% get the onset time for each trial
onsetTimes3 = edf3.mgl.time(edf3.mgl.segmentNum==1);
onsetTimes4 = edf4.mgl.time(edf4.mgl.segmentNum==1);

% account for the fact that the experiment startime varies
onsetTimes3 = round((onsetTimes3 - edf3.gaze.time(1))/2);
onsetTimes4 = round((onsetTimes4 - edf4.gaze.time(1))/2);

% % create the design matrix
% d = zeros(length(edf.gaze.pupil), 4);
% 
% % parse the different conditions
% d(onsetTimes(e.parameter.lightCond==1), 1) = 1;
% d(onsetTimes(e.parameter.lightCond==3), 2) = 1;
% d(onsetTimes(e.parameter.lightCond==4), 3) = 1;
% d(onsetTimes(e.parameter.lightCond==8), 4) = 1;
% 
% 
% grab the pupil data and remove NaN's (which are blinks)
pupil3 = edf3.gaze.pupil;
pupiltest3 = pupil3;
pupiltest3(find(isnan(pupil3)))=0;
% inn = ~isnan(pupil);
% i1 = (1:numel(pupil)).';
% pp = interp1(i1(inn),pupil(inn),'linear','pp');
output3 = blinkinterp(pupiltest3,500,5,3,124,184);
% pupil = fnval(pp,linspace(i1(1),i1(end),length(pupil)));
pupil3 = output3;

pupil4 = edf4.gaze.pupil;
pupiltest4 = pupil4;
pupiltest4(find(isnan(pupil4)))=0;
% inn = ~isnan(pupil);
% i1 = (1:numel(pupil)).';
% pp = interp1(i1(inn),pupil(inn),'linear','pp');
output4 = blinkinterp(pupiltest4,500,5,3,124,184);
% pupil = fnval(pp,linspace(i1(1),i1(end),length(pupil)));
pupil4 = output4;

xaxis = [1:length(pupil3)];
xaxis1 = [1:length(pupil4)];
xaxis2 = xaxis/500;
xaxis3 = xaxis1/500;
plot(xaxis2, pupil3)
hold on
plot(xaxis3, pupil4)
title('Pupil Size for Monitor On/Off Conditions','FontSize',22)
xlabel('Time (sec)','FontSize',18)
ylabel('Pupil Diameter','FontSize',18)
lgd = legend('Monitor ON','Monitor OFF');
fontsize(lgd,18,'points')
hold off
% onsetTimes2 = onsetTimes/500;
% xline(onsetTimes2)

%% New Section

edf = mglEyelinkEDFRead('24052317.edf');

onsetTimes = edf.mgl.time(edf.mgl.segmentNum==1);

onsetTimes = round((onsetTimes - edf.gaze.time(1))/2);

pupil = edf.gaze.pupil;
pupiltest = pupil;
pupiltest(find(isnan(pupil)))=0;

output = blinkinterp(pupiltest,500,5,3,124,184);
pupil = output;

xaxis = [1:length(pupil)];
xaxis2 = xaxis/500;

plot(xaxis2, pupil)
title('Pupil Size for Light Box LOW Monitor OFF Condition','FontSize',22)
xlabel('Time (sec)','FontSize',18)
ylabel('Pupil Diameter','FontSize',18)
onsetTimes2 = onsetTimes/500;
xline(onsetTimes2)

%% Pilot Analyses

edf1 = mglEyelinkEDFRead('24052316.edf'); %low mel 1
edf2 = mglEyelinkEDFRead('24052317.edf'); %low mel 2
edf3 = mglEyelinkEDFRead('24052314.edf'); %high mel 1
edf4 = mglEyelinkEDFRead('24052315.edf'); %high mel 2

onsetTimes1 = edf1.mgl.time(edf1.mgl.segmentNum==1);
onsetTimes1 = round((onsetTimes1 - edf1.gaze.time(1))/2);
onsetTimes2 = edf2.mgl.time(edf2.mgl.segmentNum==1);
onsetTimes2 = round((onsetTimes2 - edf2.gaze.time(1))/2);
onsetTimes3 = edf3.mgl.time(edf3.mgl.segmentNum==1);
onsetTimes3 = round((onsetTimes3 - edf3.gaze.time(1))/2);
onsetTimes4 = edf4.mgl.time(edf4.mgl.segmentNum==1);
onsetTimes4 = round((onsetTimes4 - edf4.gaze.time(1))/2);

pupil1 = edf1.gaze.pupil;
pupiltest1 = pupil1;
pupiltest1(find(isnan(pupil1)))=0;
pupil2 = edf2.gaze.pupil;
pupiltest2 = pupil2;
pupiltest2(find(isnan(pupil2)))=0;
pupil3 = edf3.gaze.pupil;
pupiltest3 = pupil3;
pupiltest3(find(isnan(pupil3)))=0;
pupil4 = edf4.gaze.pupil;
pupiltest4 = pupil4;
pupiltest4(find(isnan(pupil4)))=0;

output1 = blinkinterp(pupiltest1,500,5,3,124,184);
pupil1 = output1;
output2 = blinkinterp(pupiltest2,500,5,3,124,184);
pupil2 = output2;
output3 = blinkinterp(pupiltest3,500,5,3,124,184);
pupil3 = output3;
output4 = blinkinterp(pupiltest4,500,5,3,124,184);
pupil4 = output4;

pupill = [pupil1 pupil2];
pupilh = [pupil3 pupil4];
% m1 = mean(pupilh(30000:100000));
% m2 = mean(pupill(30000:100000));
% pupilh = pupilh-(m1-m2);

xaxis = [1:length(pupill)];
xaxis2 = xaxis/500;
xaxis1 = [1:length(pupilh)];
xaxis3 = xaxis1/500;

plot(xaxis2, pupill)
hold on
plot(xaxis3, pupilh)
title('Pupil Size','FontSize',22)
xlabel('Time (sec)','FontSize',18)
ylabel('Pupil Diameter','FontSize',18)
lgd = legend('High MEL','Low MEL');
fontsize(lgd,18,'points')
hold off
