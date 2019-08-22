function [target, target_xy] = generate_stim(params, num_trial)
%{ 
 GENERATE_STIM takes as input the parameter structure and the trial number
 and returns the target texture.
 largely based on a script used for 
 Fleming, S. M., Maniscalco, B., Ko, Y., Amendi, N., Ro, T., & Lau, H.
   (2015). Action-specific disruption of perceptual confidence. 
   Psychological science, 26(1), 89-98.
 Matan Mazor 2019
%}

global w

% make target patch
[target_xy,mask]  =    makeGrating(params.stimulus_width_px,[],1,...
    params.cycle_length_px,'pixels per period','vertical',...
    params.vPhase(num_trial));

grating = repmat(255*Scale(target_xy),1,1,3);
target = Screen('MakeTexture',w,cat(3, grating, 255*Scale(params.circleFilter)));


