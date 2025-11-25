function bandpassed_LFP(approachful,avoidant,x,chan,pt,date)
    %approachful (convoluted TF-data) (trials x freq x time)
    %avoidant (convoluted TF-data) (trials x freq x time)
    %chan (DBS lead/ECoG strip target name)
    %pt: e.g. 006
    if contains(pt,'DBSOCD')
        disp('DBSOCD Pt');
    else
        pt=['P',pt];
    end
    sfreq=250;

    baseline_idx1 = 1;
    baseline_idx2 = sfreq;
    %Baseline normalization of trial-averaged data
    baseline_power_approachful = mean(mean(approachful(:,:,baseline_idx1:baseline_idx2), 3),1);
    baseline_power_avoidant = mean(mean(avoidant(:,:,baseline_idx1:baseline_idx2), 3),1);
    
    %Baseline normalization of all trials
    db_converted_sing_approachful = 10 * log10(approachful ./ baseline_power_approachful);
    db_converted_sing_avoidant = 10 * log10(avoidant ./ baseline_power_avoidant);

    trials_approachful = size(approachful,1);
    trials_avoidant = size(avoidant,1);
    
    branges = {[1, 31], [32, 45], [46, 59], [60, 74], [75, 87]};
    names = {'Delta (1-4 Hz)', 'Theta (4-8 Hz)', 'Alpha (8-15 Hz)', 'Beta (15-30 Hz)', 'Gamma (30-55 Hz)'};

    figure;
    sgtitle(chan)
    n_timepoints = length(x);
    for i = 1:length(branges)
        brange = branges{i};
        name = names{i};

        approach_ci = get_confidence_interval(mean(db_converted_sing_approachful(:, brange(1):brange(2), :), 2));
        avoidance_ci = get_confidence_interval(mean(db_converted_sing_avoidant(:, brange(1):brange(2), :), 2));
        
        [~,zmapthresh] = permutation_cluster_test(squeeze(mean(db_converted_sing_approachful(:, brange(1):brange(2), :), 2)),squeeze(mean(db_converted_sing_avoidant(:, brange(1):brange(2), :), 2)),500,n_timepoints);
        
        subplot(2,3,i)
        plot(x, approach_ci(1, :), 'b', 'DisplayName', 'Neutral Mean');  % 'b' stands for blue
        hold on;
        fill([x, fliplr(x)], [approach_ci(2, :), fliplr(approach_ci(3, :))], 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Fill between CI with blue and 30% opacity
        
        plot(x, avoidance_ci(1, :), 'r', 'DisplayName', 'Provoked Mean');  % 'r' stands for red
        fill([x, fliplr(x)], [avoidance_ci(2, :), fliplr(avoidance_ci(3, :))], 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Fill between CI with red and 30% opacity
        
        ymax = max(max(approach_ci(3, :)), max(avoidance_ci(3, :)));
        
        % Add labels and legend
        xlabel('Time');
        ylabel('Power (dB)');
        
        significant_diff=find(zmapthresh);
        title(name)
     
        if isempty(significant_diff)
            disp('No Significance')
        else
            disp('Significant Indices Found')
            for i = 1:length(significant_diff)
                plot([x(significant_diff(i)), x(significant_diff(i))], [ymax, ymax+1], 'b', 'LineWidth', 2);
            end
        end
        if contains(chan,'Decision')
            h = legend('Approachful','', 'Avoidant');
        else
            h = legend('High Conflict Reward','', 'Low Conflict Reward');
        end
        set(h, 'Location', 'southeast', 'LineWidth', 1);
    end
    chan_save = extractAfter(chan,': ');
    if isempty(date)
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',chan_save,'_Spectral.png'])
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',chan_save,'_Spectral.svg'])
    else
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_Spectral.png'])
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_Spectral.svg'])
    end
end