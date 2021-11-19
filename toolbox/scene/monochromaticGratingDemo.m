function monochromaticGratingDemo(monkeyID)

    rootDirName = ISETmacaqueRootPath();
    mosaicFileName = fullfile(rootDirName, sprintf('dataResources/coneMosaic%s.mat', monkeyID));
    load(mosaicFileName, 'cm');
    
    sceneSpatialUpsampleFactor = 12;
    sigmaGaussianApertureMicrons = 0.204 * 1.93;
    [spatialSupportMicrons, g, frequencySupportCyclesPerDegree, gAmplitudeSpectrum] = ...
        analyzeAperture(sigmaGaussianApertureMicrons, sceneSpatialUpsampleFactor);
    minConeApertureShape = g((size(g,1)-1)/2+1,:);
    minConeApertureShape = minConeApertureShape /max(minConeApertureShape);
    coneApertureSupportDegs = spatialSupportMicrons / cm.micronsPerDegree;
    maxConeApertureShape = [];
    
    % Define wavelength support relative to the imaging wavelength
    wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-20:2:20); % (-160:2:140);
    
    % Generate diffraction-limited optics for the Williams lab experiment
    opticalDefocusDiopters = 0.0;
    theOI  = ...
        diffractionLimitedOptics(WilliamsLabData.constants.pupilDiameterMM, wavelengthSupport, ...
        WilliamsLabData.constants.imagingPeakWavelengthNM, ...
        WilliamsLabData.constants.micronsPerDegreeRetinalConversion, opticalDefocusDiopters);

    
    % Visualize the PSF
    theOptics = oiGet(theOI, 'optics');
    [~,idx] = min(abs(wavelengthSupport-WilliamsLabData.constants.imagingPeakWavelengthNM));
    theOTF = opticsGet(theOptics, 'otf data');
    sfSupportCyclesPerMM = opticsGet(theOptics, 'otf fx');
    sfSupportCyclesPerDeg = sfSupportCyclesPerMM/1e3*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    
    % Get the amplitude of the OTF 
    visualizedOTF = squeeze(abs(theOTF(:,:,idx)));
    
    % FFT shift it
    visualizedOTF = fftshift(visualizedOTF);
    
    [~,idx] = max(visualizedOTF(:));
    [r,c] = ind2sub(size(visualizedOTF), idx);
    visualizedOTFslice = squeeze(visualizedOTF(r,:));
    idx = find(sfSupportCyclesPerDeg>=0);
    otfData.spatialFrequency = sfSupportCyclesPerDeg(idx);
    otfData.slice = visualizedOTFslice(idx);
    
    stimParams = struct(...
        'fovDegs', [], ...
        'spatialFrequencyCPD', [], ...
        'spatialPhaseDegs', 0, ...
        'contrast', 1.0, ...
        'pixelSizeDegs', WilliamsLabData.constants.pixelSizeMicronsOnRetina/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
        'sceneSpatialUpsampleFactor', sceneSpatialUpsampleFactor, ... % actual stim pixel size too close to cone aperture, so upsample
        'imagingPeakWavelengthNM', WilliamsLabData.constants.imagingPeakWavelengthNM, ...
        'imagingFullWidthHalfMaxBandwidthNM', WilliamsLabData.constants.imagingFullWidthHalfMaxBandwidthNM, ...
        'wavelengthSupport', wavelengthSupport, ...
        'viewingDistanceMeters', 20.0 ...                   % focused at infinity
        );
    
    
    % Use a 3 deg, uniform field stimulus to compute the energy over a
    % retinal region of 2.54x1.92 (which we know had a power of 2.5
    % microWatts)
    stimParams.spatialFrequencyCPD = 0;
    stimParams.fovDegs = 3;
    theBackgroundScene = generateMonochromaticGratingScene(stimParams,  []);
    
    % Compute the OI of the background scene
    theOI = oiCompute(theBackgroundScene, theOI);
    
    % Compute scaling factor using the OI for the uniform field and the calibratioROI
    scalingFactor = computeScalingFactor(theOI, WilliamsLabData.constants.calibrationROI);
    
    % Make sure we got the right ROIenergy after applying the computed scaling factor
    theBackgroundScene = generateMonochromaticGratingScene(stimParams,  scalingFactor);
    theOI = oiCompute(theBackgroundScene, theOI);
    [~, computedROIenergyMicroWatts] = computeScalingFactor(theOI, WilliamsLabData.constants.calibrationROI);
    fprintf('Desired energy within ROI: %f microWatts, achieved: %f microWatts\n', ...
        WilliamsLabData.constants.calibrationROI.energyMicroWatts, computedROIenergyMicroWatts); 
    
    
    % The background stimulus
    stimParams.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
    stimParams.spatialFrequencyCPD = 0.0;
    theBackgroundScene = generateMonochromaticGratingScene(stimParams, scalingFactor);
    
    % Compute the optical image of the background stimulus
    theOI = oiCompute(theBackgroundScene, theOI);
    
    % Retrieve the spectral support
    spectralSupport = oiGet(theOI, 'wave');
    deltaW = spectralSupport(2)-spectralSupport(1);
        
    backgroundEnergyWattsPerNMPerMeter2 = oiGet(theOI, 'energy');
    backgroundEnergyWattsPerMeter2 = sum(backgroundEnergyWattsPerNMPerMeter2,3) * deltaW;
    
    
    % Compute 1.3 deg test stimuli of different spatial frequencies
    load('SpatialFrequencyData_M838_OD_2021.mat',  'freqs'); 
    sfs =  freqs;
    
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1800 1100]);
    
 
    % Video setup
    rootDirName = ISETmacaqueRootPath();
    videoFileName = fullfile(strrep(rootDirName, 'toolbox', ''), 'simulations/generatedData/exports/retinalStimulusPSpectrumLeakage0');
    videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
    videoOBJ.FrameRate = 10;
    videoOBJ.Quality = 100;
    videoOBJ.open();
    
     % Compute the spatial phases for the oi sequence
    desiredOISequenceStimulationCycles = 3;
    spatialPhases = spatialPhasesForOISequence(desiredOISequenceStimulationCycles);
    displayFrameDurationSeconds = 1/WilliamsLabData.constants.galvanoMeterScannerRefreshRate;
    
    for iSF = numel(sfs):-1:1
        stimParams.spatialFrequencyCPD = sfs(iSF);
        
        for iPhase = 1:numel(spatialPhases)
            stimParams.spatialPhaseDegs = spatialPhases(iPhase);
            theStimulusScene = generateMonochromaticGratingScene(stimParams, scalingFactor);
            % Compute the optical image of the test stimulus
            theListOfOpticalImages{iPhase} = oiCompute(theStimulusScene, theOI);
            theStimulusTemporalSupportSeconds(iPhase) = (iPhase-1)*displayFrameDurationSeconds;
        end
        
        % Generate an @oiSequence object from the list of computed optical images
        theOIsequence = oiArbitrarySequence(theListOfOpticalImages, theStimulusTemporalSupportSeconds);
        timeAxis = theOIsequence.timeAxis;
        
        for iFrame = 1:theOIsequence.length
            % Get the OI
            theOI = theOIsequence.frameAtIndex(iFrame);

            % Retrieve the energy
            energyWattsPerNMPerMeter2 = oiGet(theOI, 'energy');
            energyWattsPerMeter2 = sum(energyWattsPerNMPerMeter2,3) * deltaW;

            ROImeter2 = WilliamsLabData.constants.calibrationROI.XrangeDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion * 1e-6 * ...
                        WilliamsLabData.constants.calibrationROI.YrangeDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion * 1e-6;
            energyMicroWattsPerROI = 1e6 * energyWattsPerMeter2 * ROImeter2;
            backgroundEnergyMicroWattsPerROI = 1e6 * backgroundEnergyWattsPerMeter2 * ROImeter2;

            % Retrieve the spatial support
            spatialSupport = oiGet(theOI, 'spatial support', 'microns');
            spatialSupportXMicrons = squeeze(spatialSupport(:,:,1));
            spatialSupportXMicrons = squeeze(spatialSupportXMicrons(1,:));


            spatialSupportXDegs = spatialSupportXMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;

            % Retrieve an RGB rendition
            rgbImage = oiGet(theOI, 'rgb');

            updateFigure(energyWattsPerNMPerMeter2, rgbImage, spectralSupport, spatialSupportXDegs, spatialSupportXMicrons, ...
                backgroundEnergyMicroWattsPerROI, energyMicroWattsPerROI, stimParams, WilliamsLabData.constants.calibrationROI, ...
                coneApertureSupportDegs, minConeApertureShape, maxConeApertureShape, otfData, monkeyID, timeAxis(iFrame));
            drawnow;

            videoOBJ.writeVideo(getframe(hFig));
        end
    end
    
    videoOBJ.close();
    
end

function updateFigure(energyWattsPerNMPerMeter2, rgbImage, spectralSupport, spatialSupportXDegs,  spatialSupportXMicrons, ...
    backgroundEnergyMicroWattsPerROI, energyMicroWattsPerROI, stimParams, calibrationROI, ...
    coneApertureSupportDegs, minConeApertureShape, maxConeApertureShape, otfData, monkeyID, theTimeSeconds)
    
    % Compute the power spectrum of the min cone aperture   
    [~,minConeApertureAmplitudeSpectrum, coneApertureFrequencySupport] = analyze1DSpectrum(coneApertureSupportDegs, ...
        minConeApertureShape, 'KaiserWindow', 1, 'none');

    if (~isempty(maxConeApertureShape))
        % Compute the power spectrum of the max cone aperture   
        [~,maxConeApertureAmplitudeSpectrum, coneApertureFrequencySupport] = analyze1DSpectrum(coneApertureSupportDegs, ...
            maxConeApertureShape, 'KaiserWindow', 1, 'none');
    end
    
    subplot('Position', [0.03 0.55 0.23 0.40]);
    energyTmp = reshape(energyWattsPerNMPerMeter2, [size(energyWattsPerNMPerMeter2,1)*size(energyWattsPerNMPerMeter2,2) size(energyWattsPerNMPerMeter2,3)]);
    [~,idx] = max(energyTmp(:));
    [peakPixelIndex,peakWaveIndex] = ind2sub(size(energyTmp), idx);
    [peakY, peakX] = ind2sub([size(energyWattsPerNMPerMeter2,1) size(energyWattsPerNMPerMeter2,2)], peakPixelIndex);
    waveSlice = squeeze(energyWattsPerNMPerMeter2(peakY, peakX, :));
    stem(spectralSupport, waveSlice, 'filled', 'BaseValue', 0, 'LineStyle', '-',  'LineWidth', 1.0, 'Color', 'r',...
        'MarkerSize', 6, 'MarkerFaceColor', [1 0.5 0.5]);
    grid on
    axis 'square';
    xlabel('wavelength (nm)');
    ylabel('retinal power (Watts/nm/m2)');
    set(gca, 'XLim', [spectralSupport(1) spectralSupport(end)], 'YLim', [0 5], 'YTick', 0:1:5, 'XTick', 400:5:750);
    set(gca, 'FontSize', 20);
    
    
    subplot('Position', [0.33 0.55 0.23 0.40]);
    image(spatialSupportXDegs, spatialSupportXDegs, rgbImage);
    hold on;
    plot([0 0], [-1 1], 'k-',  'LineWidth', 1.0);
    plot([-1 1], [0 0], 'k-',  'LineWidth', 1.0);
    hold off;
    title(sprintf('%2.2f c/deg', stimParams.spatialFrequencyCPD));
    axis 'image';
    xlabel('retinal space (degs)');
    ylabel('retinal space (degs)');
    set(gca, 'XLim', stimParams.fovDegs/2*[-1 1], 'YLim', stimParams.fovDegs/2*[-1 1]);
    set(gca, 'FontSize', 20);
    
    subplot('Position', [0.03 0.06 0.95 0.40]);
    backgroundEnergy = mean(backgroundEnergyMicroWattsPerROI(:));
    yo = round(size(energyWattsPerNMPerMeter2,1)/2);
    stimEnergySlice = energyMicroWattsPerROI(yo,:); 
    
    
    slice = stimEnergySlice-backgroundEnergy;
    
    upsampleF = 1;
    interpolationMethod = 'nearest';
    % Plot the horizontal slice of retinal power
    [xb,yb] = stairs(spatialSupportXMicrons,slice+backgroundEnergy);
    plot(xb,yb, 'r-', 'LineWidth', 1.5);
    hold on;
   
    
     if (~isempty(maxConeApertureShape))
        % Plot the max cone aperture
        faceColor = [1 0 1];
        edgeColor = 0.5*[1 0 1];
        makeShadedPlot(coneApertureSupportDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, maxConeApertureShape*4.9, ...
            faceColor, edgeColor)
     end
     
    % Plot the min cone aperture
    faceColor = [0 0 1];
    edgeColor = 0.5*[0 0 1];
    makeShadedPlot(coneApertureSupportDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, minConeApertureShape*4.9, ...
        faceColor, edgeColor);

    
    %plot([0 0], [0 max(stimEnergySlice)*1.1], 'k-',  'LineWidth', 1.0);
    
    % Plot the background energy
    plot([spatialSupportXMicrons(1) spatialSupportXMicrons(end)], [backgroundEnergy backgroundEnergy], 'k--',  'LineWidth', 1.0);
    hold off;
    set(gca, 'XLim', [-60 60]); % stimParams.fovDegs/2*[-1 1]*WilliamsLabData.constants.micronsPerDegreeRetinalConversion);
    set(gca, 'YLim', [0 5], 'YTick', 0:1:5);
    set(gca, 'XTick', -200:5:200);
    grid on
    ylabel(sprintf('retinal power (microWatts per %2.2f x%2.2f degs)',calibrationROI.XrangeDegs,calibrationROI.YrangeDegs));
    xlabel('retinal space (microns)');
    title(sprintf('%2.1f msec', theTimeSeconds*1000));
    set(gca, 'FontSize', 20);
    
    
    maxAmplitudeSpectrumValudDisplayed = 2.0;
    
    % Compute power spectrum
    subplot('Position', [0.62 0.55 0.36 0.39]);
    
    powerSpectrumComputationMethod =  'KaiserWindow';  % {'GaussianWindow', 'KaiserWindow'}
    [~, amplitudeSpectrum, frequencySupport, retinalStimulusNyquistFrequency, maxPowerFrequency] = ...
       analyze1DSpectrum(spatialSupportXDegs, slice, ...
       powerSpectrumComputationMethod, upsampleF, interpolationMethod);


    stem(frequencySupport, amplitudeSpectrum, 'filled', 'BaseValue', 0, 'LineWidth', 1.0, 'LineStyle', '-', ...
             'Color', 'r', 'MarkerSize', 4, 'MarkerFaceColor', [1.0  0.5 0.5]);
    
    hold on;
    %minConeApertureHandle = plot(coneApertureFrequencySupport, minConeApertureAmplitudeSpectrum/max(minConeApertureAmplitudeSpectrum)*maxAmplitudeSpectrumValudDisplayed,' b-', 'LineWidth', 2.0);
    
    if (~isempty(maxConeApertureShape))
        maxConeApertureHandle = plot(coneApertureFrequencySupport, maxConeApertureAmplitudeSpectrum/max(maxConeApertureAmplitudeSpectrum)*maxAmplitudeSpectrumValudDisplayed,' m-', 'LineWidth', 2.0);
    end
     
    maxOTFSlice = max(otfData.slice);
    OTFSliceISETBioHandle = plot(otfData.spatialFrequency,otfData.slice/maxOTFSlice*maxAmplitudeSpectrumValudDisplayed, 'k-', 'LineWidth', 2.0); 
    load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID),'otf', 'freqs');
    OTFSliceWilliamsDataHandle = plot(freqs, otf/maxOTFSlice*maxAmplitudeSpectrumValudDisplayed, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 0.8]);
    
    %retinalStimulusNyquistFrequencyHandle = plot(retinalStimulusNyquistFrequency*[1 1], [0 maxAmplitudeSpectrumValudDisplayed], 'k--', 'LineWidth', 1.5);
    
    hold off;
    set(gca, 'YLim', [0 maxAmplitudeSpectrumValudDisplayed], 'YTick', 0:0.5:3);
    set(gca, 'XScale', 'log', 'XLim', [1 300], 'XTick', [1 3 6 10 30 60 100 300],  'YTick', [], 'FontSize', 20);
     if (~isempty(maxConeApertureShape))
        legend([minConeApertureHandle, maxConeApertureHandle, OTFSliceISETBioHandle, OTFSliceWilliamsDataHandle], ...
        {'smallest cone aperture OTF', 'largest cone aperture OTF', 'OTF (ISETBio)', 'OTF (Williams Lab'}, ...
        'FontSize', 12);
     else
          legend([OTFSliceISETBioHandle, OTFSliceWilliamsDataHandle], ...
        {'OTF (ISETBio)', 'OTF (Williams Lab)'}, ...
        'FontSize', 12);
     end
     
    
    grid on;
    xlabel('spatial frequency (c/deg)');
    ylabel('amplitude spectrum')
    %title(sprintf('max power at %2.1f c/deg', maxPowerFrequency));
    
end

function makeShadedPlot(x,y, faceColor, edgeColor)
    [xb,yb] = stairs(x,y);
    px = reshape(xb, [1 numel(xb)]);
    py = reshape(yb, [1 numel(yb)]);
    px = [px(1) px px(end)];
    py = [1*eps py 2*eps];
    pz = -10*eps*ones(size(py)); 
    patch(px,py,pz,'FaceColor',faceColor,'EdgeColor',edgeColor, 'FaceAlpha', 0.5);
end

