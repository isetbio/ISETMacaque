function theScene = generateMonochromaticGratingScene(stimParams, scalingFactor)
    
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
    
    % The spectral profile of the imaging beam
    gratingSpdRadianceProfile = exp(-0.5*((stimParams.wavelengthSupport-stimParams.imagingPeakWavelengthNM)/FWHMToStd(stimParams.imagingFullWidthHalfMaxBandwidthNM)).^2);
    
    % Amplify it according to the scalingFactor
    if (~isempty(scalingFactor))
        gratingSpdRadianceProfile = gratingSpdRadianceProfile * scalingFactor;
    end
    
    % Compute the stimulus spatial-spectral radiance
    stimulusRadiance = zeros(pixelsNum, pixelsNum, numel(stimParams.wavelengthSupport));
    for iWave = 1:numel(stimParams.wavelengthSupport)
        stimulusRadiance(:,:,iWave) = spatialModulationPattern * gratingSpdRadianceProfile(iWave);
    end
    
    % Set the scene radiance
    theScene = sceneSet(theScene, 'energy', stimulusRadiance, stimParams.wavelengthSupport);
    
    % Set the desired FOV
    theScene = sceneSet(theScene, 'h fov', stimParams.fovDegs);
end