%{
  Calibration for fMRI experiment, run in the Wellcome Centre for Human Neuroimaging.
  Matan Mazor, 2019.
  First calibrate Alpha on the detection task, and then calibrate
  AngleMu on the discrimination task, using the fixed alpha value.
%}

clear all
version = '2018-08-14';
%{
    add path to the preRNG folder, to support cryptographic time-locking of
    hypotheses and analysis plans. Can be downloaded/cloned from
    github.com/matanmazor/prerng
%}

addpath('..\..\..\complete\preRNG\Matlab')
% PsychDebugWindowConfiguration()

%global variables
global log
global params
global global_clock
global w %psychtoolbox window

%name: name of subject. Should start with the subject number. The name of
%the subject should be included in the data/subjects.mat file.
prompt = {'Name: ', 'Practice: ', 'Scanning: '};
dlg_title = 'Filename'; % title of the input dialog box
num_lines = 1; % number of input lines
default = {'999MaMa','0','0'}; % default filename
savestr = inputdlg(prompt,dlg_title,num_lines,default);

%set preferences and open screen
% Screen('Preference','SkipSyncTests', 1)
screens=Screen('Screens');
screenNumber=max(screens);
doublebuffer=1;

%The fMRI button box does not work well with KbCheck. I use KbQueue
%instead here, to get precise timings and be sensitive to all presses.
KbQueueCreate;
KbQueueStart;

%Open window.
[w, rect] = Screen('OpenWindow', screenNumber, [127,127,127],[], 32, doublebuffer+1);
Screen(w,'TextSize',40)
%Load parameters (calibration is true)
params = loadPars(w, rect, savestr, 1);

KbName('UnifyKeyNames');
AssertOpenGL;
PsychVideoDelayLoop('SetAbortKeys', KbName('Escape'));
HideCursor();
Priority(MaxPriority(w));

% Enable alpha blending with proper blend-function. We need it
% for drawing of smoothed points:
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Initialize log with NaNs where possible.
log.confidence = nan(params.Nsets,1);
log.resp = zeros(params.Nsets,2);
log.detection = nan(params.Nsets,1);
log.Alpha = nan(params.Nsets,1);
log.correct = nan(params.Nsets,1);
log.events = [];
stack = [];

step_size = 0.95; % this is actually more of a step factor

%% WAIT FOR 5
% Wait for the 6th volume to start the experiment.
% The 2d sequence sends a 5 for every slice, so waiting for 48*5 fives
% before starting the experiment.

excludeVolumes = 5;
slicesperVolume = 48;

%initialize
num_five = 0;
while num_five<excludeVolumes*slicesperVolume
    Screen('DrawTexture', w, params.waitTexture);
    vbl=Screen('Flip', w);
    [ ~, firstPress]= KbQueueCheck;
    if firstPress(params.scanner_signal)
        num_five = num_five+1;
    elseif firstPress(KbName('0)'))  %for debugging
        num_five = inf;
    elseif firstPress(KbName('ESCAPE'))
        Screen('CloseAll');
        clear;
        return
    end
end


%stop recording 5s from the scanner, because it seems to be too much for
%the kbcheck function.
DisableKeysForKbCheck(KbName('5%'));

proceed = 1;
num_trial = 0;
alpha = 0.05;
anglesigma = 40;

global_clock = tic();

while toc(global_clock)<params.instruction_time
    
    Screen('DrawTexture', w, params.yesTexture, [], params.positions{params.yes})
    Screen('DrawTexture', w, params.noTexture, [], params.positions{3-params.yes})
    
    % because DrawText is not working :-(
    % https://github.com/Psychtoolbox-3/Psychtoolbox-3/issues/579
    Screen('DrawTexture', w, params.orTexture);
    %             DrawFormattedText(w, '?',params.positions{2}(3)+100,'center');
    
    vbl=Screen('Flip', w);
    keysPressed = queryInput();
end

%% MAIN LOOP: detection
while proceed
    
    num_trial = num_trial+1;
    trial_clock = tic();
    
    % Restrat Queue
    KbQueueStart;
    
    % Start actual trials:
    % Generate the stimulus.
    [target,target_xy] = generate_stim(params, num_trial);
    
    % Save to log.
    log.Alpha(num_trial) = params.vPresent(num_trial)*alpha(end);
    log.Orientation(num_trial) = params.vOrient(num_trial)*...
        (1-params.vVertical(num_trial));
    log.xymatrix{num_trial} = target_xy;
    log.detection(num_trial) = 1;
    
    
    while toc(trial_clock)<0.5
        % Present a dot at the centre of the screen.
        Screen('DrawDots', w, [0 0]', ...
            params.fixation_diameter_px, [255 255 255]*0.4, params.center,1);
        vbl=Screen('Flip', w);%initial flip
        
        keysPressed = queryInput();
    end
    
    response = [nan nan];
    
    while toc(trial_clock)<1.5
        % Present the fixation cross.
        %         DrawFormattedText(w, '+','center','center');
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    % Present the stimulus.
    tini = GetSecs;
    % The onset of the stimulus is encoded in the log file as '0'.
    log.events = [log.events; 0 toc(global_clock)];
    
    while (GetSecs - tini)<params.display_time
        Screen('DrawTextures',w,target, [], [],params.AngleMu+anglesigma(end)*...
            params.vOrient(num_trial),...
            [], alpha(end)*params.vPresent(num_trial));
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    %% Wait for response
    while (GetSecs - tini)<params.display_time+params.time_to_respond
        
        %During the first 200 milliseconds a fixation cross appears on
        %the screen. The subject can respond during this time
        %nevertheless.
        if (GetSecs - tini)<params.display_time+0.2
            Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
            %               DrawFormattedText(w, '+','center','center');
        else
            Screen('DrawTexture', w, params.yesTexture, [], params.positions{params.yes}, ...
                [],[], 0.5+0.5*(response(2)==1))
            Screen('DrawTexture', w, params.noTexture, [], params.positions{3-params.yes},...
                [],[], 0.5+0.5*(response(2)==0))
        end
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
        if keysPressed(KbName(params.keys{params.yes}))
            response = [GetSecs-tini 1];
        elseif keysPressed(KbName(params.keys{3-params.yes}))
            response = [GetSecs-tini 0];
        end
    end
    
   
    % Write to log.
    log.resp(num_trial,:) = response;
    log.stimTime{num_trial} = vbl;
    if keysPressed(KbName('ESCAPE'))
        Screen('CloseAll');
    end
    
    % Check if the response was accurate or not
    if log.resp(num_trial,2)== sign(params.vPresent(num_trial))
        log.correct(num_trial) = 1;
        stack(end+1) = 1;
    else
        log.correct(num_trial) = 0;
        stack(end+1) = 0;
    end
    
    %1up2down
    if stack(end) == 0
        alpha(end+1) = alpha(end)/step_size;
        stack = [];
    elseif numel(stack)==2
        alpha(end+1) = alpha(end)*step_size;
        stack = [];
    else
        alpha(end+1) = alpha(end);
    end
    
    if num_trial>=60 && mod(num_trial,20)==0
        
        last_20 = nanmean(log.correct(num_trial-19:num_trial));
        lastlast_20 = nanmean(log.correct(num_trial-39:num_trial-20));

        if all([last_20,lastlast_20]<=0.75) && all([last_20,lastlast_20]>=0.67)
            proceed = 0
            params.Alpha = 2^(mean(log2(alpha(num_trial-39:num_trial))));
        end
    end

end

global_clock = tic();

while toc(global_clock)<params.instruction_time
    
    Screen('DrawTexture', w, params.vertTexture, [], params.positions{params.vertical})
    Screen('DrawTexture', w, params.xTexture, [], params.positions{3-params.vertical})
    
    % because DrawText is not working :-(
    % https://github.com/Psychtoolbox-3/Psychtoolbox-3/issues/579
    Screen('DrawTexture', w, params.orTexture);
    %             DrawFormattedText(w, '?',params.positions{2}(3)+100,'center');
    
    vbl=Screen('Flip', w);
    keysPressed = queryInput();

end

num_trial = 1000;
proceed = 1;

%% MAIN LOOP: discrimination
while proceed
    
    num_trial = num_trial+1;
    trial_clock = tic();
    
    % Restrat Queue
    KbQueueStart;
    
    % Start actual trials:
    % Generate the stimulus.
    [target,target_xy] = generate_stim(params, num_trial);
    
    % Save to log.
    log.Alpha(num_trial) = params.vPresent(num_trial)*alpha(end);
    log.Orientation(num_trial) = params.vOrient(num_trial)*...
        (1-params.vVertical(num_trial));
    log.xymatrix{num_trial} = target_xy;
    log.detection(num_trial) = 0;
    
    
    while toc(trial_clock)<0.5
        % Present a dot at the centre of the screen.
        Screen('DrawDots', w, [0 0]', ...
            params.fixation_diameter_px, [255 255 255]*0.4, params.center,1);
        vbl=Screen('Flip', w);%initial flip
        
        keysPressed = queryInput();
    end
    
    response = [nan nan];
    
    while toc(trial_clock)<1.5
        % Present the fixation cross.
        %         DrawFormattedText(w, '+','center','center');
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    % Present the stimulus.
    tini = GetSecs;
    % The onset of the stimulus is encoded in the log file as '0'.
    log.events = [log.events; 0 toc(global_clock)];
    
    while (GetSecs - tini)<params.display_time
        Screen('DrawTextures',w,target, [], [],(1-params.vVertical(num_trial))*...
            (params.AngleMu+anglesigma(end)*params.vOrient(num_trial)),...
            [], params.Alpha*params.vPresent(num_trial));
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    %% Wait for response
    while (GetSecs - tini)<params.display_time+params.time_to_respond
        
        %During the first 200 milliseconds a fixation cross appears on
        %the screen. The subject can respond during this time
        %nevertheless.
        if (GetSecs - tini)<params.display_time+0.2
            Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
            %               DrawFormattedText(w, '+','center','center');
        else
            Screen('DrawTexture', w, params.vertTexture, [], params.positions{params.vertical},...
                [],[],0.5+0.5*(response(2)==1))
            Screen('DrawTexture', w, params.xTexture, [], params.positions{3-params.vertical},...
                [],[],0.5+0.5*(response(2)==0))
        end
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
        if keysPressed(KbName(params.keys{params.vertical}))
            response = [GetSecs-tini 1];
        elseif keysPressed(KbName(params.keys{3-params.vertical}))
            response = [GetSecs-tini 0];
        end
    end
    
   
    % Write to log.
    log.resp(num_trial,:) = response;
    log.stimTime{num_trial} = vbl;
    if keysPressed(KbName('ESCAPE'))
        Screen('CloseAll');
    end
    
    % Check if the response was accurate or not
    if sign(log.resp(num_trial,2))== sign(params.vVertical(num_trial))
        log.correct(num_trial) = 1;
        stack(end+1) = 1;
    else
        log.correct(num_trial) = 0;
        stack(end+1) = 0;
    end
    
    %1up2down
    if stack(end) == 0
        anglesigma(end+1) = anglesigma(end)/step_size;
        stack = [];
    elseif numel(stack)==2
        anglesigma(end+1) = anglesigma(end)*step_size;
        stack = [];
    else
        anglesigma(end+1) = anglesigma(end);
    end
    
    if num_trial>=1060 && mod(num_trial,20)==0
        
        last_20 = nanmean(log.correct(num_trial-19:num_trial));
        lastlast_20 = nanmean(log.correct(num_trial-39:num_trial-20));

        if all([last_20,lastlast_20]<=0.75) && all([last_20,lastlast_20]>=0.67)
            proceed = 0
            params.AngleSigma = 2^(mean(log2(anglesigma(end-39:end))));
        end
    end

end

%% close
Priority(0);
ShowCursor
Screen('CloseAll');

% Make a gong sound so that I can hear from outside the testing room that
% the behavioural session is over :-)
if ~params.scanning
    load gong.mat;
    soundsc(y);
end

%% write to log

if ~params.practice
    log.date = date;
    log.version = version;
    save(fullfile('data', params.filename),'params','log');
    if exist(fullfile('data', ['temp_',params.filename]), 'file')==2
        delete(fullfile('data', ['temp_',params.filename]));
    end
end

