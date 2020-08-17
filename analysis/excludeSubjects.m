clear;
clc;

%% 1. LOAD DATA
data_struct = loadData();
subjects = data_struct.keys;

participants = readtable('D:\Documents\projects\inProgress\unequalVarianceDiscrim\data\data\participants.csv');

toExclude = ones(length(subjects),6);
toExcludeFromConfAnalyses = ones(length(subjects),6);

%% 2. Exclude

for s = 1:length(subjects)
    
    subject = data_struct(subjects{s});
    
    for run_num = 1:length(subject.DisRT)/26
        
        if any([subject.DisInclude((run_num-1)*26+2),...
                subject.DetInclude((run_num-1)*26+2),...
                subject.TiltInclude((run_num-1)*26+2)])
            toExcludeFromConfAnalyses(s,run_num)=0;
            toExclude(s,run_num)=0;
        end
        
    end
    
    
% 3. save exclusion files in participant's directory
subject_id = participants.participant_id(...
    strcmp(strtrim(participants.name_initials),subjects{s}));
func_dir = fullfile('D:\Documents\projects\inProgress\unequalVarianceDiscrim\data\pp_data\',...
    strtrim(subject_id{1}),'func'); 


fid = fopen( fullfile(func_dir,'exclusion.txt'), 'wt' );
fprintf( fid, '%d,%d,%d,%d,%d,%d', toExclude(s,1), toExclude(s,2),...
                    toExclude(s,3),toExclude(s,4), toExclude(s,5),...
                    toExclude(s,6));
fclose(fid);

fid = fopen( fullfile(func_dir,'conf_exclusion.txt'), 'wt' );
fprintf( fid, '%d,%d,%d,%d,%d,%d', toExcludeFromConfAnalyses(s,1),...
                                toExcludeFromConfAnalyses(s,2),...
                                toExcludeFromConfAnalyses(s,3),...
                                toExcludeFromConfAnalyses(s,4),...
                                toExcludeFromConfAnalyses(s,5),...
                                toExcludeFromConfAnalyses(s,6));
fclose(fid);
good_ss = find(sum(toExclude'==0)>2);
end


