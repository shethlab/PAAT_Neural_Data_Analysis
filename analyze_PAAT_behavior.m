close all; clear all;

path_to_file = matlab.desktop.editor.getActiveFilename;
path_to_dir = 'C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\processed\';
figure_path = [path_to_dir 'figures\'];
all_fits = {};
patient_group = ["P015_2024-08-14"];
pt=extractBefore(patient_group,'_');
date=extractAfter(patient_group,'_');
% ["NIN004_2024-08-20","NIN006_2024-10-30","NIN007_2024-10-11"];
% ["aDBS010_2024-02-27","aDBS010_2024-06-27","aDBS011_2023-12-20",... ["non_responder","responder","disinhibited"];
% "aDBS012_2023-12-18","P004_2024-04-02","P010_2024-01-03","P010_2024-01-11",...
% "P011_2024-01-04","P011_2024-01-18","P012_2024-02-26","P013_2024-03-14",...
% "P013_2024-07-18","P014_2024-08-15","P015_2024-08-14","P017_2024-08-12","P018_2024-06-27","P020_2024-08-19"];

for count = 1:length(patient_group)
    current_pt=patient_group(count);
    current_pt=strcat(extractBefore(current_pt,'_'),'-',extractAfter(current_pt,'_'));
    reponse_type = '';
    file_path = fullfile(path_to_dir, 'single_session', ['PAAT_combined_dataTable_' char(patient_group(count)) '.csv']);
    resultsTable = readtable(file_path);
    
    patient_group_string = char(patient_group(count));
    patient_group_string(patient_group_string == '_') = ' ';
    
    %% Organize NonResponder Data
    % timePoint: 1-3
    resultsTable.timePoint = ordinal(resultsTable.Session,{'1','2','3'},[],[0 2.5 4.5 6.5]);
    resultsTable.timePoint = discretize(resultsTable.Session,[0 2.5 4.5 6.5],'categorical',{'1', '2', '3'});
    resultsTable.timePointContin = resultsTable.Session;
    resultsTable.timePointContin(resultsTable.Session==1 | resultsTable.Session==2) = -1;
    resultsTable.timePointContin(resultsTable.Session==3 | resultsTable.Session==4) = 0;
    resultsTable.timePointContin(resultsTable.Session==5 | resultsTable.Session==6) = 1;
    
    % sessionHalf: 1 or 2
    resultsTable.sessionHalf = nominal((mod(resultsTable.Session,2)==0)+1);
    resultsTable.ChoseRight = resultsTable.Choice==2;
    resultsTable.ChoseRight = double(resultsTable.ChoseRight);
    resultsTable.ChoseRight(isnan(resultsTable.ChoiceRT),:) = nan;
    resultsTable.logChoiceRT = log(resultsTable.ChoiceRT);
    
    % Code forced-choice trials
    resultsTable.isForcedChoice = zeros(size(resultsTable,1),1);
    resultsTable.isForcedChoice(isnan(resultsTable.PosProb1) | isnan(resultsTable.PosProb2)) = 1;
    resultsTable_wForcedChoice = resultsTable;
    % Cuting out any forced-choice trials:
    resultsTable = resultsTable(resultsTable.isForcedChoice == 0,:);
    
    % Relative negative and positive probabilities per trial
    resultsTable.relNegProb_RvL = round(10*(resultsTable.NegProb2 - resultsTable.NegProb1));
    resultsTable.relPosProb_RvL = round(10*(resultsTable.PosProb2 - resultsTable.PosProb1));
    resultsTable.absRelNegProb_RvL = abs(resultsTable.relNegProb_RvL);
    resultsTable.absRelPosProb_RvL = abs(resultsTable.relPosProb_RvL);
    
    %%%%%6/23 FIXES TO CORRECT FOR IMPLEMENTED TRIAL DISTRIBUTION:
    % Which option is "safer" (lower prob of negative outcome)
    resultsTable.isRoption_safer_fixed0623 = ...
        (resultsTable.relNegProb_RvL<0); 
    
    % Was the safer (lower prob negative) option chosen (with extra code to deal with nan choice trials)?
    resultsTable.ChoseSafer_fixed0623 = nan(length(resultsTable.ChoseRight),1);
    resultsTable.ChoseSafer_fixed0623(resultsTable.isRoption_safer_fixed0623 & resultsTable.ChoseRight==1) = 1;
    resultsTable.ChoseSafer_fixed0623(~resultsTable.isRoption_safer_fixed0623 & resultsTable.ChoseRight==0) = 1;
    resultsTable.ChoseSafer_fixed0623(~resultsTable.isRoption_safer_fixed0623 & resultsTable.ChoseRight==1) = 0;
    resultsTable.ChoseSafer_fixed0623(resultsTable.isRoption_safer_fixed0623 & resultsTable.ChoseRight==0) = 0;
    
    % How much lower of a probability is the negative outcome for the safer option?
    resultsTable.relNegProb_safe_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.relNegProb_RvL + ...
        -1*resultsTable.relNegProb_RvL.*(~resultsTable.isRoption_safer_fixed0623);
    
    % How much lower of a probability is the positive outcome for the safer option?
    resultsTable.relPosProb_safe_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.relPosProb_RvL + ...
        ~resultsTable.isRoption_safer_fixed0623.*(-1*resultsTable.relPosProb_RvL);
    
    % Safer/riskier neg prob coding is identical to previous min/max:
    resultsTable.NegProb_safer_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.NegProb2 + ...
        ~resultsTable.isRoption_safer_fixed0623.*resultsTable.NegProb1;
    resultsTable.NegProb_riskier_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.NegProb1 + ...
        ~resultsTable.isRoption_safer_fixed0623.*resultsTable.NegProb2;
    resultsTable.PosProb_safer_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.PosProb2 + ...
        ~resultsTable.isRoption_safer_fixed0623.*resultsTable.PosProb1;
    resultsTable.PosProb_riskier_fixed0623 = ...
        resultsTable.isRoption_safer_fixed0623.*resultsTable.PosProb1 + ...
        ~resultsTable.isRoption_safer_fixed0623.*resultsTable.PosProb2;
    
    % Choices where both pos and neg outcomes point in the same direction, creating higher approach-avoid conflict (as intended):
    resultsTable.arePosNegAligned = ...
        sign(resultsTable.relNegProb_RvL) == sign(resultsTable.relPosProb_RvL);
    
    
    %%Mean-center ([s]caled) regressions inputs
    resultsTable.s_NegProb1 = resultsTable.NegProb1 - nanmean(resultsTable.NegProb1);
    resultsTable.s_NegProb2 = resultsTable.NegProb2 - nanmean(resultsTable.NegProb2);
    resultsTable.s_PosProb1 = resultsTable.PosProb1 - nanmean(resultsTable.PosProb1);
    resultsTable.s_PosProb2 = resultsTable.PosProb2 - nanmean(resultsTable.PosProb2);
    resultsTable.s_relNegProb_RvL = resultsTable.relNegProb_RvL - nanmean(resultsTable.relNegProb_RvL);
    resultsTable.s_relPosProb_RvL = resultsTable.relPosProb_RvL - nanmean(resultsTable.relPosProb_RvL);
    resultsTable.s_absRelNegProb_RvL = resultsTable.absRelNegProb_RvL - nanmean(resultsTable.absRelNegProb_RvL);
    resultsTable.s_absRelPosProb_RvL = resultsTable.absRelPosProb_RvL - nanmean(resultsTable.absRelPosProb_RvL);
    
    resultsTable.s_relNegProb_safe_fixed0623 = resultsTable.relNegProb_safe_fixed0623 - nanmean(resultsTable.relNegProb_safe_fixed0623);
    resultsTable.s_relPosProb_safe_fixed0623 = resultsTable.relPosProb_safe_fixed0623 - nanmean(resultsTable.relPosProb_safe_fixed0623);
    
    resultsTable.s_NegProb_safer_fixed0623 = resultsTable.NegProb_safer_fixed0623 - nanmean(resultsTable.NegProb_safer_fixed0623);
    resultsTable.s_NegProb_riskier_fixed0623 = resultsTable.NegProb_riskier_fixed0623 - nanmean(resultsTable.NegProb_riskier_fixed0623);
    resultsTable.s_PosProb_safer_fixed0623 = resultsTable.PosProb_safer_fixed0623 - nanmean(resultsTable.PosProb_safer_fixed0623);
    resultsTable.s_PosProb_riskier_fixed0623 = resultsTable.PosProb_riskier_fixed0623 - nanmean(resultsTable.PosProb_riskier_fixed0623);
    
    %%Creating new table with only congruent trials
    % Subsetted table with only trials like those intended (risky = more positive)
    resultsTable_AlignedTrialsOnly = resultsTable(resultsTable.arePosNegAligned,:);
    
    
    
    %% Probs of picking each possible option (Plotting Starts Here):
    load([path_to_dir 'empty_table.mat'])
    
    my_table = resultsTable;
    my_table(isnan(table2array(my_table(:,11))),:) = [];
    
    tmp_all_options_list = [[table2array(my_table(my_table.Choice == 1,[7,9])),ones(length(table2array(my_table(my_table.Choice == 1,[7,9]))),1)];...
        [table2array(my_table(my_table.Choice == 1,[8,10])),zeros(length(table2array(my_table(my_table.Choice == 1,[8,10]))),1)];...
        [table2array(my_table(my_table.Choice == 2,[7,9])),zeros(length(table2array(my_table(my_table.Choice == 2,[7,9]))),1)];...
        [table2array(my_table(my_table.Choice == 2,[8,10])),ones(length(table2array(my_table(my_table.Choice == 2,[8,10]))),1)]];
    all_options_list = table;
    all_options_list.PosProb = tmp_all_options_list(:,1);
    all_options_list.NegProb = tmp_all_options_list(:,2);
    total_count_of_each_option = grpstats(all_options_list,{'PosProb','NegProb'});
    options_not_offered = total_count_of_each_option(total_count_of_each_option.GroupCount == 0,:);
    if ~isempty(options_not_offered)
        disp(options_not_offered)
    end
    choice_mask = table2array(my_table(:,11)) == 1;
    tmp_chosen_options = [table2array(my_table(choice_mask,[7,9]));table2array(my_table(~choice_mask,[8,10]))];
    chosen_options = table;
    chosen_options.PosProb = tmp_chosen_options(:,1);
    chosen_options.NegProb = tmp_chosen_options(:,2);
    total_count_of_chosen_options = grpstats(chosen_options,{'PosProb','NegProb'});
    if height(total_count_of_chosen_options) ~=25
        tmp = empty_count_table;
        row_names = total_count_of_chosen_options.Properties.RowNames;
        for i = 1:height(total_count_of_chosen_options)
            tmp{row_names{i},3} = total_count_of_chosen_options{row_names{i},3};
        end
        total_count_of_chosen_options = tmp;
    end
    
    prob_of_selecting_option = table2array(total_count_of_chosen_options(:,3)) ./ table2array(total_count_of_each_option(:,3));
    sd_of_selecting_option = 1 ./ sqrt(table2array(total_count_of_each_option(:,3)));
     
    % 
    xAxis = {'10','30', '50', '70', '90'};
    yAxis = {'10','30', '50', '70', '90'};
    xAxisLabel = {'Reward Value'};
    yAxisLabel = {'Aversive Value'};
    
    figure(count);
    %a1 = `(1,2,1);
    data = reshape(prob_of_selecting_option,[5 5]);
    % savedata(patient_group(count)) = data;
    avgChoice_allSessions = flipud(data);
    colormap();
    [nr,nc] = size(data);
    padded = [data nan(nr,1); nan(1,nc+1)];
    i = pcolor(padded);
    c = colorbar; %axis([0 1]);
    xticks([1.5 2.5 3.5 4.5 5.5]); xticklabels(xAxis);
    yticks([1.5 2.5 3.5 4.5 5.5]); yticklabels(yAxis);
    caxis([0 1]);
    % set(gca,'fontsize',24)
    % set(gcf, 'Position',  [0 1000 700 600])
    % 
    x = repmat(.1:.2:.9,1,5)';
    y = repelem(.1:.2:.9,1,5)';
    z = reshape(prob_of_selecting_option.',1,[])';
    sf = fit([x,y],z,'poly11');
    intervals = confint(sf,0.95);
    not_sig_slope_diff_from_0_mask = intervals(1,:).*intervals(2,:) < 0;
    z_aversion(count) = sf.p10;
    z_reward(count) = sf.p01;
    angle(count) =  atand(z_aversion(count)/z_reward(count));%atand(R_aversion/R_reward);
    mag(count) = sqrt(z_aversion(count)^2+z_reward(count)^2);
    current_patient = strrep(current_pt,'-',' ');
    title([current_patient,'Magnitude=',num2str(mag),'Angle=',num2str(angle)]); xlabel(xAxisLabel); ylabel(yAxisLabel);c.Label.String = 'Probability of Selecting Option';
    saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt{1},'\',date{1},'\Behavioral_Grid.png'])
    saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt{1},'\',date{1},'\Behavioral_Grid.svg'])
    
    % if not_sig_slope_diff_from_0_mask(2)
    %     z_aversion(count) = 0;
    % else
    %     z_aversion(count) = sf.p10;
    % end
    % if not_sig_slope_diff_from_0_mask(3)
    %     z_reward(count) = 0;
    % else
    %     z_reward(count) = sf.p01;
    % end
    % if not_sig_slope_diff_from_0_mask(2) && not_sig_slope_diff_from_0_mask(3)
    %     z_aversion(count) = sf.p10;
    %     z_reward(count) = sf.p01;
    % end

    
    disp(['Z_Aversion: ' num2str(z_aversion(count)) '  ' 'Z_Reward: ' num2str(z_reward(count)) '  ' 'Z_Aver / Z_Rew: ' num2str(z_aversion(count)/z_reward(count)) '  ' 'Angle ' num2str(angle(count))])
    z_aversion(count) = sf.p10;
    z_reward(count) = sf.p01;
    % y=data;
    % x1 = [.1 .3 .5 .7 .9];
    % % aversion
    % aversion_all = [];
    % reward_all = [];
    % x_all = [];
    % 
    % for i = 1:5
    %     x_all = [x_all,x1];
    %     aversion_all = [aversion_all;y(:,i)];
    %     reward_all = [reward_all,y(i,:)];
    % end
    % z_aversion(count) = fitlm(aversion_all,x_all).Coefficients.Estimate(2,1);
    % z_reward(count) = fitlm(reward_all,x_all).Coefficients.Estimate(2,1);
    % 
    % R_reward1  = corrcoef(reward_all,x_all');
    % R_reward(count)  = R_reward1(1,2);
    % R_aversion1  = corrcoef(aversion_all,x_all');
    % R_aversion(count)  = R_aversion1(1,2);
    % angle(count) =  atand(z_aversion(count)/z_reward(count));%atand(R_aversion/R_reward);
    % % angle_degrees(count) = angle*(180/pi);
    % mag(count) = sqrt(z_aversion(count)^2+z_reward(count)^2);
    

end
    


% %%
%     figure;
%     subplot(1,4,1);hold on;
%     mask_non = patient_group_num==1; mask_res = patient_group_num==2; mask_dis = patient_group_num==3;
%     boxchart(patient_group_num(mask_non),z_reward(mask_non),'BoxFaceColor',[0 0.4470 0.7410],'LineWidth',5); swarmchart(patient_group_num(mask_non),z_reward(mask_non),60,'black','filled','XJitterWidth',.5);
%     boxchart(patient_group_num(mask_res),z_reward(mask_res),'BoxFaceColor',[0.8500 0.3250 0.0980],'LineWidth',5); swarmchart(patient_group_num(mask_res),z_reward(mask_res),60,'black','filled','XJitterWidth',.5);
%     boxchart(patient_group_num(mask_dis),z_reward(mask_dis),'BoxFaceColor',[0.9290 0.6940 0.1250],'LineWidth',5); swarmchart(patient_group_num(mask_dis),z_reward(mask_dis),60,'black','filled','XJitterWidth',.5);
%     title('Approach Slope'); ylim([-1.5,1.5]);
%     subplot(1,4,2);hold on;
%     boxchart(patient_group_num(mask_non),z_aversion(mask_non),'BoxFaceColor',[0 0.4470 0.7410],'LineWidth',5); swarmchart(patient_group_num(mask_non),z_aversion(mask_non),60,'black','filled');
%     boxchart(patient_group_num(mask_res),z_aversion(mask_res),'BoxFaceColor',[0.8500 0.3250 0.0980],'LineWidth',5); swarmchart(patient_group_num(mask_res),z_aversion(mask_res),60,'black','filled','XJitterWidth',.5);
%     boxchart(patient_group_num(mask_dis),z_aversion(mask_dis),'BoxFaceColor',[0.9290 0.6940 0.1250],'LineWidth',5); swarmchart(patient_group_num(mask_dis),z_aversion(mask_dis),60,'black','filled','XJitterWidth',.5);
%     title('Avoidance Slope'); ylim([-1.5,1.5]);
%     subplot(1,4,3);hold on;
%     boxchart(patient_group_num(mask_non),angle(mask_non),'BoxFaceColor',[0 0.4470 0.7410],'LineWidth',5); swarmchart(patient_group_num(mask_non),angle(mask_non),60,'black','filled');
%     boxchart(patient_group_num(mask_res),angle(mask_res),'BoxFaceColor',[0.8500 0.3250 0.0980],'LineWidth',5); swarmchart(patient_group_num(mask_res),angle(mask_res),60,'black','filled','XJitterWidth',.5);
%     boxchart(patient_group_num(mask_dis),angle(mask_dis),'BoxFaceColor',[0.9290 0.6940 0.1250],'LineWidth',5); swarmchart(patient_group_num(mask_dis),angle(mask_dis),60,'black','filled','XJitterWidth',.5);
%     title('Avoidance Slope'); 
%         subplot(1,4,4);hold on;
%     boxchart(patient_group_num(mask_non),mag(mask_non),'BoxFaceColor',[0 0.4470 0.7410],'LineWidth',5); swarmchart(patient_group_num(mask_non),mag(mask_non),60,'black','filled');
%     boxchart(patient_group_num(mask_res),mag(mask_res),'BoxFaceColor',[0.8500 0.3250 0.0980],'LineWidth',5); swarmchart(patient_group_num(mask_res),mag(mask_res),60,'black','filled','XJitterWidth',.5);
%     boxchart(patient_group_num(mask_dis),mag(mask_dis),'BoxFaceColor',[0.9290 0.6940 0.1250],'LineWidth',5); swarmchart(patient_group_num(mask_dis),mag(mask_dis),60,'black','filled','XJitterWidth',.5);
%     title('Avoidance Slope'); 
% 
% 
%     figure;hold on;
%     scatter(z_reward(mask_non),z_aversion(mask_non))
%     scatter(z_reward(mask_res),z_aversion(mask_res))
%     scatter(z_reward(mask_dis),z_aversion(mask_dis))
% % 
% linkprop(a2, {'View', 'XLim', 'YLim', 'ZLim'})
% %% Generate Hypothesis Figures
% load('/Users/raphaelb/Documents/UW/Research/gridlab/adbs_ocd/tasks/PAAT/Behavior Analysis/Baylor/Data/Predicted_Response_Values.mat');
% 
% xAxis = {'10','30', '50', '70', '90'};
% yAxis = {'10','30', '50', '70', '90'};
% xAxisLabel = {'Reward Value'};
% yAxisLabel = {'Aversive Value'};
% 
% figure;
% 
% curTitle='';
% subplot(2,3,1);
% colormap();
% [nr,nc] = size(prob_of_selecting_option_non_responder);
% prob_of_selecting_option_non_responder = [prob_of_selecting_option_non_responder nan(nr,1); nan(1,nc+1)];
% i = pcolor(prob_of_selecting_option_non_responder);
% c = colorbar; 
% xticks([1.5 2.5 3.5 4.5 5.5]); xticklabels(xAxis);
% yticks([1.5 2.5 3.5 4.5 5.5]); yticklabels(yAxis);
% title(curTitle); xlabel(xAxisLabel); ylabel(yAxisLabel);c.Label.String = 'Probability of Selecting Option';
% set(gca,'fontsize',24)
% set(gcf, 'Position',  [10 10 1200 450])
% 
% subplot(2,3,2);
% colormap();
% prob_of_selecting_option_responder = [prob_of_selecting_option_responder nan(nr,1); nan(1,nc+1)];
% i = pcolor(prob_of_selecting_option_responder);
% c = colorbar; 
% xticks([1.5 2.5 3.5 4.5 5.5]); xticklabels(xAxis);
% yticks([1.5 2.5 3.5 4.5 5.5]); yticklabels(yAxis);
% title(curTitle); xlabel(xAxisLabel); ylabel(yAxisLabel);c.Label.String = 'Probability of Selecting Option';
% set(gca,'fontsize',24)
% set(gcf, 'Position',  [10 10 1200 450])
% 
% subplot(2,3,3);
% colormap();
% prob_of_selecting_option_disinhib = [prob_of_selecting_option_disinhib nan(nr,1); nan(1,nc+1)];
% i = pcolor(prob_of_selecting_option_disinhib);
% c = colorbar; 
% xticks([1.5 2.5 3.5 4.5 5.5]); xticklabels(xAxis);
% yticks([1.5 2.5 3.5 4.5 5.5]); yticklabels(yAxis);
% title(curTitle); xlabel(xAxisLabel); ylabel(yAxisLabel);c.Label.String = 'Probability of Selecting Option';
% set(gca,'fontsize',24)
% set(gcf, 'Position',  [10 10 1600 800])
% 
% x_values = linspace(-25,125,7);
% y_values = linspace(-25,125,7);
% [X,Y] = meshgrid(x_values,y_values);
% [X_lines,Y_lines] = meshgrid(linspace(-25,125,7),linspace(-25,125,7));
% 
% a1=subplot(2,3,4);set(gca, 'XDir','reverse');
% prob_of_selecting_option_non_responder = [nan(1,nc+2); nan(nr+1,1) prob_of_selecting_option_non_responder];
% % surf(X,Y,prob_of_selecting_option_non_responder); hold on; shading interp;

% load('/Users/raphaelb/Documents/UW/Research/gridlab/adbs_ocd/tasks/PAAT/Behavior Analysis/Baylor/Data/Predicted_Response_Values.mat', 'prob_of_selecting_option_non_responder')
% x = repmat(10:20:90,1,5)';
% y = repelem(10:20:90,1,5)';
% z = reshape(prob_of_selecting_option_non_responder.',1,[])';
% sf = fit([x,y],z,'poly11');
% plot(sf,[x,y],z); hold on; caxis([0 1]);
% 
% % zlim([0,1])
% ylim([0,100])
% xlim([0,100])
% xlabel('Reward')
% ylabel('Risk')
% 
% 
% a2=subplot(2,3,5);set(gca, 'XDir','reverse');
% prob_of_selecting_option_responder = [nan(1,nc+2); nan(nr+1,1) prob_of_selecting_option_responder];
% % surf(X,Y,prob_of_selecting_option_responder); hold on;shading interp;
% load('/Users/raphaelb/Documents/UW/Research/gridlab/adbs_ocd/tasks/PAAT/Behavior Analysis/Baylor/Data/Predicted_Response_Values.mat', 'prob_of_selecting_option_responder')
% x = repmat(10:20:90,1,5)';
% y = repelem(10:20:90,1,5)';
% z = reshape(prob_of_selecting_option_responder.',1,[])';
% sf = fit([x,y],z,'poly11');
% plot(sf,[x,y],z); hold on; caxis([0 1]);
% 
% % zlim([0,1])
% ylim([0,100])
% xlim([0,100])
% xlabel('Reward')
% ylabel('Risk')
% 
% a3=subplot(2,3,6);set(gca, 'XDir','reverse');
% prob_of_selecting_option_disinhib = [nan(1,nc+2); nan(nr+1,1) prob_of_selecting_option_disinhib];
% % surf(X,Y,prob_of_selecting_option_disinhib); hold on;shading interp;
% load('/Users/raphaelb/Documents/UW/Research/gridlab/adbs_ocd/tasks/PAAT/Behavior Analysis/Baylor/Data/Predicted_Response_Values.mat', 'prob_of_selecting_option_disinhib')
% x = repmat(10:20:90,1,5)';
% y = repelem(10:20:90,1,5)';
% z = reshape(prob_of_selecting_option_disinhib.',1,[])';
% sf = fit([x,y],z,'poly11');
% plot(sf,[x,y],z); hold on; caxis([0 1]);
% % zlim([0,1])
% ylim([0,100])
% xlim([0,100])
% xlabel('Reward')
% ylabel('Risk')
% % 
% linkprop([a1,a2,a3], {'View', 'XLim', 'YLim', 'ZLim'})
% 
% %% Plot_fit_surace_params
% patient_group_types = ["non_responder","non_responder","non_responder",...
%     "non_responder","responder","non_responder","disinhibited",...
%     "disinhibited","responder","responder","non_responder"];
% groups_category = [1,1,1,1,2,1,3,3,2,2,1];
% responder_inds = [8,12,13];
% nonresponder_inds = [4,5,6,7,9,14];
% disinhib_inds = [10,11];
% p00 = [];
% p01 = [];
% p10 = [];
% for count = 1:length(patient_group)
%    p00(count) = all_fits{count}.p00;
%    p01(count) = all_fits{count}.p01;
%    p10(count) = all_fits{count}.p10;
%    disp(count)
%    disp(patient_group(count))
%    all_fits{count}
% 
% end
% figure; boxchart(groups_category,p00); hold on; swarmchart(groups_category,p00);
% figure; boxchart(groups_category,p01); hold on; swarmchart(groups_category,p01);
% figure; boxchart(groups_category,p10); hold on; swarmchart(groups_category,p10);
% 
% 
% %% Plot video of what params mean on surface
% load('/Users/raphaelb/Documents/UW/Research/gridlab/adbs_ocd/tasks/PAAT/Behavior Analysis/Baylor/Data/Predicted_Response_Values.mat', 'prob_of_selecting_option_responder')
% x = repmat(10:20:90,1,5)';
% y = repelem(10:20:90,1,5)';
% z = reshape(prob_of_selecting_option_responder.',1,[])';
% sf = fit([x,y],z,'poly11');
% p00_params = [linspace(sf.p00,sf.p00*2,33),linspace(sf.p00*2,0,66),linspace(0,sf.p00,33)];
% p10_params = [linspace(0.00625 ,0.02 ,33),linspace(0.02,-0.00625,66),linspace(-0.00625,0.00625,33)];
% p01_params = [linspace(-0.00625 ,0.00625 ,33),linspace(0.00625,-0.0125,66),linspace(-0.0125,-0.00625,33)];
% p00_inital = sf.p00;
% p10_inital = sf.p10;
% p01_inital = sf.p01;
% figure(2);
% 
% for i = 1:length(p00_params)
%     sf.p00 = p00_params(i);
%     subplot(2,3,1)
%     plot(sf,[x,y],z); caxis([0 1]);
%     view(2);
%     xlabel('Reward')
%     ylabel('Risk')    
%     subplot(2,3,4)
%     plot(sf,[x,y],z); caxis([0 1]);
%     zlim([-0.5,1.5])
%     xlabel('Reward')
%     ylabel('Risk')
%     sf.p00 = p00_inital;
% 
%     sf.p10 = p10_params(i);
%     subplot(2,3,2)
%     plot(sf,[x,y],z); caxis([0 1]);
%     view(2);
%     xlabel('Reward')
%     ylabel('Risk')    
%     subplot(2,3,5)
%     plot(sf,[x,y],z); caxis([0 1]);
%     zlim([-0.5,1.5])
%     xlabel('Reward')
%     ylabel('Risk')
%     sf.p10 = p10_inital;
% 
%     sf.p01 = p01_params(i);
%     subplot(2,3,3)
%     plot(sf,[x,y],z); caxis([0 1]);
%     view(2);
%     xlabel('Reward')
%     ylabel('Risk')    
%     subplot(2,3,6)
%     plot(sf,[x,y],z); caxis([0 1]);
%     zlim([-0.5,1.5])
%     xlabel('Reward')
%     ylabel('Risk')
%     sf.p01 = p01_inital;
% 
%     drawnow
% end