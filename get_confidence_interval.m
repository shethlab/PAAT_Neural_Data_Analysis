function ci = get_confidence_interval(data)
    %data (trials x timepoints)
    [n, timepoints] = size(data);  
    
    ci = zeros(3, timepoints);
    
    for cz = 1:timepoints
        % Fit normal distribution to data at timepoint cz
        mu_provoc = mean(data(:, cz));  % Mean of the data
        sigma_provoc = std(data(:, cz));  % Standard deviation of the data
        
        ci(1, cz) = mu_provoc;  % Store the mean in the first row of ci
        ci_provoc = 1.96 * (sigma_provoc / sqrt(n));  % 95% CI for mean
        
        ci(2, cz) = mu_provoc - ci_provoc;  % Lower bound of CI
        ci(3, cz) = mu_provoc + ci_provoc;  % Upper bound of CI
    end
end