function plot_spectrograms(approachful,avoidant,chan,pt,date)
    %approachful (convoluted TF-data) (trials x freq x time)
    %avoidant (convoluted TF-data) (trials x freq x time)
    %chan (DBS lead/ECoG strip target name)
    %pt: e.g. 006
    pt=['P',pt];
    sfreq=250;
    frequencies = logspace(log10(1),log10(100),100);
    time = linspace(-2,8,sfreq*10);

    baseline_idx1 = 1;
    baseline_idx2 = sfreq;
    %Baseline normalization of trial-averaged data
    baseline_power_approachful = mean(mean(approachful(:,:,baseline_idx1:baseline_idx2), 3),1);
    baseline_power_avoidant = mean(mean(avoidant(:,:,baseline_idx1:baseline_idx2), 3),1);
    db_converted_avg_approachful = 10 * log10(squeeze(mean(approachful, 1)) ./ baseline_power_approachful');
    db_converted_avg_avoidant = 10 * log10(squeeze(mean(avoidant, 1)) ./ baseline_power_avoidant');
    %Baseline normalization of all trials
    db_converted_sing_approachful = 10 * log10(approachful ./ baseline_power_approachful);
    db_converted_sing_avoidant = 10 * log10(avoidant ./ baseline_power_avoidant);

    trials_approachful = size(approachful,1);
    trials_avoidant = size(avoidant,1);
    %Statistical Analysis
    [zmap,zmapthresh] = permutation_cluster_test(db_converted_sing_approachful,db_converted_sing_avoidant,500);
    
    figure;
    subplot(3,1,1)
    imagesc(time,frequencies,db_converted_avg_approachful)
    set(gca, 'YDir', 'normal');
    title(['Approachful (Trials = ',num2str(trials_approachful),')'], FontSize=14)
    clim([-5 5])
    xline(0, 'Color', 'black', 'LineWidth', 2); 
    labels=[2.4,6.1,15.6,39.4,100];
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    yticklabels(arrayfun(@num2str, labels, 'UniformOutput', false));
    colormap(jet);

    subplot(3,1,2)
    imagesc(time,frequencies,db_converted_avg_avoidant)
    set(gca, 'YDir', 'normal');
    title(['Avoidant (Trials = ',num2str(trials_avoidant),')'], FontSize=14)
    clim([-5 5])
    xline(0, 'Color', 'black', 'LineWidth', 2); 
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    yticklabels(arrayfun(@num2str, labels, 'UniformOutput', false));
    colormap(jet);
    
    subplot(3,1,3)
    imagesc(time,frequencies,zmap)
    clim([-5 5])
    set(gca, 'YDir', 'normal');
    hold on
    contour(time,frequencies,zmapthresh,1,'linecolor','k')
    xline(0, 'Color', 'black', 'LineWidth', 2); 
    yticklabels(arrayfun(@num2str, labels, 'UniformOutput', false));
    title('Avoidant - Approachful', FontSize=14)
    xlabel('Time (s)'), ylabel('Frequency (Hz)')

    h = colorbar;
    h.Position = [0.92 0.1 0.02 0.8];
    ylabel(h,'Power (dB)')
    sgtitle([chan,': High Conflict Trials'])
    chan_save = extractAfter(chan,': ');
    saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_High_Conflict_Trials.png'])
    saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_High_Conflict_Trials.svg'])
end