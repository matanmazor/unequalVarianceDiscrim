function target = generate_stim(params, num_trial)
% GENERATE_STIM takes as input the parameter structure and the trial number
% and returns the target matrix.
% largely based on a script used for 
% Fleming, S. M., Maniscalco, B., Ko, Y., Amendi, N., Ro, T., & Lau, H.
%   (2015). Action-specific disruption of perceptual confidence. 
%   Psychological science, 26(1), 89-98.
% Matan Mazor 2018

% make target patch
grating   =    makeGrating(params.stimulus_width_px,[],1,...
    params.cycle_length_px,'pixels per period','vertical',...
    params.vPhase(num_trial));

% noise     = (1-(params.Wg *  params.vWg(num_trial))) * (2*rand(params.stimulus_width_px)-1);

noisyGrating = 2*Scale(grating)-1;

target    = round( 127 + 127 * params.stimContrast * noisyGrating );

target(params.circleFilter==0) = 127;


