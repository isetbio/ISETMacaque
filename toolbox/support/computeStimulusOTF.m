function stimulusOTF = computeStimulusOTF(desiredSpatialFrequencySupport)
    % Compute stimulus OTF
    stimulusSupportMicrons = linspace(0, 250*WilliamsLabData.constants.pixelSizeMicronsOnRetina, 2048*4);
    stimulusSupportMicrons = [-fliplr(stimulusSupportMicrons) stimulusSupportMicrons(2:end)];
    stimulusSupportDegs = stimulusSupportMicrons/WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    stimulus = zeros(1,numel(stimulusSupportMicrons));
    stimulus(abs(stimulusSupportMicrons) <= WilliamsLabData.constants.pixelSizeMicronsOnRetina/2) = 1;
    
 
    [powerSpectrum, amplitudeSpectrum, frequencySupport] = ...
        analyze1DSpectrum(stimulusSupportDegs, stimulus, 'GaussianWindow', 1, 'none');
    amplitudeSpectrum = amplitudeSpectrum/max(amplitudeSpectrum);
        
 
    stimulusOTF = zeros(1, numel(desiredSpatialFrequencySupport));
    for k = 1:numel(desiredSpatialFrequencySupport)
        [~, idx] = min(abs(desiredSpatialFrequencySupport(k)-frequencySupport));
        stimulusOTF(k) = amplitudeSpectrum(idx);
    end
    
    showStimulusOTF = ~true;
    if (showStimulusOTF)
        figure(99); clf;
        subplot(1,2,1)
        stairs(stimulusSupportMicrons, stimulus, 'LineWidth', 1.5)
        xlabel('space (microns)');
        
        subplot(1,2,2)
        plot(frequencySupport, amplitudeSpectrum, 'k-', 'LineWidth', 1.5);
        hold on;
        plot(desiredSpatialFrequencySupport, stimulusOTF, 'ks', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 60], 'XScale', 'log', 'FontSize', 14);
        xlabel('spatial frequency (c/deg)');
        pause
    end
end

