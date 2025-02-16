function [zmap,zmapthresh] = permutation_cluster_test(condition1,condition2,n_permutes)
    % Condition 1 Approachful (trials x frequencies x timepoints)
    % Condition 2 Avoidant (trials x frequencies x timepoints)
    % addpath('C:\Users\matth\OneDrive\BCM\fieldtrip-20250114')
    % ft_defaults;
    sfreq=250;
    num_frex=100;
    frex = logspace(log10(1),log10(100),100);
    tftimes = linspace(-2*sfreq,8*sfreq,sfreq*10);
    nTimepoints = numel(tftimes);
    
    % TF data
    comb_short_tf= cat(1, condition1, condition2);
    total_trials=size(comb_short_tf,1);
    avoidant_trialnum=size(condition2,1);
    approachful_trialnum=size(condition1,1);
    
    diffmap=squeeze(mean(condition2(:,:,:),1) - mean(condition1(:,:,:),1));
    
    voxel_pval = 0.05;
    mcc_voxel_pval = 0.05; % mcc = multiple comparisons correction
    mcc_cluster_pval = 0.05;
    
    % compute actual t-test of difference
    tnum   = squeeze(mean(condition2(:,:,:),1) - mean(condition1(:,:,:),1));
    tdenom = sqrt( (std(condition2(:,:,:),0,1).^2)./size(condition2,1) + (std(condition1(:,:,:),0,1).^2)./size(condition1,1) );
    real_t = tnum./squeeze(tdenom);
    
    % initialize null hypothesis matrices
    permuted_tvals  = zeros(n_permutes,num_frex,nTimepoints);
    max_pixel_pvals = zeros(n_permutes,2);
    max_clust_info  = zeros(n_permutes,1);
    
    % generate pixel-specific null hypothesis parameter distributions
    for permi = 1:n_permutes
        fprintf('Iteration: %d of %d\n', permi, n_permutes);
        fake_condition_mapping = sign(randn(total_trials,1));
        
        % compute t-map of null hypothesis
        tnum   = squeeze(mean(comb_short_tf(fake_condition_mapping==-1,:,:),1)-mean(comb_short_tf(fake_condition_mapping==1,:,:),1));
        tdenom = sqrt( (std(comb_short_tf(fake_condition_mapping==-1,:,:),0,1).^2)./sum(fake_condition_mapping==-1) + (std(comb_short_tf(fake_condition_mapping==1,:,:),0,1).^2)./sum(fake_condition_mapping==1) );
        tmap = tnum./squeeze(tdenom);
        
        % save all permuted values
        permuted_tvals(permi,:,:) = tmap;
    
        % save maximum pixel values
        max_pixel_pvals(permi,:) = [ min(tmap(:)) max(tmap(:)) ];
        
        % for cluster correction, apply uncorrected threshold and get maximum cluster sizes
        % note that here, clusters were obtained by parametrically thresholding
        % the t-maps
        tmap(abs(tmap)<tinv(1-voxel_pval,total_trials-1))=0;
        
        % get number of elements in largest supra-threshold cluster
        clustinfo = bwconncomp(tmap);
        max_clust_info(permi) = max([ 0 cellfun(@numel,clustinfo.PixelIdxList) ]); % notes: cellfun is superfast, and the zero accounts for empty maps
    end
    
    % now compute Z-map
    zmap = (real_t-squeeze(mean(permuted_tvals,1)))./squeeze(std(permuted_tvals));
    
    % apply cluster-level corrected threshold
    zmapthresh = zmap;
    % uncorrected pixel-level threshold
    zmapthresh(abs(zmapthresh)<norminv(1-voxel_pval))=0;
    % find islands and remove those smaller than cluster size threshold
    clustinfo = bwconncomp(zmapthresh);
    clust_info = cellfun(@numel,clustinfo.PixelIdxList);
    clust_threshold = prctile(max_clust_info,100-mcc_cluster_pval*100);
    
    % identify clusters to remove
    whichclusters2remove = find(clust_info<clust_threshold);
    
    % remove clusters
    for ii=1:length(whichclusters2remove)
        zmapthresh(clustinfo.PixelIdxList{whichclusters2remove(ii)})=0;
    end
    zmapthresh=logical(zmapthresh);

end