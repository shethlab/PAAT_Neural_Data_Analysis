function [approachful_LFP_epochs,avoidant_LFP_epochs]=percept_toggle(toggle_file,pt,date)
    pt=['P',pt];

    %Load Neural/Behavioral Data
    load(toggle_file,'lfpData');
    load(toggle_file,'toggle_sync');
    behav_path=['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\processed\single_session\PAAT_combined_dataTable_',pt,'_',date,'.csv'];
    resultsTable = readtable(behav_path);

    [resultsTable]=expand_table_data(resultsTable); %add additional info
    %bad_idx = resultsTable.isForcedChoice==1;
    event_codes=toggle_sync.UDT_harmonized_events.Event;
    event_marker_num=event_codes;
    event_marker_num=str2double(extractBetween(event_marker_num,3,4));
    start_marker=find(event_marker_num==1);
 
    sfreq=250;
    derivedtimes=[lfpData.combinedDataTable.DerivedTimes];
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
    s2=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  2')),2};
    s3=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  3')),2};
    s4=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  4')),2};
    s6=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  6')),2};
    s8=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  8')),2};
    s9=toggle_sync.UDT_harmonized_events{find(contains(event_codes,'S  9')),2};
    LFP_epochs=cell(length(s2),1);
    %Epoch LFP data at every s4 marker
    for u=1:length(s4)
        event_index=s4(u);
        lfp_index=find(lfpData.combinedDataTable.DerivedTimes==event_index);
        if u==1
            start_index=lfp_index;
        end
        if u==length(s4)
            end_index=lfp_index;
        end
        LFP_epochs(u,1)={lfpData.combinedDataTable{lfp_index-(sfreq*2):lfp_index+(sfreq*8)-1,2}};
        %Report packet loss for left hem
        pckt_loss_LT = isnan(LFP_epochs{u,1});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs(u,2)={0};
        else
            LFP_epochs(u,2)={nnz(pckt_loss_LT)};
        end
        LFP_epochs(u,3)={lfpData.combinedDataTable{lfp_index-(sfreq*2):lfp_index+(sfreq*8)-1,3}};
        %Report packet loss for right hem
        pckt_loss_LT = isnan(LFP_epochs{u,3});
        log_LT=find(pckt_loss_LT==1);
        if isempty(log_LT)==1
            LFP_epochs(u,4)={0};
        else
            LFP_epochs(u,4)={nnz(pckt_loss_LT)};
        end
    end

    %Raw LFP and PSD Inspection both hemispheres (for weird artifacts)
    lowpassed_left = lowpass(lfpData.combinedDataTable{start_index:end_index,2},100,sfreq);
    lowpassed_left=lowpassed_left(sfreq:end-sfreq);
    lowpassed_right = lowpass(lfpData.combinedDataTable{start_index:end_index,3},100,sfreq);
    lowpassed_right=lowpassed_right(sfreq:end-sfreq); 
    [welch_left,~]=pwelch(lowpassed_left,sfreq*8,sfreq*4,[],sfreq);
    [welch_right,f]=pwelch(lowpassed_right,sfreq*8,sfreq*4,[],sfreq);

    figure;
    subplot(2,2,1)
    plot((1:length(lowpassed_left))/sfreq,lowpassed_left)
    title('Lowpassed Left LFP')
    subplot(2,2,2)
    plot(f(f<75),10*log10(welch_left(f<75)))
    title('Left PSD')
    subplot(2,2,3)
    plot((1:length(lowpassed_right))/sfreq,lowpassed_right)
    title('Lowpassed Right LFP')
    subplot(2,2,4)
    plot(f(f<75),10*log10(welch_right(f<75)))
    title('Right PSD')
    
    prompt='Inspect PSDs: Are there artifacts (1=yes & 0=no): ';
    response=input(prompt);
    if response==1
        error('Chalked Data. Exclude or Preprocess Again')
    end
    start_ind=start_marker(response+1);
    %Keep only high conflict trials and separate into approachful/avoidant
    if length(s4)==height(resultsTable) %check if #trials match from Results Table & Toggle Sync File
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
        error('Mismatch: Event Markers (Neural Data) and Behavioral Trial Count (Results Table)')
    end
    disp('Finished')
end