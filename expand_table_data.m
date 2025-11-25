function [resultsTable]=expand_table_data(resultsTable)
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
    %resultsTable = resultsTable(resultsTable.isForcedChoice == 0,:);
    
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
    
    % Was the rewarding option chosen (in low conflict trials)?
    resultsTable.ChoseRewarding_LowConflict = nan(length(resultsTable.ChoseRight),1);

    resultsTable.ChoseRewarding_LowConflict(resultsTable.relPosProb_RvL>0 & resultsTable.ChoseRight==1 & resultsTable.arePosNegAligned==0) = 1;
    resultsTable.ChoseRewarding_LowConflict(resultsTable.relPosProb_RvL<0 & resultsTable.ChoseRight==0 & resultsTable.arePosNegAligned==0) = 1;
    resultsTable.ChoseRewarding_LowConflict(resultsTable.arePosNegAligned==1) = 0;
    resultsTable.ChoseRewarding_LowConflict(resultsTable.relPosProb_RvL<0 & resultsTable.ChoseRight==1 & resultsTable.arePosNegAligned==0) = 0;
    resultsTable.ChoseRewarding_LowConflict(resultsTable.relPosProb_RvL>0 & resultsTable.ChoseRight==0 & resultsTable.arePosNegAligned==0) = 0;
    %%Creating new table with only congruent trials
    % Subsetted table with only trials like those intended (risky = more positive)
    resultsTable_AlignedTrialsOnly = resultsTable(resultsTable.arePosNegAligned,:);
end