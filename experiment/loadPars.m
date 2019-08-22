function params = loadPars(w, rect, savestr, calibration)
% LOADPARS load run/session parameters.
% Strongly based on scripts from Zylberberg, A., Bartfeld, P., & Signman, M. (2012).
%   The construction of confidence in percpetual decision.
%   Frontiers in integrative neuroscience,6, 79.

% Matan Mazor, 2018

params.scanner_signal = KbName('5%');
params.subj = savestr{1};

params.practice = str2double(savestr{2});
params.scanning = str2double(savestr{3});

% load the subject list from the data folder.
load(fullfile('data','subjects.mat'));
if ismember(params.subj, subjects.keys)
    response_mappings = subjects(params.subj);
    %when this equals 1, bigger circles represent higher confidence 
    params.conf_mapping = response_mappings(1);
else
    error('Participant is not in subjects list');
end
    
% A while-loop to start next session in line.
if ~params.practice && ~calibration
    num_session=0;
    stopper=0;
    while stopper==0
        num_session = num_session + 1;
        aux_filename = strjoin({params.subj,...
                ['session',num2str(num_session)],'.mat'},'_');
        stopper = isempty(dir(fullfile('data',aux_filename)));
        if ~stopper
            % if previous run exists, load log and parameters as
            % 'old_params'
            old_params = load(fullfile('data',aux_filename));
        end
    end
    params.num_session = num_session;
    params.filename = aux_filename;
else
    params.num_session = 0;
    num_session=0;
    params.filename = strjoin({params.subj,'calibration.mat'},'_');
end

% Tha mapping between Gabor orientations and right/left alternates between
% runs. When this equals 1, the 'Yes'/'clockwise' response will be on the right.
params.yes = mod(params.num_session,2)+1;
% for historical reasons, 'vertical' is 'clockwise' and 'horizontal' and
% 'anticlockwise'. 
params.vertical = mod(params.num_session+1,2)+1;

%% randomize
if ~params.practice
    subject_num = str2num(params.subj(1:2));
    serial_num = subject_num*100+num_session;
      % experimental randomization is a deterministic function of the
      % contents of the protocol folder and the subject number. 
      % read more here: 
      % https://medium.com/@mazormatan/cryptographic-preregistration-from-newton-to-fmri-df0968377bb2
      params.protocolSum = preRNG('protocolFolder.zip',serial_num);
end

params.waitframes = 1; 
if params.practice || calibration
    params.DetWg = 0.075;
    params.DisWg = 0.07;
    params.AngleSD = 4.5;
elseif ~exist('old_params') 
    old_params = load(fullfile('data',strjoin({params.subj,'calibration.mat'},'_')));
    params.DetWg = old_params.params.DetWg(end);
    params.DisWg = old_params.params.DisWg(end);
    params.AngleSD = old_params.params.AngleSD(end);
else
    % Monitor and update thw Wg parameter based on performance on the
    % previous run. Don't change unless performance was below 0.525 or above
    % 0.85, in which case multiply or divide by a factor of 0.85. These
    % numbers were chosen because the likelihood of reaching these levels
    % of accuracy when performance is at 0.71 is around 1 percent.
    if params.scanning
        lower_bound = 0.525;
        upper_bound = 0.85;
    else
        lower_bound = 0.6;
        upper_bound = 0.8;
    end
    
    if nanmean(old_params.log.correct(find(old_params.log.detection)))<=lower_bound
            params.DetWg = old_params.params.DetWg(end)/0.9;
    elseif nanmean(old_params.log.correct(find(old_params.log.detection)))>=upper_bound
            params.DetWg = old_params.params.DetWg(end)*0.9;
    else
            params.DetWg = old_params.params.DetWg(end);
    end
    
    if nanmean(old_params.log.correct(find(1-old_params.log.detection)))<=lower_bound
        params.DisWg = old_params.params.DisWg(end)/0.9;        
    elseif nanmean(old_params.log.correct(find(1-old_params.log.detection)))>=upper_bound
        params.DisWg = old_params.params.DisWg(end)*0.9;
    
    elseif nanmean(old_params.log.correct(find(1-old_params.log.detection)))>=...
            nanmean(old_params.log.correct(find(old_params.log.detection)))+...
            (upper_bound-lower_bound)/2&& params.DetWg == old_params.params.DetWg(end)
        params.DetWg = old_params.params.DetWg(end)/sqrt(0.9);
        params.DisWg = old_params.params.DisWg(end)*sqrt(0.9);
        
     elseif nanmean(old_params.log.correct(find(1-old_params.log.detection)))<=...
            nanmean(old_params.log.correct(find(old_params.log.detection)))-...
            (upper_bound-lower_bound)/2&& params.DetWg == old_params.params.DetWg(end)
        params.DetWg = old_params.params.DetWg(end)*sqrt(0.9);
        params.DisWg = old_params.params.DisWg(end)/sqrt(0.9);
    
    else 
        params.DisWg = old_params.params.DisWg(end);
    end
    
        params.AngleSD = old_params.params.AngleSD(end);

end

%% Visual properties
%background color
params.bg = 0.5;
%letter size
params.letter_size = 25;
%dot color
params.fix_color = [0 0 255];
params.displace = 300;
% Screen('TextFont',w,'Corbel');
params.stimContrast = .9;


%% Timing
params.fixation_time = 0.8;
params.display_time = 1/30;
params.time_to_respond = 1.5;
params.time_to_conf = 2.5;

%% Number of trials and blocks
if params.practice
    params.trialsPerBlock = 4;
    params.Nblocks = 1;
    params.calibration = 0;
elseif calibration
    params.calibration = 1;
    params.trialsPerBlock = 100;
    params.Nblocks = 2;
else
    params.calibration = 0;
    params.trialsPerBlock = 40;
    params.Nblocks = 2;
end
params.Nsets = params.trialsPerBlock*params.Nblocks;

distance_from_monitor = 77; % cm
mon_width = 29; 
mon_height = 21.5; 
newResolution.width = 1024;
newResolution.height = 768;
cm_per_px_width  = mon_width/newResolution.width;
cm_per_px_height = mon_height/newResolution.height;
params.deg_per_px_width = cm_per_px_width * atan(1/distance_from_monitor) * 360/(2*pi);
params.deg_per_px_height = cm_per_px_height * atan(1/distance_from_monitor) * 360/(2*pi);

params.stimulus_width_deg = 3;
params.stimulus_width_px = round(params.stimulus_width_deg/params.deg_per_px_width);

params.fixation_diameter_deg = 0.2;
params.fixation_diameter_px = round(params.fixation_diameter_deg/params.deg_per_px_width);

params.cycles_deg      = 2;
params.cycle_length_deg = 1/params.cycles_deg;
params.cycle_length_px = round(params.cycle_length_deg/params.deg_per_px_width);

params.conf_diam_deg = 6;
params.conf_width_px = round(params.conf_diam_deg/params.deg_per_px_width);
params.conf_height_px = round(params.conf_diam_deg/params.deg_per_px_height);

% circle filter
x = [1:params.stimulus_width_px] - median(1:params.stimulus_width_px);
[xx yy] = meshgrid(x);
params.stimRadii    = sqrt(xx.^2 + yy.^2);
params.circleFilter = (params.stimRadii <= params.stimulus_width_px/2);

params.annulus_diameter = 6.5; %degrees

[params.center(1), params.center(2)] = RectCenter(rect);
params.rect = rect;

params.horiTexture = Screen('MakeTexture', w, imread(fullfile('textures','hori.png')));
params.vertTexture = Screen('MakeTexture', w, imread(fullfile('textures','vert.png')));

[img, ~, alpha] = imread(fullfile('textures','weAreJustAboutToBegin.png'));
img(:, :, 4) = alpha;
params.waitTexture = Screen('MakeTexture',w,img);

[img, ~, alpha] = imread(fullfile('textures','or.png'));
img(:, :, 4) = alpha;
params.orTexture = Screen('MakeTexture',w,img);

[img, ~, alpha] = imread(fullfile('textures','Y.png'));
img(:, :, 4) = alpha;
params.yesTexture = Screen('MakeTexture',w,img);

[img, ~, alpha] = imread(fullfile('textures','N.png'));
img(:, :, 4) = alpha;
params.noTexture = Screen('MakeTexture',w,img);



params.positions = {[params.center(1)-250, params.center(2)-50,...
                            params.center(1)-150, params.center(2)+50],...
             [params.center(1)+150, params.center(2)-50,...
                            params.center(1)+250, params.center(2)+50]};

params.keys = {'2@','3#'};

% determine direction and Wg for every trial
if params.practice == 2 %practice detection
    % in the practice sessions there is no guarantee that the number of CW
    % and CCW trials will be even. It is determined randomly for every
    % practice session. 
    params.vDirection = ones(params.Nsets,1)+ 2*binornd(1,0.5,params.Nsets,1);
    params.vWg = binornd(1,0.5,params.Nsets,1);
    params.vTask = [1, 1];
    params.onsets = cumsum(6*ones(params.Nsets));
    params.vPhase = rand(params.Nsets,1);
    params.vOrient = normrnd(0,1,4,1);
elseif params.practice == 1 %practice discrimination
    params.vDirection = ones(params.Nsets,1)+ 2*binornd(1,0.5,params.Nsets,1);
    params.vWg = ones(params.Nsets,1);
    params.vTask = [0,0];
    params.onsets = cumsum(6*ones(params.Nsets));
    params.vPhase = rand(params.Nsets,1);
    params.vOrient = normrnd(0,1,4,1);
else % true experimental session or calibration
    params.run_duration = 601.44; %seconds = 179 TRs of 3.36 seconds;
    [params.vDirection, params.vWg, params.vTask, params.onsets,...
        params.vPhase, params.vOrient] = ...
    get_trials_params(params);
end
end