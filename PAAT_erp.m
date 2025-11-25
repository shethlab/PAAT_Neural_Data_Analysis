function PAAT_erp(approachful_LFP,avoidant_LFP,time,chan,pt,date)
    %% Compute ERP for PAAT (enter two conditions with time points)
    %approachful_LFP (trials x timepoints)
    %avoidant_LFP (trials x timepoints)
    
    % Percept Pts have sfreq=250
    sfreq=250;
    %Lowpass filter and remove edge artifacts
    lowpassed_approachful = lowpass(approachful_LFP', 100, sfreq);
    lowpassed_avoidant = lowpass(avoidant_LFP', 100, sfreq);
    lowpassed_approachful = lowpassed_approachful((sfreq/2)+1 : end - (sfreq/2),:)';
    lowpassed_avoidant = lowpassed_avoidant((sfreq/2)+1 : end - (sfreq/2),:)';

     
    %Normalize Approachful Trial LFP
    median_data = median(lowpassed_approachful,2);
    mad_data = mad(lowpassed_approachful,1, 2);
    approachful_ERP = (lowpassed_approachful - median_data) ./ mad_data;

    %Remove bad trials if they contain LFP data points over 10 MADs
    bd = [];  
    for count = 1:size(approachful_ERP, 1) 
        trial = approachful_ERP(count, :);
        if any(trial > 10 | trial < -10) 
            bd(end+1) = count; 
        end
    end
    approachful_ERP(bd,:)=[];
    
    %Normalize Avoidant Trial LFP
    median_data = median(lowpassed_avoidant,2);
    mad_data = mad(lowpassed_avoidant,1, 2);
    avoidant_ERP = (lowpassed_avoidant - median_data) ./ mad_data;
    
    %Remove bad trials if they contain LFP data points over 10 MADs
    bd = [];  
    for count = 1:size(avoidant_ERP, 1) 
        trial = avoidant_ERP(count, :); 
        if any(trial > 10 | trial < -10)
            bd(end+1) = count;
        end
    end
    avoidant_ERP(bd,:)=[];

    %Smooth ERP for plotting purposes
    avg_erp_approach= mean(approachful_ERP, 1);
    avg_erp_avoid= mean(avoidant_ERP, 1);
    smooth_erp_approach = smoothdata(avg_erp_approach, 'gaussian', sfreq/4);
    smooth_erp_avoid = smoothdata(avg_erp_avoid, 'gaussian', sfreq/4);
    
    
    figure;
    time = time((sfreq/2)+1 : end - (sfreq/2));
    % Heatmap
    subplot(2, 1, 1);
    imagesc(time, 1:size(approachful_ERP, 1), approachful_ERP);
    colormap(jet);
    clim([-5 5])
    title([chan,' Approachful']);
    xlabel('Time (s)');
    ylabel('Trials');
    hold on;
    yyaxis right;
    plot(time, smooth_erp_approach, 'LineWidth', 2);
    ylabel('Z-Robust')
    hold off;
    
    subplot(2, 1, 2);
    imagesc(time, 1:size(avoidant_ERP, 1), avoidant_ERP);
    colormap(jet);
    clim([-5 5])
    title([chan,' Avoidant']);
    xlabel('Time (s)');
    ylabel('Trials');
    hold on;
    yyaxis right;
    plot(time, smooth_erp_avoid, 'LineWidth', 2);
    ylabel('Z-Robust')
    hold off;
    
    h = colorbar('Location', 'eastoutside');
    set(h, 'Position', [0.94, 0.11, 0.02, 0.77]);
    ylabel(h, 'Z-Robust', 'FontSize', 12);
    chan_save = extractAfter(chan,': ');
    savepath = ['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\'];
    if ~exist(savepath, 'dir')
        mkdir(savepath)
    end
    if isempty(date)
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',chan_save,'_High_Conflict_ERP.png'])
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',chan_save,'_High_Conflict_ERP.svg'])
    else
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_High_Conflict_ERP.png'])
        saveas(gcf,['C:\Users\matth\OneDrive\BCM\PAAT Analysis\data\',pt,'\',date,'\',chan_save,'_High_Conflict_ERP.svg'])
    end

end