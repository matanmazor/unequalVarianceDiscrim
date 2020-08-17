function data_struct = loadData()
% load data from all participants and arrange in a dictionary

data_struct = containers.Map;

% load subject list
load(fullfile('..','experiment','data','subjects.mat'));
participants = readtable(fullfile('..','data','data','participants.csv'));
% subj_list = subjects.keys;
subj_list = participants.name_initials;
scanid_list = participants.participant_id;
sex_list = participants.sex;
age_list = participants.age;
hand_list = participants.hand_laterality;
mapping_list = participants.confidence_mapping;

subj_id = {};
task = {};
alpha = [];
angle_sigma = [];
orientation = [];
stimulus = [];
response = [];
accuracy = [];
confidence = [];
RT = [];
include = [];
confInc = [];
confDec = [];
block = [];
trial = [];
BOLD_rTPJ = [];
BOLD_pMFC = [];
BOLD_FPl = [];
BOLD_FPm = [];
BOLD_preSMA = [];
BOLD_vmPFC = [];

%load data
for i=1:length(subj_list) %don't analyze dummy subject 999MaMa
    
    makeEventsTSV(subj_list{i},scanid_list{i})
    
    subj = subj_list{i};
    subj_sex = sex_list{i};
    subj_age = age_list{i};
    subj_hand = hand_list{i};
    subj_mapping = mapping_list(i);
    if str2num(subj(1:2))<60
        subj_files = dir(fullfile('..','experiment','data',[subj,'_session*lite.mat']));
        if ~isempty(subj_files)
            subject_data.DisAlpha = [];
            subject_data.DetAlpha = [];
            subject_data.TiltAlpha = [];
            
            subject_data.AngleSigma = [];
            
            subject_data.DisOrientation = [];
            subject_data.DetOrientation = [];
            subject_data.TiltOrientation = [];
            
            subject_data.DisCorrect = [];
            subject_data.DetCorrect = [];
            subject_data.TiltCorrect = [];
            
            subject_data.DisConf = [];
            subject_data.DisConfInc = []; %increase confidence presses
            subject_data.DisConfDec = []; %decrease confidence presses
            subject_data.DetConf = [];
            subject_data.DetConfInc = [];
            subject_data.DetConfDec = [];
            subject_data.TiltConf = [];
            subject_data.TiltConfInc = [];
            subject_data.TiltConfDec = [];
            
            subject_data.DisResp = [];
            subject_data.DetResp = [];
            subject_data.TiltResp = [];
            
            subject_data.DisRT = [];
            subject_data.DetRT = [];
            subject_data.TiltRT = [];
            
            subject_data.vTask = [];
            
            subject_data.DetSignal = [];
            subject_data.DisSignal = [];
            subject_data.TiltSignal = [];
            
            subject_data.DetVertical = [];
            subject_data.DisVertcial = [];
            subject_data.TiltVertical = [];
            
            subject_data.DisInclude = [];
            subject_data.DetInclude = [];
            subject_data.TiltInclude = [];
            
            subject_data.DisTrial = [];
            subject_data.DetTrial = [];
            subject_data.TiltTrial = [];
            
            for j = 1:length(subj_files)
                load(fullfile('..','experiment','data',subj_files(j).name));
                num_trials = length(log.resp);
                num_blocks = num_trials/params.trialsPerBlock;
                log.confidence = log.confidence(1:num_trials);
                log.resp = log.resp(1:num_trials,:);
                log.task = log.task(1:num_trials,:);
                log.correct = log.correct(1:num_trials,:);
                log.Alpha = log.Alpha(1:num_trials);
                params.vTask = params.vTask(1:num_blocks);
                trial_events = find(log.events(:,1)==0);
                if not(length(trial_events)==78)
                    error(sprintf('wrong number of events %d',...
                        length(trial_events)))
                end
                trial_events(79) = length(log.events)+1;
                [up_count, down_count] = deal(nan(78,1));
                for i_t = 1:78
                    down_count(i_t) = sum(abs(...
                        log.events(trial_events(i_t):trial_events(i_t+1)-1,1)-55)<eps);
                    up_count(i_t) = sum(abs(...
                        log.events(trial_events(i_t):trial_events(i_t+1)-1,1)-54)<eps);
                end
                if params.conf_mapping==1
                    inc_count = up_count;
                    dec_count = down_count;
                else
                    inc_count = down_count;
                    dec_count = up_count;
                end
                
                subject_data.DisTrial = [subject_data.DisTrial; log.uid(log.task==0)];
                subject_data.DetTrial = [subject_data.DetTrial; log.uid(log.task==1)];
                subject_data.TiltTrial = [subject_data.TiltTrial; log.uid(log.task==2)];
                
                subject_data.DisAlpha = [subject_data.DisAlpha; log.Alpha(log.task==0)];
                subject_data.DetAlpha = [subject_data.DetAlpha; log.Alpha(log.task==1)];
                subject_data.AngleSigma = [subject_data.AngleSigma; params.AngleSigma*ones(size(log.Alpha(log.task==0)))];
                
                subject_data.DisCorrect = [subject_data.DisCorrect; ...
                    log.correct(log.task==0)];
                subject_data.DetCorrect = [subject_data.DetCorrect; ...
                    log.correct(log.task==1)];
                subject_data.TiltCorrect= [subject_data.TiltCorrect; ...
                    log.correct(log.task==2)];
                
                % load confidence reports (same structure)
                subject_data.DisConf = [subject_data.DisConf; ...
                    log.confidence(log.task==0)];
                subject_data.DetConf = [subject_data.DetConf; ...
                    log.confidence(log.task==1)];
                subject_data.TiltConf = [subject_data.TiltConf; ...
                    log.confidence(log.task==2)];
                
                subject_data.DisConfInc = [subject_data.DisConfInc; ...
                    inc_count(log.task==0)];
                subject_data.DetConfInc = [subject_data.DetConfInc; ...
                    inc_count(log.task==1)];
                subject_data.TiltConfInc = [subject_data.TiltConfInc; ...
                    inc_count(log.task==2)];
                
                subject_data.DisConfDec = [subject_data.DisConfDec; ...
                    dec_count(log.task==0)];
                subject_data.DetConfDec = [subject_data.DetConfDec; ...
                    dec_count(log.task==1)];
                subject_data.TiltConfDec = [subject_data.TiltConfDec; ...
                    dec_count(log.task==2)];
                subject_data.DisOrientation = [subject_data.DisOrientation; ...
                    log.orientation(log.task==0)];
                subject_data.DetOrientation = [subject_data.DetOrientation; ...
                    log.orientation(log.task==1)];
                subject_data.TiltOrientation = [subject_data.TiltOrientation; ...
                    log.orientation(log.task==2)];
                
                
                % load responses
                subject_data.DisResp = [subject_data.DisResp; ...
                    log.resp(log.task==0,2)];
                subject_data.DetResp = [subject_data.DetResp; ...
                    log.resp(log.task==1,2)];
                subject_data.TiltResp = [subject_data.TiltResp; ...
                    1-log.resp(log.task==2,2)];
                
                %load RTs
                subject_data.DisRT = [subject_data.DisRT; log.resp(log.task==0,1)];
                subject_data.DetRT = [subject_data.DetRT; log.resp(log.task==1,1)];
                subject_data.TiltRT = [subject_data.TiltRT; log.resp(log.task==2,1)];
                
                %load task order vector. 1 for detection, 0 for discrimination
                subject_data.vTask = [subject_data.vTask; params.vTask];
                
                %load trial order vector
                subject_data.DetSignal = [subject_data.DetSignal;
                    log.Alpha(log.task==1)>0];
                subject_data.DisSignal = [subject_data.DisSignal;
                    log.orientation(log.task==0)==45];
                subject_data.TiltSignal = [subject_data.TiltSignal;
                    1-params.vVertical(log.task==2)];
                
                %exclusion
                CW_conf = hist(log.confidence(log.task==0 & log.resp(:,2)==1),1:6);
                CCW_conf = hist(log.confidence(log.task==0 & log.resp(:,2)==0),1:6);
                
                Y_conf = hist(log.confidence(log.task==1 & log.resp(:,2)==1),1:6);
                N_conf = hist(log.confidence(log.task==1 & log.resp(:,2)==0),1:6);
                
                V_conf = hist(log.confidence(log.task==2 & log.resp(:,2)==1),1:6);
                T_conf = hist(log.confidence(log.task==2 & log.resp(:,2)==0),1:6);
                
                if sum(isnan(subject_data.DisCorrect(end-25:end)))<6 && ...
                        nanmean(subject_data.DisCorrect(end-25:end))>0.6 && ...
                        abs(nanmean(subject_data.DisResp(end-25:end))-0.5)<0.3 && ...
                        max(CW_conf)/sum(CW_conf)<0.9 && max(CCW_conf)/sum(CCW_conf)<0.9
                    subject_data.DisInclude = [subject_data.DisInclude; 0; ones(25,1)];
                else
                    subject_data.DisInclude = [subject_data.DisInclude; zeros(26,1)];
                end
                
                if sum(isnan(subject_data.DetCorrect(end-25:end)))<6 && ...
                        nanmean(subject_data.DetCorrect(end-25:end))>0.6 && ...
                        abs(nanmean(subject_data.DetResp(end-25:end))-0.5)<0.3 && ...
                        max(Y_conf)/sum(Y_conf)<0.9 && max(N_conf)/sum(N_conf)<0.9
                    subject_data.DetInclude = [subject_data.DetInclude; 0; ones(25,1)];
                else
                    subject_data.DetInclude = [subject_data.DetInclude; zeros(26,1)];
                end
                
                if sum(isnan(subject_data.TiltCorrect(end-25:end)))<6 && ...
                        nanmean(subject_data.TiltCorrect(end-25:end))>0.6 && ...
                        abs(nanmean(subject_data.TiltResp(end-25:end))-0.5)<0.3 && ...
                        max(T_conf)/sum(T_conf)<0.9 && max(V_conf)/sum(V_conf)<0.9
                    subject_data.TiltInclude = [subject_data.TiltInclude; 0; ones(25,1)];
                else
                    subject_data.TiltInclude = [subject_data.TiltInclude; zeros(26,1)];
                end
                
            end
            
            %compute bonus
            subject_data.bonus = ((subject_data.DetCorrect(find(~isnan(subject_data.DetConf)))-0.5)'...
                *subject_data.DetConf(find(~isnan(subject_data.DetConf)))+...
                (subject_data.DisCorrect(find(~isnan(subject_data.DisConf)))-0.5)'...
                *subject_data.DisConf(find(~isnan(subject_data.DisConf)))+...
                (subject_data.TiltCorrect(find(~isnan(subject_data.TiltConf)))-0.5)'...
                *subject_data.TiltConf(find(~isnan(subject_data.TiltConf))))/100;
            
            
            if sum(subject_data.DetInclude)>=75 && ...
                    sum(subject_data.DisInclude)>=75 && ...
                    sum(subject_data.TiltInclude)>=75
                subject_data.include = 1;
            else
                subject_data.include=0;
                subject_data.DetInclude = subject_data.DetInclude*0;
                subject_data.DisInclude = subject_data.DisInclude*0;
                subject_data.TiltInclude = subject_data.TiltInclude*0;
                
                if sum(subject_data.DetInclude)<75
                    sprintf('reason for excluding %s: detection',subj)
                end
                
                if sum(subject_data.DisInclude)<75
                    sprintf('reason for excluding %s: discrimination',subj)
                end
                
                if sum(subject_data.TiltInclude)<75
                    sprintf('reason for excluding %s: tilt',subj)
                end
            end
            
            data_struct(subj)=subject_data;
            
            
            %% update group data
            last_row = numel(subj_id);
            trials_per_task = numel(subject_data.DetInclude);
            %subject name
            subj_id(last_row+1:last_row+trials_per_task*3) = {subj};
            
            %demographics
            sex(last_row+1:last_row+trials_per_task*3) = {subj_sex};
            hand_laterality(last_row+1:last_row+trials_per_task*3) = {subj_hand};
            age(last_row+1:last_row+trials_per_task*3) = {subj_age};
            conf_mapping(last_row+1:last_row+trials_per_task*3) = {subj_mapping};
            
            %task name
            task(last_row+1:last_row+trials_per_task) = {'Discrimination'};
            task(last_row+trials_per_task+1:last_row+2*trials_per_task) = {'Detection'};
            task(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = {'Tilt'};
            
            %alpha level
            alpha(last_row+1:last_row+trials_per_task) = subject_data.DisAlpha;
            alpha(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetAlpha;
            %alpha is fixed in tilt recognition
            alpha(last_row+2*trials_per_task+1:last_row+3*trials_per_task) =  0.2*ones(size(subject_data.DisAlpha));
            
            %angle sigma (same for all tasks)
            angle_sigma(last_row+1:last_row+trials_per_task*3) = repmat(subject_data.AngleSigma,3,1);
            
            %orientation
            orientation(last_row+1:last_row+trials_per_task) = subject_data.DisOrientation;
            orientation(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetOrientation;
            orientation(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltOrientation;
            
            %stimulus
            stimulus(last_row+1:last_row+trials_per_task) = subject_data.DisSignal;
            stimulus(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetSignal;
            stimulus(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltSignal;
            
            %response
            response(last_row+1:last_row+trials_per_task) = subject_data.DisResp;
            response(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetResp;
            response(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltResp;
            
            %accuracy
            accuracy(last_row+1:last_row+trials_per_task) = subject_data.DisCorrect;
            accuracy(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetCorrect;
            accuracy(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltCorrect;
            
            %confidence
            confidence(last_row+1:last_row+trials_per_task) = subject_data.DisConf;
            confidence(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetConf;
            confidence(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltConf;
            
            %number of confidence increase button presses
            confInc(last_row+1:last_row+trials_per_task) = subject_data.DisConfInc;
            confInc(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetConfInc;
            confInc(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltConfInc;
            
            %number of confidence decrease button presses
            confDec(last_row+1:last_row+trials_per_task) = subject_data.DisConfDec;
            confDec(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetConfDec;
            confDec(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltConfDec;
            
            %RT
            RT(last_row+1:last_row+trials_per_task) = subject_data.DisRT;
            RT(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetRT;
            RT(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltRT;
            
            %inclusion
            include(last_row+1:last_row+trials_per_task) = subject_data.DisInclude;
            include(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetInclude;
            include(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltInclude;
            
            %trial
            trial(last_row+1:last_row+trials_per_task) = subject_data.DisTrial;
            trial(last_row+trials_per_task+1:last_row+2*trials_per_task) = subject_data.DetTrial;
            trial(last_row+2*trials_per_task+1:last_row+3*trials_per_task) = subject_data.TiltTrial;
            
            %block
            num_blocks = trials_per_task/26;
            block_mat = repmat(1:num_blocks,26,3);
            block(last_row+1:last_row+trials_per_task*3) = block_mat(:);
            
            scanid = scanid_list{i};
            rTPJ_file_path = fullfile('..\analyzed\DM200', scanid,'rTPJ.mat');
            
            if subject_data.include & exist(rTPJ_file_path,'file')
                
                rTPJ = load(fullfile('..\analyzed\DM200', scanid,'rTPJ.mat'));
                vmPFC = load(fullfile('..\analyzed\DM200', scanid,'vmPFC.mat'));
                pMFC = load(fullfile('..\analyzed\DM200', scanid,'pMFC.mat'));
                FPl = load(fullfile('..\analyzed\DM200', scanid,'FPl.mat'));
                FPm = load(fullfile('..\analyzed\DM200', scanid,'FPm.mat'));
                preSMA = load(fullfile('..\analyzed\DM200', scanid,'preSMA.mat'));
                
                id_mat = [rTPJ.id; vmPFC.id; pMFC.id; FPl.id; FPm.id; preSMA.id];
                if mean(var(id_mat))>0
                    error('id vectors don''t match')
                end
                
                conf_mat = [rTPJ.confidence_vec; vmPFC.confidence_vec; 
                    pMFC.confidence_vec; FPl.confidence_vec; 
                    FPm.confidence_vec; preSMA.confidence_vec];
                if mean(var(conf_mat))>0
                    error('confidence vectors don''t match')
                end
                
                for i = last_row:last_row+3*trials_per_task
                    if ismember(trial(i), rTPJ.id)
                        trial_number = find(rTPJ.id==trial(i));
                        if confidence(i)~=rTPJ.confidence_vec(trial_number)
                            error('confidence ratings don''t match')
                        else
                            BOLD_rTPJ(i)= rTPJ.mean_beta_vec(trial_number);
                            BOLD_pMFC(i) = pMFC.mean_beta_vec(trial_number);
                            BOLD_FPl(i) = FPl.mean_beta_vec(trial_number);
                            BOLD_FPm(i) = FPm.mean_beta_vec(trial_number);
                            BOLD_preSMA(i) = preSMA.mean_beta_vec(trial_number);
                            BOLD_vmPFC(i) = vmPFC.mean_beta_vec(trial_number);
                        end
                    else
                        BOLD_rTPJ(i)=nan;
                        BOLD_pMFC(i) = nan;
                        BOLD_FPl(i) = nan;
                        BOLD_FPm(i) = nan;
                        BOLD_preSMA(i) = nan;
                        BOLD_vmPFC(i) = nan;
                    end
                end
            else
                BOLD_rTPJ(last_row+1:last_row+trials_per_task*3)=nan;
                BOLD_pMFC(last_row+1:last_row+trials_per_task*3) = nan;
                BOLD_FPl(last_row+1:last_row+trials_per_task*3) = nan;
                BOLD_FPm(last_row+1:last_row+trials_per_task*3) = nan;
                BOLD_preSMA(last_row+1:last_row+trials_per_task*3) = nan;
                BOLD_vmPFC(last_row+1:last_row+trials_per_task*3) = nan;
            end
        end
    end
end
subj_id = subj_id';
age=age';
sex = sex';
conf_mapping = conf_mapping';
hand_laterality = hand_laterality';
task = task';
alpha = alpha';
angle_sigma = angle_sigma';
orientation = orientation';
stimulus = stimulus';
accuracy = accuracy';
confidence = confidence';
response = response';
response_time = RT';
inclusion = include';
increase_presses = confInc';
decrease_presses = confDec';
block = block';
trial=trial';
BOLD_rTPJ = BOLD_rTPJ';
BOLD_pMFC = BOLD_pMFC';
BOLD_FPm = BOLD_FPm';
BOLD_FPl = BOLD_FPl';
BOLD_vmPFC = BOLD_vmPFC';
BOLD_preSMA = BOLD_preSMA';

T = table(subj_id,sex,age,hand_laterality,conf_mapping,...
    inclusion,block,trial,task,alpha,angle_sigma,...
    orientation, stimulus, response, accuracy, response_time, confidence, ...
    increase_presses, decrease_presses, BOLD_rTPJ, BOLD_pMFC, BOLD_FPm,...
    BOLD_FPl, BOLD_preSMA, BOLD_vmPFC);
writetable(T,fullfile('..','experiment','data','data.csv'))
end
