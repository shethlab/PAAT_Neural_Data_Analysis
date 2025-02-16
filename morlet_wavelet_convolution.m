function [tf_data] = morlet_wavelet_convolution(data,sfreq)
    %Inputs:
    % data (number of trials x number of time points)
    % sfreq (sampling frequency)
    num_trials=size(data,1);
    frequencies=logspace(log10(1),log10(100),100);
    time = -1 : (1/sfreq) : (1 + 1/sfreq);
    n_wavelet = length(time);
    half_wavelet= (n_wavelet) ./ 2;
    n_data = size(data,2);
    n_convolution = n_wavelet + n_data -1;
    n_conv_pow2 = 2.^nextpow2(n_convolution);
    wavelet_cycles = logspace(log10(4),log10(7),length(frequencies));
    tf_data = zeros(num_trials,length(frequencies),n_data);
    for trial=1:num_trials
        fft_data = fft(data(trial,:),n_conv_pow2);
        for fi=1:length(frequencies)
            wavelet = (pi * frequencies(fi) * sqrt(pi))^(-0.5) .* exp(2 * 1j * pi * frequencies(fi) .* time) .* exp(-time.^2 ./ (2 * (wavelet_cycles(fi) ./ (2 * pi * frequencies(fi))).^2)) ./ frequencies(fi);
            fft_wavelet = fft(wavelet,n_conv_pow2);
            convolution_result_fft = ifft(fft_wavelet .* fft_data,n_conv_pow2);
            convolution_result_fft = convolution_result_fft(1:n_convolution);
            convolution_result_fft = convolution_result_fft(half_wavelet:end-half_wavelet);
            tf_data(trial,fi,:) = abs(convolution_result_fft).^2;
        end
    end
end