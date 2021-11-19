
function [scalingFactor, computedROIenergyMicroWatts] = computeScalingFactor(theBackgroundOI, calibrationROI)
    
    % Get the irradiant energy (Watts/m^2/nm)
    energyMap = oiGet(theBackgroundOI, 'energy');
    
    % We want the energy at the photoreceptors, so we need to multiply this
    % by the macular transmittance.
    m = Macular('wave', oiGet(theBackgroundOI, 'wave'));
    macularTransmittance = m.transmittance;

    for iW = 1:size(energyMap,3)
        energyMap(:,:,iW) = energyMap(:,:,iW) * macularTransmittance(iW);
    end
        
    % Get the wavelength support
    wavelengthSupport = oiGet(theBackgroundOI, 'wave');
    
    % Get the spatial support
    spatialSupport = oiGet(theBackgroundOI, 'spatial support', 'microns');
    
    % Compute retinal pixel area in meters^2
    spatialSupportXMicrons = squeeze(spatialSupport(:,:,1));
    spatialSupportYMicrons = squeeze(spatialSupport(:,:,2));
    deltaXMicrons = spatialSupportXMicrons(1,2)-spatialSupportXMicrons(1,1);
    deltaYMicrons = spatialSupportYMicrons(2,1)-spatialSupportYMicrons(1,1);
    retinalPixelAreaMeters2 = (deltaXMicrons * 1e-6) * (deltaYMicrons * 1e-6);
    
    % Extract the retinal energy within the ROI
    spatialSupportXDegs = spatialSupportXMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    spatialSupportYDegs = spatialSupportYMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    idx = find( ...
        (abs(spatialSupportXDegs) <= calibrationROI.XrangeDegs / 2) & ...
        (abs(spatialSupportYDegs) <= calibrationROI.YrangeDegs / 2));
    [nRows, mCols, nWaves] = size(energyMap);
    
    % Extract the energy map within the ROI
    energyMap = reshape(energyMap, [nRows*mCols nWaves]);
    energyMap = energyMap(idx,:);
    
    % Integrate energyMap over the ROI space and over wavelength
    % Note that energy is Watts/m2/nm
    deltaLambdaNM = wavelengthSupport(2)-wavelengthSupport(1);
    computedROIenergyWatts = sum(energyMap(:)) * deltaLambdaNM * retinalPixelAreaMeters2; 
    computedROIenergyMicroWatts = computedROIenergyWatts * 1e6;
    
    % Compute scaling factor
    scalingFactor = calibrationROI.energyMicroWatts / computedROIenergyMicroWatts;
end
