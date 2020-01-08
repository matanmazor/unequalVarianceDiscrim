clear all
version = '2019-12-11';

% add path to the preRNG folder, to support cryptographic time-locking of
% hypotheses and analysis plans. Can be downloaded/cloned from
% github.com/matanmazor/prerng
% addpath('..\..\..\2018\preRNG\Matlab')

PsychDebugWindowConfiguration()

%global variables
global log
global params
global w %psychtoolbox window
global global_clock
global_clock = tic();

%name: name of subject. Should start with the subject number. The name of
%the subject should be included in the data/subjects.mat file.
%practice: enter 0.
%scanning: enter 0

prompt = {'Name: ', 'Practice: ', 'Scanning: '};
dlg_title = 'Filename'; % title of the input dialog box
num_lines = 1; % number of input lines
default = {'999MaMa','0','0'}; % default filename
savestr = inputdlg(prompt,dlg_title,num_lines,default);

%set preferences and open screen
Screen('Preference','SkipSyncTests', 1)
screens=Screen('Screens');
screenNumber=max(screens);
doublebuffer=1;

%The fMRI button box does not work well with KbCheck. I use KbQueue
%instead here, to get precise timings and be sensitive to all presses.
KbQueueCreate;
KbQueueStart;

[w, rect] = Screen('OpenWindow', screenNumber, [127,127,127],[], 32, doublebuffer+1);
Screen(w,'TextSize',40)

%load parameters
params = loadPars(w, rect, savestr, 1);

KbName('UnifyKeyNames');
AssertOpenGL;
PsychVideoDelayLoop('SetAbortKeys', KbName('Escape'));
HideCursor();
Priority(MaxPriority(w));

% Enable alpha blending with proper blend-function. We need it
% for drawing of smoothed points:
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% In order to make sure that gratings are being presented even with very 
% low alpha levels (https://github.com/Psychtoolbox-3/Psychtoolbox-3/issues/585)
% I enable PseudoGray. help CreatePseudoGrayLUT
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'EnablePseudoGrayOutput');


%MM: initialize decision log
log.resp = zeros(params.Nsets,2);
log.task = nan(params.Nsets,1);
log.Alpha = nan(params.Nsets,1);
log.correct = nan(params.Nsets,1);
log.tilt = nan(params.Nsets,1);
log.estimates = [];
log.events = [];

% change parameters:
params.trialsPerBlock = 1000; %arbitrary large number
params.Nsets = 3000;
[params.vVertical, params.vPresent, params.vTask, params.vOnset, params.vOrient] = ...
    get_trials_params(params);

% has performance level converged yet?
converged = 0;


num_trial = 1;
last_two_trials = [0,0];
alpha_vec = [];
%% Strart the trials
while num_trial <= params.Nsets
    
    %At the beinning of each block, do:
    if mod(num_trial,round(params.trialsPerBlock))==1
        
        save(fullfile('data', params.filename),'params','log');
        
        %which task is it? 0: discrimination, 1: detection, or 2: tilt?
        task = params.vTask(ceil(num_trial/params.trialsPerBlock));
        
        if task ==0
            Screen('DrawTexture', w, params.vertTexture, [], params.positions{params.clockwise}, 45);
            Screen('DrawTexture', w, params.vertTexture, [], params.positions{3-params.clockwise}, -45)
            alpha = params.DisAlpha(end);
        elseif task==1
            Screen('DrawTexture', w, params.yesTexture, [], params.positions{params.yes})
            Screen('DrawTexture', w, params.noTexture, [], params.positions{3-params.yes})
            alpha = params.DetAlpha(end);
        elseif task ==2
            Screen('DrawTexture', w, params.vertTexture, [], params.positions{params.vertical})
            Screen('DrawTexture', w, params.xTexture, [], params.positions{3-params.vertical})
            alpha = params.TiltAlpha(end);
        else
            error('unknown task number');
        end
        
        Screen('DrawTexture', w, params.orTexture);
        vbl=Screen('Flip', w);
        
        instruction_clock = tic;
        keyIsDown = queryInput();
        while ~keyIsDown
            keyIsDown = KbQueueCheck();
        end
    end
    
    % Start actual trials:
    % Generate the stimulus.
    [target,target_xy] = generate_stim(params, num_trial);
    
    %     % Save to log.
    log.Alpha(num_trial) = params.vPresent(num_trial)*alpha;
    log.Orientation(num_trial) = params.vOrient(num_trial)*...
        (1-params.vVertical(num_trial));
    log.xymatrix{num_trial} = target_xy;
    log.task(num_trial) = task;
    
    response = [nan nan];
    
    % MM: fixation
    Screen('DrawDots', w, [0 0]', ...
        params.fixation_diameter_px, [255 255 255]*0.4, params.center,1);
    vbl=Screen('Flip', w);%initial flip
    
    % since timing is not an issue for the calibration phase, timing is
    % always relative to the onset of a trial and not the onset of the run.
    trial_clock = tic;
    
    % rest of 1 second
    while toc(trial_clock)<1
        keysPressed = queryInput();
    end
    
    % present fixation cross for 0.5 second
    while toc(trial_clock)<1.5
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    tini = GetSecs;
    
    %present stimulus
    while (GetSecs - tini)<params.display_time
        Screen('DrawTextures',w,target, [], [],(1-params.vVertical(num_trial))...
            *params.vOrient(num_trial),...
            [], alpha*params.vPresent(num_trial));
        Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
        vbl=Screen('Flip', w);
        keysPressed = queryInput();
    end
    
    if task ==0 %discrimination
        while (GetSecs - tini)<params.display_time+params.time_to_respond
            
            Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
            
            if (GetSecs - tini)>=params.display_time+0.2
                Screen('DrawTexture', w, params.vertTexture, [], params.positions{params.clockwise},...
                    45,[],0.5+0.5*(response(2)==1))
                Screen('DrawTexture', w, params.vertTexture, [], params.positions{3-params.clockwise},...
                    -45,[],0.5+0.5*(response(2)==0))
            end
            
            vbl=Screen('Flip', w);
            keysPressed = queryInput();
            if keysPressed(KbName(params.keys{params.clockwise}))
                response = [GetSecs-tini 1];
            elseif keysPressed(KbName(params.keys{3-params.clockwise}))
                response = [GetSecs-tini 0];
            end
        end
        
    elseif task==1 %detection
        while (GetSecs - tini)<params.display_time+params.time_to_respond
            
            %During the first 200 milliseconds a fixation cross appears on
            %the screen. The subject can respond during this time
            %nevertheless.
            Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
            
            if (GetSecs - tini)>=params.display_time+0.2
                
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
        
    elseif task==2 %tilt discrimination
        while (GetSecs - tini)<params.display_time+params.time_to_respond
            
            Screen('DrawTexture', w, params.crossTexture,[],params.cross_position);
            
            if (GetSecs - tini)>=params.display_time+0.2
                %
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
    end
    
    
    log.resp(num_trial,:) = response;
    if keysPressed(KbName('ESCAPE'))
        Screen('CloseAll');
    end
    
    % MM: check if the response was accurate or not
    if task==0 && ~isnan(log.resp(num_trial,2))
        if sign(log.resp(num_trial,2))== sign(params.vOrient(num_trial)+45)
            log.correct(num_trial) = 1;
        else
            log.correct(num_trial) = 0;
        end
    elseif task==1 && ~isnan(log.resp(num_trial,2))
        if log.resp(num_trial,2)== sign(params.vPresent(num_trial))
            log.correct(num_trial) = 1;
        else
            log.correct(num_trial) = 0;
        end
    elseif task==2 && ~isnan(log.resp(num_trial,2))
        if log.resp(num_trial,2) == params.vVertical(num_trial)
            log.correct(num_trial) = 1;
        else
            log.correct(num_trial) = 0;
        end
    end
    
    % end of decision phase
    % monitor and update coherence levels
    % 1 up 2 down procedure
    
    if mod(num_trial,round(params.trialsPerBlock))>1
        if log.correct(num_trial) == 0
            a = 'incorrect'
            alpha = alpha/0.9
            last_two_trials = [0,0]
        elseif log.correct(num_trial)==1
            if last_two_trials(2) == 1
                a= 'two in a row'
                alpha = alpha*0.9
                last_two_trials = [0,0]
            elseif last_two_trials(2) == 0
                last_two_trials = [0,1]
            end
        end
        
        %if alpha didn't change this time, and we're over 80 trials
        %into the calibration phase
        if mod(num_trial,10)==0
            
            if task==0
                params.DisAlpha = [params.DisAlpha;  mode(log.Alpha(num_trial-9:num_trial))];
            elseif task==1
                %don't take into account target absence trials.
                last_alphas = log.Alpha(num_trial-9:num_trial);
                params.DetAlpha = [params.DetAlpha; mode(last_alphas(last_alphas>0))];
            elseif task==2
                params.TiltAlpha = [params.TiltAlpha;  mode(log.Alpha(num_trial-9:num_trial))];
            end
            
            if mod(num_trial, params.trialsPerBlock)>80
                %and it didn't change last time either, move to the next
                %task.
                if task==0 && params.DisAlpha(end-1)==params.DisAlpha(end)
                    last_two_trials = [0,0];
                    num_trial = ceil(num_trial/params.trialsPerBlock)*params.trialsPerBlock;
                elseif task==1 && params.DetAlpha(end-1)==params.DetAlpha(end)
                    last_two_trials = [0,0];
                    num_trial = ceil(num_trial/params.trialsPerBlock)*params.trialsPerBlock;
                elseif task==2 && params.TiltAlpha(end-1)==params.TiltAlpha(end)
                    last_two_trials = [0,0];
                    num_trial = ceil(num_trial/params.trialsPerBlock)*params.trialsPerBlock;
                end
            end
        end
    end
    num_trial = num_trial+1;
end

%% write to log

log.date = date;
log.filename = params.filename;
log.version = version;
save(fullfile('data', params.filename),'params','log');

if ~params.scanning
    load gong.mat;
    soundsc(y);
end

%% close
Priority(0);
ShowCursor
Screen('CloseAll');
