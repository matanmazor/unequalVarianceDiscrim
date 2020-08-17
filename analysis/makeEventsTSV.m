function [] = makeEventsTSV(subj_id, scanner_code)
% create a TSV file with event information

fclose('all');

subj_files = dir(fullfile('..','experiment','data',[subj_id,'_session*_lite.mat']));

dis_map = containers.Map([0,1],{'A','C'});
det_map = containers.Map([0,1],{'N','Y'});
tilt_map = containers.Map([0,1],{'V','T'});


for j = 1:length(subj_files)
    
    load(fullfile('..','experiment','data',subj_files(j).name));
    
    %% SOME SANITY CHECKS
    if sum(log.events(:,1)==0) ~= params.Nsets
        error('The numbers of planned and executed events are not identical');
    end
    
    %% WRITE TSV FILE
    
    %% initialize file
    if ~exist(fullfile('..','data','data',scanner_code,'func'),'dir')
        mkdir(fullfile('..','data','data',scanner_code,'func'))
    end
    file_path = fullfile('..','data','data',scanner_code,'func',...
        strcat(scanner_code,'_task-unequalVariance_run-',sprintf('%02d',j),'_events.tsv'));
    if exist(file_path, 'file')==2
        delete(file_path);
    end
    fileID = fopen(file_path,'a');
    
    %field names
    fprintf(fileID, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'onset','duration',...
        'trial_type','response_time','confidence','task','stimulus','response','key_id','include','uid');
    
    %% loop over events
    trial_counter = 0;
    for event_idx = 1:length(log.events)
        
        %is it a trial or a button press?
        if log.events(event_idx,1)==0 % trial onset
            
            trial_counter = trial_counter+1;
            % figure out the trial type
            if log.task(trial_counter)==0 %discrimination
                task = 0;
                stimulus = log.orientation(trial_counter)==45.0;
                response = log.resp(trial_counter,2);
            elseif log.task(trial_counter)==1 %detection
                task =1;
                stimulus = log.Alpha(trial_counter)>0;
                response = log.resp(trial_counter,2);
                % I know it's confusing, but in the original log files
                % response '0' means 'tilted' and '1' vertical, but in the
                % analysis scripts it's the other way around. So we're
                % switching the response mapping here:
            elseif log.task(trial_counter)==2 %tilt recognition
                task = 2;
                stimulus = log.orientation(trial_counter)~=0;
                response = 1-log.resp(trial_counter,2);
            end
            
            %include trial or not?
            inclusion = includeOrExcludeTrial(log,trial_counter);
            
            %was this trial missed (participant failed to respond on time)?
            if isnan(response)
                fprintf(fileID,'%.2f\t%.2f\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%d\t%d\n', ...
                    log.events(event_idx,2),... %onset in seconds
                    params.display_time...
                    + params.time_to_respond + params.time_to_conf,... %trial duration
                    'missed_trial',...
                    'n/a',...
                    'n/a',...
                    task,...
                    stimulus,...
                    'n/a',...
                    'n/a',...
                    inclusion,...
                    log.uid(trial_counter));
                
            else %not a miss
                
                % figure out the trial type
                switch task
                    case 0
                        trial_type = ...
                            [dis_map(stimulus), dis_map(response)];
                    case 1
                        trial_type = ...
                            [det_map(stimulus), det_map(response)];
                    case 2
                        trial_type = ...
                            [tilt_map(stimulus), tilt_map(response)];
                end
                
                fprintf(fileID, '%.2f\t%.2f\t%s\t%.2f\t%d\t%d\t%d\t%d\t%s\t%d\t%d\n', ...
                    log.events(event_idx,2),... %onset in seconds
                    params.display_time...
                    + params.time_to_respond + params.time_to_conf,... %trial duration
                    trial_type, ...
                    log.resp(trial_counter,1), ... %RT
                    log.confidence(trial_counter),...
                    task,...
                    stimulus,...
                    response,...
                    'n/a',...
                    inclusion,...
                    log.uid(trial_counter));
            end
        else %button press
            fprintf(fileID,  '%.2f\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\n', ...
                log.events(event_idx,2),... %onset in seconds
                0,... %button press is modeled as a delta function
                'button press',...
                'n/a',...
                'n/a',...
                'n/a',...
                'n/a',...
                'n/a',...
                log.events(event_idx,1),...
                'n/a',...
                'n/a');
        end
    end
    fclose(fileID);
end

end