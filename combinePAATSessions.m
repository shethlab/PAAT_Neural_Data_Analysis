date_path = 'C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\';
data_path = [date_path 'processed\'];

% % % NON RESPONDER DATA
% subjects = ["P010","P011","aDBS012","P014","P017","P019"]; %"P06",
% dates = {["2024-01-03","2024-01-11"],["2024-01-04"],["2023-12-18"],["2024-08-15"],["2024-08-12"],["2024-08-13"]}; %
% file_name = [data_path 'PAAT_combined_dataTable_non_responder.csv'];

% RESPONDER DATA (P011 2024-01-18 is remitter) aDBS010 is remitter
% subjects = ["P004","P011","P012","aDBS010","aDBS011","P015","P018","P020"];
% dates = {["2024-04-02"],["2024-01-18"],["2024-02-26"],["2024-02-27","2024-06-27"],["2023-12-20"],["2024-08-14"],["2024-06-27"],["2024-08-19"]};
% file_name = [data_path 'PAAT_combined_dataTable_responder.csv'];

%Disinhibited DATA (P013)
% subjects = ["P013"];
% dates = {["2024-03-14","2024-04-11","2024-07-18"]};
% file_name = [data_path 'PAAT_combined_dataTable_disinhibited.csv'];
subjects = ["DBSOCD001"];
dates = {"2025-02-11"};
% PD patients
% subjects = ["NIN004","NIN006","NIN007"];
% dates = {["2024-08-20"],["2024-10-30"],["2024-10-11"]};
% file_name = [data_path 'PAAT_combined_dataTable_PD.csv'];

%ALL DATA
% subjects = ["P004","P006","P010","P011","P012","P013","aDBS010","aDBS011","aDBS012"];
% dates = {["2024-04-02"],["2024-01-18"],["2024-01-03","2024-01-11"],["2024-01-04","2024-01-18"],["2024-02-26"],["2024-03-14","2024-04-11","2024-07-18"],["2024-02-27","2024-06-27"],["2023-12-20"],["2023-12-18"]};
% file_name = [data_path 'PAAT_combined_dataTable_all.csv'];

sesion_total_award = cell(1,11);
full_data_table = table();
count = 1;
n_count = 0;
all_count =0;
for i = 1:length(subjects)
    disp(subjects(i))
    for j = 1:length(dates{i})
        disp(dates{i}(j))
        all_count = all_count+1;
        clear results resultsTable p
        data_file = dir(strcat(date_path,subjects(i),'\',dates{i}(j),'\PAAT_',subjects(i),'*.mat'));
        
        disp([data_file.folder, '\', data_file.name])
        load([data_file.folder, '\', data_file.name])

        resultsTable = table();
        resultsTable.SubID = repmat(subjects(i), length(results.trial),1);
        resultsTable.Session = repelem(1:6, length(results.trial)/6)';
        resultsTable.Block = results.block;
        resultsTable.Trial = results.trial;
        resultsTable.PosProb1 = results.posProb1;
        resultsTable.PosProb2 = results.posProb2;
        resultsTable.NegProb1 = results.negProb1;
        resultsTable.NegProb2 = results.negProb2;
        resultsTable.Choice = results.choiceResp;
        resultsTable.ChoiceString = results.choiceStr;
        resultsTable.ChoiceRT = results.choiceRT;
        resultsTable.Outcome = results.outcome;
        resultsTable.OutcomeCode = results.outcomeStr;
        resultsTable.ImgShown = results.imgShown;
        resultsTable.Reward = results.reward;
        
        resultsTable.Date = repmat(dates{i}(j), length(results.trial),1);
        resultsTable.OnsetFixationTimes = results.timing.absolute.onsetFixation;
        resultsTable.TrialInBlock = results.trialInBlock;
        resultsTable.Loss = results.loss;
        resultsTable.MaxPosProb = results.maxPosProb;
        resultsTable.MaxNegProb = results.maxNegProb;
        resultsTable.MinPosProb = results.minPosProb;
        resultsTable.MinNegProb = results.minNegProb;
        resultsTable.RelPosProb = results.relPosProb;
        resultsTable.RelNegProb = results.relNegProb;
        resultsTable.MeanPosProb = results.meanRewProbs;
        resultsTable.MeanNegProb = results.meanAversProbs;

        resultsTable = movevars(resultsTable,"Session",'Before',"SubID");
        resultsTable = movevars(resultsTable,"Date",'After',"Session");
        resultsTable = movevars(resultsTable,"TrialInBlock",'After',"Trial");


        
        % sesion_total_award{count} = [sesion_total_award{count}, sum(resultsTable.Reward,"omitnan")];
        % mon_neut_trial_count = sum(strcmp(resultsTable.ImgShown,'monetary_neutral'));
        % mon_reward_trial_count = sum(strcmp(resultsTable.ImgShown,'monetary_reward'));
        % disp(sum(resultsTable.Reward==.5));
%         disp(['Number of Trials that gave a  Reward: ' num2str(mon_reward_trial_count/(mon_neut_trial_count+mon_reward_trial_count))])
%         disp(['Number of Trials Potential Reward: ' num2str(mon_neut_trial_count+mon_reward_trial_count)])
      

        full_data_table = [full_data_table;resultsTable];
        
        relNegProb_RvL = round(10*(resultsTable.NegProb2 - resultsTable.NegProb1));
        relPosProb_RvL = round(10*(resultsTable.PosProb2 - resultsTable.PosProb1));
        nan_mask = isnan(resultsTable.NegProb1);
        arePosNegAligned = sign(relNegProb_RvL) == sign(relPosProb_RvL);
        resultsTable_LowConflictOnly = resultsTable(~(arePosNegAligned | nan_mask),:);
        low_conflict_count = sum(~(arePosNegAligned | nan_mask));
        high_conflict_count = sum(arePosNegAligned);
        fc_trial_count = sum(nan_mask);
        total_trials = fc_trial_count + high_conflict_count + low_conflict_count;
        mask_left_option_is_best = resultsTable_LowConflictOnly.PosProb1 > resultsTable_LowConflictOnly.PosProb2;
        mask_selected_left_option = resultsTable_LowConflictOnly.Choice == 1;
        precent_low_conflict_correct = sum(mask_left_option_is_best == mask_selected_left_option)/length(mask_left_option_is_best);
        count = count+1;
        disp(['Count:  High = ' num2str(high_conflict_count) ', Low : ' num2str(low_conflict_count) ', FC : ' num2str(fc_trial_count) ', Total : ' num2str(total_trials)]);
        disp(['Ratio:  High = ' num2str(high_conflict_count/total_trials) ', Low : ' num2str(low_conflict_count/total_trials) ', FC : ' num2str(fc_trial_count/total_trials) ', Total : ' num2str(total_trials/total_trials)]);
        disp(['Accuracy:  High = ' num2str(NaN) ', Low : ' num2str(precent_low_conflict_correct) ', FC : ' num2str(NaN) ', Total : ' num2str(NaN)]);
        disp(['Highconlict: ' num2str(sum(arePosNegAligned)/height(resultsTable)) ' Low conflcit: ' num2str(sum(~arePosNegAligned)/height(resultsTable))]);
        disp(['Percent Of Low Conflict Trials Done Correctly: ' num2str(precent_low_conflict_correct)])
        if precent_low_conflict_correct < .5
            disp('Nope.')
            continue;
        end
       
        n_count = n_count+1;
        local_file_name = [data_path 'single_session/PAAT_combined_dataTable_' char(subjects(i)) '_' char(dates{i}(j)) '.csv'];
        writetable(resultsTable, local_file_name)
    end  
end
disp(n_count)
disp(all_count)
disp(['Saved to: ',local_file_name])
% writetable(full_data_table, file_name)