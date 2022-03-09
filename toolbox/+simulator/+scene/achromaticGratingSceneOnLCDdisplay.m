function theScene = achromaticGratingSceneOnLCDdisplay(stimParams, theDisplay)

    
    meanLuminance = stimParams.backgroundLuminanceCdM2;
    meanChromaticity = stimParams.backgroundChromaticity;

    backgroundxyY = [meanChromaticity(1) meanChromaticity(2) 1];
    coneContrastModulation = [1 1 1];
    rgbSettings = computeAchromaticRGBsettings(theDisplay, backgroundxyY, coneContrastModulation);
    
    lcdSPD = displayGet(theDisplay, 'spd');
       
    % We upsample, so that the resulting oiImage will be of high resolution, and therefore,
    % spatial filtering by the cone aperture will also be done in high resolution
    upsampleFactor = stimParams.sceneSpatialUpsampleFactor;

    % Determine pixels num, taking into account the upsampleFactor
    sceneSampleSizeDegs = stimParams.pixelSizeDegs/upsampleFactor;
    pixelsNum = round(stimParams.fovDegs / sceneSampleSizeDegs);
    
    % Compute spatial support
    spatialSupportDegs = linspace(-0.5*stimParams.fovDegs, 0.5*stimParams.fovDegs, pixelsNum);
    spatialSupportDegs = spatialSupportDegs - mean(spatialSupportDegs);
    [X,Y] = meshgrid(spatialSupportDegs, spatialSupportDegs);
    
    % Quantize space based on stimParams.pixelSizeDegs
    quantizedX = floor(X/stimParams.pixelSizeDegs)*stimParams.pixelSizeDegs;

    % Compute spatial modulation pattern
    spatialModulationPattern = 0.5*(1 + stimParams.contrast * sin(2*pi*stimParams.spatialFrequencyCPD * quantizedX + stimParams.spatialPhaseDegs/180*pi));

    % Create an empty scene.  Put it far enough away so it
    % is basically in focus for an emmetropic eye accommodated to infinity.
    theScene = sceneCreate('empty');
    theScene = sceneSet(theScene,'wavelength',stimParams.wavelengthSupport);
    theScene = sceneSet(theScene,'distance', stimParams.viewingDistanceMeters);
    
    % The spectral profile of the 3 LCD guns driven with settings [rgb]
    gratingSpdRadianceProfile = rgbSettings(1) * lcdSPD(:,1) + rgbSettings(2) * lcdSPD(:,2) + rgbSettings(3) * lcdSPD(:,3);
    
    % Compute the stimulus spatial-spectral radiance
    stimulusRadiance = zeros(pixelsNum, pixelsNum, numel(stimParams.wavelengthSupport));
    for iWave = 1:numel(stimParams.wavelengthSupport)
        stimulusRadiance(:,:,iWave) = spatialModulationPattern * gratingSpdRadianceProfile(iWave);
    end
    
    % Set the scene radiance
    theScene = sceneSet(theScene, 'energy', stimulusRadiance, stimParams.wavelengthSupport);
    
    % Set the desired FOV
    theScene = sceneSet(theScene, 'h fov', stimParams.fovDegs);
            
    % Se the desired mean luminance
    theScene = sceneAdjustLuminance(theScene, meanLuminance);
end


function RGBimage = computeAchromaticRGBsettings(theDisplay, backgroundxyY, coneContrastModulation)

    % Compute the color transformation matrices for this display
    displayLinearRGBToLMS = displayGet(theDisplay, 'rgb2lms');
    displayLMSToLinearRGB = inv(displayLinearRGBToLMS);
    displayLinearRGBToXYZ = displayGet(theDisplay, 'rgb2xyz');
    displayXYZToLinearRGB = inv(displayLinearRGBToXYZ);
    
    % Background chromaticity and mean luminance vector
    xyY = backgroundxyY;
    
    % Background XYZ tri-stimulus values
    backgroundXYZ = (xyYToXYZ(xyY(:)))';
    
    % Background linear RGB primary values for the presentation display
    backgroundRGB = imageLinearTransform(backgroundXYZ, displayXYZToLinearRGB);
    
    % Background LMS excitations
    backgroundLMS = imageLinearTransform(backgroundRGB, displayLinearRGBToLMS);
    
    % Compute the spatial contrast modulation pattern
    contrastPattern = [1];
    
    % Compute the LMS-cone contrast spatial pattern
    LMScontrastImage = zeros(size(contrastPattern,1), size(contrastPattern,2), 3);
    for coneIndex = 1:3
        LMScontrastImage(:,:,coneIndex) = coneContrastModulation(coneIndex) * contrastPattern;
    end
    
    % Compute the LMS excitations image
    LMSexcitationImage = bsxfun(@times, (1.0+LMScontrastImage), reshape(backgroundLMS, [1 1 3]));
        
    % Compute the linear RGB primaries image
    RGBimage = imageLinearTransform(LMSexcitationImage, displayLMSToLinearRGB);
end
