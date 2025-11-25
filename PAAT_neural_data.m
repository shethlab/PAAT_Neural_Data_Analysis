%% Load aDBS, Percept, and NIH data
clear all;
close all;

pt_cohort='Percept';
pt = '011';
files = ['C:\Users\matth\OneDrive\BCM\PAAT Analysis\preprocessed\',pt];

[preprocessed_file,location] = uigetfile({'*.mat'},'Select a preprocessed file',files);
toggle_file = [location preprocessed_file];
current_date = extractBetween(location,[pt '\'],'\PAAT');
current_date = current_date{1};
[approachful_LFP_epochs,avoidant_LFP_epochs,low_conflict_LFP_epochs]=percept_toggle(toggle_file,pt,current_date);
%iterate for each channel
channels = {[pt_cohort,' ',pt,': Left Hem Decision'],[pt_cohort,' ',pt,': Right Hem Decision']};
channels2 = {[pt_cohort,' ',pt,': Left Hem Low Conflict'],[pt_cohort,' ',pt,': Right Hem Low Conflict']};
for x = 1:size(approachful_LFP_epochs,3) %third axis is each channel          
   %Time-frequency decomposition
   approachful_LFP = morlet_wavelet_convolution(squeeze(approachful_LFP_epochs(:,:,x)),250);
   avoidant_LFP = morlet_wavelet_convolution(squeeze(avoidant_LFP_epochs(:,:,x)),250);
   reward_LFP = morlet_wavelet_convolution(squeeze(low_conflict_LFP_epochs(:,:,x)),250);
   
   %save time-frequency data to combine dates later
   % if contains(pt,'DBSOCD')
   %     save(['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',current_date,'_tfdata_',num2str(x),'.mat'],'approachful_LFP','avoidant_LFP','reward_LFP','negative_stimuli_LFP')
   % else
   %     save(['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\P',pt,'\',current_date,'_tfdata_',num2str(x),'.mat'],'approachful_LFP','avoidant_LFP','reward_LFP','negative_stimuli_LFP')
   % end

   %plot spectrograms for approach/avoidance
   time = linspace(-6,3,250*9);
   % plot_spectrograms(approachful_LFP,avoidant_LFP,time,channels{x},pt,current_date)
   % bandpassed_LFP(approachful_LFP,avoidant_LFP,time,channels{x},pt,current_date)
   
   %plot spectrograms for low conflict rewarding and high conflict
   %rewarding
   plot_spectrograms(approachful_LFP,reward_LFP,time,channels2{x},pt,current_date)
   bandpassed_LFP(approachful_LFP,reward_LFP,time,channels2{x},pt,current_date)   
end


% for date=1:length(files)
%     %Access all preprocessed dates for pt
%     current_date=files(date).name;
%     current_folder=files(date).folder;
%     if ~contains(current_date,'.')
%         %make sure all folders are task dates
%         date_path=dir(fullfile(current_folder,current_date));
%         for task=1:length(date_path)
%             %iterate through each task date
%             if contains(date_path(task).name,'PAAT')
%                 %make sure each date has a PAAT task
%                 task_files=dir(fullfile(date_path(task).folder,date_path(task).name));
%                 task_file_names={task_files.name};
%                 toggle_ind = find(contains(task_file_names,'.mat'));
%                 behav_ind = find(contains(task_file_names,'synced_behav'));
%                 if isempty(toggle_ind)
%                     %If no toggle_sync, used lfp_synced file
%                     lfp_ind=find(contains(task_file_names,'lfp'));
%                     lfp_file=fullfile(task_files(lfp_ind).folder,task_files(lfp_ind).name);
%                     percept_no_toggle(lfp_file)
%                 else
%                     for tog=1:length(toggle_ind)
%                         toggle_file=fullfile(task_files(toggle_ind(tog)).folder,task_files(toggle_ind(tog)).name);
%                         [approachful_LFP_epochs,avoidant_LFP_epochs]=percept_toggle(toggle_file,pt,current_date);
%                         %iterate for each channel
%                         channels = {[pt_cohort,' ',pt,': Left Hem'],[pt_cohort,' ',pt,': Right Hem']};
%                         for x = 1:size(approachful_LFP_epochs,3) %third axis is each channel          
%                            %Time-frequency decomposition
%                            approachful_LFP = morlet_wavelet_convolution(squeeze(approachful_LFP_epochs(:,:,x)),250);
%                            avoidant_LFP = morlet_wavelet_convolution(squeeze(avoidant_LFP_epochs(:,:,x)),250);
%                            %plot spectrograms and save
%                            plot_spectrograms(approachful_LFP,avoidant_LFP,channels{x},pt,current_date)
%                            bandpassed_LFP(approachful_LFP,avoidant_LFP,channels{x},pt,current_date)
%                         end
%                     end
%                 end
% 
%              end
%          end
%      end
% 
% end