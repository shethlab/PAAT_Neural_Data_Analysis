clear all;
close all;
%combine_tf_data
pt = 'P011';
files = ['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt];
pt_files = dir(fullfile(files));
combined_approachful_L = [];
combined_avoidant_L = [];
combined_approachful_R = [];
combined_avoidant_R = [];
combined_reward_L = [] ;
combined_negative_L = [] ;
combined_reward_R = [] ; 
combined_negative_R = [] ;
for file=1:length(pt_files)
    if contains(pt_files(file).name,'1.mat')
        disp(pt_files(file).name)
        tf_data_file = fullfile(pt_files(file).folder,pt_files(file).name);
        load(tf_data_file,'approachful_LFP');
        load(tf_data_file,'avoidant_LFP');
        % load(tf_data_file,'reward_LFP');
        % load(tf_data_file,'negative_stimuli_LFP');        
        combined_approachful_L = [combined_approachful_L;approachful_LFP];
        combined_avoidant_L = [combined_avoidant_L;avoidant_LFP];
        % combined_reward_L = [combined_reward_L;reward_LFP] ;
        % combined_negative_L = [combined_negative_L;negative_stimuli_LFP] ;
    end
    if contains(pt_files(file).name,'2.mat')
        tf_data_file = fullfile(pt_files(file).folder,pt_files(file).name);
        load(tf_data_file,'approachful_LFP');
        load(tf_data_file,'avoidant_LFP');
        % load(tf_data_file,'reward_LFP');
        % load(tf_data_file,'negative_stimuli_LFP');  
        combined_approachful_R = [combined_approachful_R;approachful_LFP];
        combined_avoidant_R = [combined_avoidant_R;avoidant_LFP]; 
        % combined_reward_R = [combined_reward_R;reward_LFP] ;
        % combined_negative_R = [combined_negative_R;negative_stimuli_LFP] ;
    end
end
patient = pt;
sfreq=250;
chan_L = [pt,': Combined Left Decision'];
chan_R = [pt,': Combined Right Decision'];

time = linspace(-6,3,sfreq*9);
plot_spectrograms(combined_approachful_L,combined_avoidant_L,time,chan_L,pt,[])
bandpassed_LFP(combined_approachful_L,combined_avoidant_L,time,chan_L,pt,[])
plot_spectrograms(combined_approachful_R,combined_avoidant_R,time,chan_R,pt,[])
bandpassed_LFP(combined_approachful_R,combined_avoidant_R,time,chan_R,pt,[])

% chan_L = [pt,':Combined Left Stimulus'];
% chan_R = [pt,':Combined Right Stimulus'];
% 
% time = linspace(-2,5,sfreq*7);
% plot_spectrograms(combined_reward_L,combined_negative_L,time,chan_L,patient,[])
% bandpassed_LFP(combined_reward_L,combined_negative_L,time,chan_L,patient,[])
% plot_spectrograms(combined_reward_R,combined_negative_R,time,chan_R,patient,[])
% bandpassed_LFP(combined_reward_R,combined_negative_R,time,chan_R,patient,[])