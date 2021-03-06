function theStimulusOTF = stimulusOTF(spatialFrequencySupport)
% Compute the stimulation apparatus OTF (due to finite pixel size)
%
% Syntax:
%   theStimulusOTF = simulator.analyze.stimulusOTF(spatialFrequencySupport)
%
%
% Description: Compute the stimulation apparatus OTF (due to finite pixel size)

    % Compute stimulus OTF
    stimulusSupportMicrons = linspace(0, 250*WilliamsLabData.constants.pixelSizeMicronsOnRetina, 2048*4);
    stimulusSupportMicrons = [-fliplr(stimulusSupportMicrons) stimulusSupportMicrons(2:end)];
    stimulusSupportDegs = stimulusSupportMicrons/WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    stimulus = zeros(1,numel(stimulusSupportMicrons));
    stimulus(abs(stimulusSupportMicrons) <= WilliamsLabData.constants.pixelSizeMicronsOnRetina/2) = 1;
    
 
    [powerSpectrum, amplitudeSpectrum, frequencySupport] = ...
        analyze1DSpectrum(stimulusSupportDegs, stimulus, 'GaussianWindow', 1, 'none');
    amplitudeSpectrum = amplitudeSpectrum/max(amplitudeSpectrum);
        
    theStimulusOTF = interp1(frequencySupport, amplitudeSpectrum, spatialFrequencySupport, 'linear');
    
    
    showStimulusOTF = ~true;
    if (showStimulusOTF)
        figure(99); clf;
        subplot(1,2,1)
        stairs(stimulusSupportMicrons, stimulus, 'LineWidth', 1.5)
        xlabel('space (microns)');
        
        subplot(1,2,2)
        plot(frequencySupport, amplitudeSpectrum, 'k-', 'LineWidth', 1.5);
        hold on;
        plot(spatialFrequencySupport, theStimulusOTF, 'ks', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 60], 'XScale', 'log', 'FontSize', 14);
        xlabel('spatial frequency (c/deg)');
        
    end
end

function [powerSpectrum, amplitudeSpectrum, frequencySupport, NyquistFrequency, maxPowerFrequency] = ...
    analyze1DSpectrum(support, slice, powerSpectrumComputationMethod, upsampleF, interpolationMethod)

    % Validate inputs
    assert(ismember(interpolationMethod, {'nearest', 'linear', 'none'}), ...
        'interpolationMethod must be either ''linear'', ''nearest'', or ''none''.');
    assert(ismember(powerSpectrumComputationMethod, {'GaussianWindow', 'KaiserWindow'}), ...
        'powerSpectrumComputationMethod must be either ''GaussianWindow'' or ''KaiserWindow''.');
    
    % Upsample signal if so specified
    if (upsampleF > 1) && (ismember(interpolationMethod, {'nearest', 'linear'}))
       supportHR = linspace(support(1), support(end), round(numel(support)*upsampleF)); 
       sliceHR = interp1(support, slice, supportHR, interpolationMethod);
    else
       supportHR = support;
       sliceHR = slice;
    end
   
    % Compute power spectrum
    switch (powerSpectrumComputationMethod)
       case 'GaussianWindow'
            sigmaSupport = max(supportHR)/4;
            windowGauss = exp(-0.5*(supportHR/sigmaSupport).^2);
            sliceHR = sliceHR .* windowGauss;
            nFFT = max([4096 numel(supportHR)]);
            amplitudeSpectrum = abs(fftshift(fft(sliceHR,nFFT))) / length(sliceHR);
            powerSpectrum = amplitudeSpectrum .^2;
            
            % Frequency support
            fMax = 1/(2*(supportHR(2)-supportHR(1)));
            deltaF = fMax / (nFFT/2);
            frequencySupport = (-fMax+deltaF):deltaF:fMax;
            
            % Only keep positive frequencies
            idx = find(frequencySupport>=0);
            amplitudeSpectrum = amplitudeSpectrum(idx);
            powerSpectrum = powerSpectrum(idx);
            frequencySupport = frequencySupport(idx);
            
       case 'KaiserWindow'
           % 'Leakage' controls the Kaiser window sidelobe attenuation relative to the mainlobe width, compromising between improving resolution and decreasing leakage:
           % A large leakage value resolves closely spaced tones, but masks nearby weak tones.
           % A small leakage value finds small tones in the vicinity of larger tones, but smears close frequencies together.
           % Example: 'Leakage',0 reduces leakage to a minimum at the expense of spectral resolution.
           % Example: 'Leakage',0.85 approximates windowing the data with a Hann window.
           % Example: 'Leakage',1 is equivalent to windowing the data with a rectangular window, maximizing leakage but improving spectral resolution.
           [powerSpectrum, frequencySupport ] = pspectrum(sliceHR, supportHR, 'Leakage', 0);
           amplitudeSpectrum = sqrt(powerSpectrum);
   end
   
   % Compute Nyquist frequency of the original signal
   dX = support(2)-support(1);
   NyquistFrequency = 1/(2*dX);
   
   % Frequency at which power spectrum is maximal
   [~,maxPidx] = max(powerSpectrum);
   maxPowerFrequency = frequencySupport(maxPidx);
end
