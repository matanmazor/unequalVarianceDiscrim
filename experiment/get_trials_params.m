function [vVertical, vPresent, vTask, vOnset, vOrient] = get_trials_params(params)
%{
 GET_TRIALS_PARAMS this function randomizes the orientation
 and presence of stimuli, the order of the detection and discrimination
 blocks, and the timing of events.
%}

Nsets = params.Nsets;
Nblocks = params.Nblocks;

% randomize blocks for detection/discrimination. Always interleaved, but
% the first can be detection or discrimination.
% 0 is discrimination, 1 detection
vTask = reshape([ones(Nblocks/2,1) zeros(Nblocks/2,1)]',Nblocks,1);
if binornd(1,0.5)
    vTask = 1-vTask;
end

vPresent = [];
vVertical = [];

% loop over experimental blocks
for i=1:length(vTask)
    
    % is this a detection or a discrimination block?
    detection = vTask(i);
   
    if ~detection
       vVertical = [vVertical; binornd(1,0.5,params.trialsPerBlock,1)];
       vPresent = [vPresent; ones(params.trialsPerBlock,1)];

    else 
        vVertical = [vVertical; zeros(params.trialsPerBlock,1)];
        vPresent = [vPresent; binornd(1,0.5,params.trialsPerBlock,1)];
    end
    
end

vOrient = normrnd(params.AngleMu,params.AngleSigma,params.Nsets,1);

%% Randomize event timing

% the trial duration includes extra 0.8 seconds to make the minimum spacing
% between consecutive trials 800 milliseconds.
trial_duration = params.fixation_time + params.display_time...
    + params.time_to_respond + params.time_to_conf+0.8;
% this is the duration (in seconds) of all trials combined + 10 seconds 
% for the beginning of each experimental block.
used_time = trial_duration*length(vPresent)+10*length(vTask);
% this is the duration (in seconds) of rest time that can be fiddled with.
spare_time = params.run_duration-used_time;
% to add gitter to all events, first I draw numbers from a uniform
% distribution between 1 and 0, and scale them so that the minimum is 0 and
% the maximum is 1.
gitter_vec = Scale(rand(size(vPresent)));
% I then multiply them by the factor needed to make their total duration
% equal to the spare_time. 
gitter_vec = gitter_vec/sum(gitter_vec)*spare_time;
% add the trial duration and the instruction screens to the gitter_vec.
gitter_vec = gitter_vec+trial_duration;
gitter_vec = [0; gitter_vec];
gitter_vec(1:Nsets/Nblocks:end) = gitter_vec(1:Nsets/Nblocks:end)+10;
% now the vector of trial onsets is the serial accumulation of the gitter vec.
vOnset = cumsum(gitter_vec(1:end-1));


if vOnset(end)-params.run_duration > eps && ~params.calibration
    error('the randomization procedure went wrong')
end

end
