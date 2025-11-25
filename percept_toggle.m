function [approachful_LFP_epochs,avoidant_LFP_epochs,low_conflict_LFP_epochs]=percept_toggle(toggle_file,pt,date)
    if contains(pt,'DBSOCD')
        disp('DBSOCD Pt');
    else
        pt=['P',pt];
    end
    %Load Neural/Behavioral Data
    load(toggle_file,'data');
    try
        behav_path=['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\processed\single_session\PAAT_combined_dataTable_',pt,'_',date,'.csv'];
        resultsTable = readtable(behav_path);
    catch
        prompt = 'Multiple Files Found. Select file number: ';
        file_num=input(prompt);
        behav_path=['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\processed\single_session\PAAT_combined_dataTable_',pt,'_',date,'_',num2str(file_num),'.csv'];
        resultsTable = readtable(behav_path);
    end
    [resultsTable]=expand_table_data(resultsTable); %add additional info
    %bad_idx = resultsTable.isForcedChoice==1;
    event_codes=data.Events.Event;
    event_marker_num=event_codes;
    start_marker=find(event_marker_num==1);

    %ekg_time = (1000*data.brainvision.time{1,1}) + data.brainvision.brainvision_task_start_timestamp_unix;
    ekg_time = (1000*data.brainvision.time{1,1}) + data.brainvision.brainvision_start_timestamp_unix;
    ekg_ind = find(cellfun(@(x) contains(x,'Electrode'), data.brainvision.label)==1);
    if isempty(ekg_ind)
        ekg_ind = find(cellfun(@(x) contains(x,'EKG'), data.brainvision.label)==1);
        if isempty(ekg_ind)
            ekg_ind = find(cellfun(@(x) contains(x,'ECG'), data.brainvision.label)==1);
        end
    end
    ekg_data = data.brainvision.trial{1,1}(ekg_ind,:);
    figure; 
    hold on; plot(ekg_time, ekg_data)
    plot(data.Events.Timestamp,data.Events.Event*100); 
    plot(data.neural.combined_data_table.Timestamp,data.neural.combined_data_table{:,3},'Color','g')

    sfreq=250;
    derivedtimes=[data.neural.combined_data_table.Timestamp];
    figure; plot(derivedtimes)
    prompt = 'Is the Derived Time Linear (1=yes 0=no): ';
    response=input(prompt);
    
    if response==0
        error('Chalked Data. Exclude or Preprocess Again')
    end
    
    figure; plot(event_marker_num);
    prompt='How many practice runs are there (0 for none): ';
    response=input(prompt);    
    try
        start_ind=start_marker(response+1);
    catch
        prompt='Index Invalid (Use integer numbers):How many practice runs are there (0 for none)?';
        response=input(prompt);
        start_ind=start_marker(response+1);
    end

    %extract event marker timestamps
    event_codes=event_codes(start_ind:end);
    s2=data.Events{find(event_codes==2),1};
    s3=data.Events{find(event_codes==3),1};
    s4=data.Events{find(event_codes==4),1};
    s6=data.Events{find(event_codes==6),1};
    s8=data.Events{find(event_codes==8),1};
    s9=data.Events{find(event_codes==9),1};
    LFP_epochs=cell(length(s2),1);
    %Epoch LFP data at every s4 marker
    for u=1:length(s4)
        event_index=s4(u);
        [~,lfp_index]=min(abs(data.neural.combined_data_table.Timestamp-event_index));
        if u==1
            start_index=lfp_index;
        end
        if u==length(s4)
            end_index=lfp_index;
        end
        LFP_epochs(u,1)={data.neural.combined_data_table{lfp_index-(sfreq*6):lfp_index+(sfreq*3)-1,3}};
        %Report packet loss for left hem
        pckt_loss_LT = isnan(LFP_epochs{u,1});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs(u,2)={0};
        else
            LFP_epochs(u,2)={nnz(pckt_loss_LT)};
        end
        LFP_epochs(u,3)={data.neural.combined_data_table{lfp_index-(sfreq*6):lfp_index+(sfreq*3)-1,4}};
        %Report packet loss for right hem
        pckt_loss_LT = isnan(LFP_epochs{u,3});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs(u,4)={0};
        else
            LFP_epochs(u,4)={nnz(pckt_loss_LT)};
        end
    end

    LFP_epochs_outcome=cell(length(s8),1);
    for u=1:length(s8)
        event_index=s8(u);
        [~,lfp_index]=min(abs(data.neural.combined_data_table.Timestamp-event_index));
        if u==1
            start_index=lfp_index;
        end
        if u==length(s8)
            end_index=lfp_index;
        end
        LFP_epochs_outcome(u,1)={data.neural.combined_data_table{lfp_index-(sfreq*2.0):lfp_index+(sfreq*5)-1,3}};
        %Report packet loss for left hem
        pckt_loss_LT = isnan(LFP_epochs_outcome{u,1});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs_outcome(u,2)={0};
        else
            LFP_epochs_outcome(u,2)={nnz(pckt_loss_LT)};
        end
        LFP_epochs_outcome(u,3)={data.neural.combined_data_table{lfp_index-(sfreq*2.0):lfp_index+(sfreq*5)-1,4}};
        %Report packet loss for right hem
        pckt_loss_LT = isnan(LFP_epochs_outcome{u,3});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs_outcome(u,4)={0};
        else
            LFP_epochs_outcome(u,4)={nnz(pckt_loss_LT)};
        end
    end
    %Raw LFP and PSD Inspection both hemispheres (for weird artifacts)
    % lowpassed_left = lowpass(data.neural.combined_data_table{start_index:end_index,3},100,sfreq);
    % lowpassed_left=lowpassed_left(sfreq:end-sfreq);
    % lowpassed_right = lowpass(data.neural.combined_data_table{start_index:end_index,4},100,sfreq);
    % lowpassed_right=lowpassed_right(sfreq:end-sfreq); 
    % [welch_left,~]=pwelch(lowpassed_left,sfreq*8,sfreq*4,[],sfreq);
    % [welch_right,f]=pwelch(lowpassed_right,sfreq*8,sfreq*4,[],sfreq);
    % 
    % figure;
    % subplot(2,2,1)
    % plot((1:length(lowpassed_left))/sfreq,lowpassed_left)
    % title('Lowpassed Left LFP')
    % subplot(2,2,2)
    % plot(f(f<75),10*log10(welch_left(f<75)))
    % title('Left PSD')
    % subplot(2,2,3)
    % plot((1:length(lowpassed_right))/sfreq,lowpassed_right)
    % title('Lowpassed Right LFP')
    % subplot(2,2,4)
    % plot(f(f<75),10*log10(welch_right(f<75)))
    % title('Right PSD')
    % 
    % prompt='Inspect PSDs: Are there artifacts (1=yes & 0=no): ';
    % response=input(prompt);
    % if response==1
    %     error('Chalked Data. Exclude or Preprocess Again')
    % end
    % start_ind=start_marker(response+1);
    %Keep only high conflict trials and separate into approachful/avoidant
    % good_trials=[];
    % for result=1:height(resultsTable)
    %     if ~any(ismissing(resultsTable(result,7:10)))
    %         good_trials = [good_trials,result];
    %     end
    % end
    % resultsTable=resultsTable(good_trials,:);
    if length(s4)==height(resultsTable) %check if #trials match from Results Table & Toggle Sync File
        %Low Conflict High Reward
        low_conflict_reward_ind = find(resultsTable.ChoseRewarding_LowConflict==1);
        low_conflict_reward = LFP_epochs(low_conflict_reward_ind,:); 
        no_packet_loss_ind = find(cellfun(@(x) any(x==0),low_conflict_reward(:,2)) & cellfun(@(x) any(x==0),low_conflict_reward(:,4)));
        low_conflict_reward=low_conflict_reward(no_packet_loss_ind,[1,3]);
        low_conflict_reward_L=cell2mat(reshape(low_conflict_reward(:,1),1,[]))';
        low_conflict_reward_R=cell2mat(reshape(low_conflict_reward(:,2),1,[]))';
        low_conflict_LFP_epochs= cat(3,low_conflict_reward_L,low_conflict_reward_R);

        %High Conflict and Approach/Avoidance
        high_conflict_avoidant_ind=find(resultsTable.arePosNegAligned==1 & resultsTable.ChoseSafer_fixed0623==1);
        high_conflict_avoidant=LFP_epochs(high_conflict_avoidant_ind,:);     
        no_packet_loss_ind = find(cellfun(@(x) any(x==0),high_conflict_avoidant(:,2)) & cellfun(@(x) any(x==0),high_conflict_avoidant(:,4)));
        high_conflict_avoidant=high_conflict_avoidant(no_packet_loss_ind,[1,3]);
        high_conflict_avoidant_L=cell2mat(reshape(high_conflict_avoidant(:,1),1,[]))';
        high_conflict_avoidant_R=cell2mat(reshape(high_conflict_avoidant(:,2),1,[]))';
        avoidant_LFP_epochs= cat(3,high_conflict_avoidant_L,high_conflict_avoidant_R);

        high_conflict_approachful_ind=find(resultsTable.arePosNegAligned==1 & resultsTable.ChoseSafer_fixed0623==0);   
        high_conflict_approachful=LFP_epochs(high_conflict_approachful_ind,:);
        no_packet_loss_ind = find(cellfun(@(x) any(x==0),high_conflict_approachful(:,2)) & cellfun(@(x) any(x==0),high_conflict_approachful(:,4)));
        high_conflict_approachful=high_conflict_approachful(no_packet_loss_ind,[1,3]);
        high_conflict_approachful_L=cell2mat(reshape(high_conflict_approachful(:,1),1,[]))';
        high_conflict_approachful_R=cell2mat(reshape(high_conflict_approachful(:,2),1,[]))';
        approachful_LFP_epochs = cat(3,high_conflict_approachful_L,high_conflict_approachful_R);
    else
        disp(['Number of Results: ',num2str(height(resultsTable))])
        disp(['Number of LFP Epochs: ',num2str(length(s4))])
        error('Mismatch: Event Markers (Neural Data) and Behavioral Trial Count (Results Table)')
    end
    % 
    % if length(s8)==height(resultsTable) %check if #trials match from Results Table & Toggle Sync File
    %     reward_ind=find(resultsTable.Outcome==1);
    %     reward_LFP=LFP_epochs_outcome(reward_ind,:);     
    %     no_packet_loss_ind = find(cellfun(@(x) any(x==0),reward_LFP(:,2)) & cellfun(@(x) any(x==0),reward_LFP(:,4)));
    %     reward_LFP=reward_LFP(no_packet_loss_ind,[1,3]);
    %     reward_LFP_L=cell2mat(reshape(reward_LFP(:,1),1,[]))';
    %     reward_LFP_R=cell2mat(reshape(reward_LFP(:,2),1,[]))';
    %     reward_epochs= cat(3,reward_LFP_L,reward_LFP_R);
    % 
    %     negative_stimulus_ind=find(resultsTable.Outcome==-1);   
    %     negative_stimulus_LFP=LFP_epochs_outcome(negative_stimulus_ind,:);
    %     no_packet_loss_ind = find(cellfun(@(x) any(x==0),negative_stimulus_LFP(:,2)) & cellfun(@(x) any(x==0),negative_stimulus_LFP(:,4)));
    %     negative_stimulus_LFP=negative_stimulus_LFP(no_packet_loss_ind,[1,3]);
    %     negative_stimulus_LFP_L=cell2mat(reshape(negative_stimulus_LFP(:,1),1,[]))';
    %     negative_stimulus_LFP_R=cell2mat(reshape(negative_stimulus_LFP(:,2),1,[]))';
    %     negative_stimulus_LFP_epochs = cat(3,negative_stimulus_LFP_L,negative_stimulus_LFP_R);
    % else
    %     error('Mismatch: Event Markers (Neural Data) and Behavioral Trial Count (Results Table)')
    % end
    disp('Finished')

end