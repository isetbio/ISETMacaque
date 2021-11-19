function displayConeMosaicStats(theConeMosaic)

    load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
    horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
    verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
    medianConeDiameterMicronsRawData = cone_locxy_diameter_838OD(:,3);
    fprintf('Min cone diameter from raw data: %f\n', min(medianConeDiameterMicronsRawData));
    fprintf('Max cone diameter from raw data: %f\n', max(medianConeDiameterMicronsRawData));
    
    [minConeApertureMicrons, idxMin] = min(theConeMosaic.coneApertureDiametersMicrons);
    [maxConeApertureMicrons, idxMax] = max(theConeMosaic.coneApertureDiametersMicrons);
    minConeApertureSigma = minConeApertureMicrons*theConeMosaic.coneApertureModifiers.sigma;
    maxConeApertureSigma = maxConeApertureMicrons*theConeMosaic.coneApertureModifiers.sigma;
    fprintf('min cone aperture diameter : %2.2f, sigma: %2.2f microns at %2.1f,%2.1f\n', ...
        minConeApertureMicrons, min(theConeMosaic.blurApertureDiameterMicronsZones)*theConeMosaic.coneApertureModifiers.sigma, theConeMosaic.coneRFpositionsMicrons(idxMin,1), theConeMosaic.coneRFpositionsMicrons(idxMin,2));
    fprintf('max cone aperture diameter : %2.2f , sigma: %2.2f microns at %2.1f,%2.1f\n', ...
        maxConeApertureMicrons, max(theConeMosaic.blurApertureDiameterMicronsZones)*theConeMosaic.coneApertureModifiers.sigma, theConeMosaic.coneRFpositionsMicrons(idxMax,1), theConeMosaic.coneRFpositionsMicrons(idxMax,2));
    
    
    for zoneIndex = 1:numel(theConeMosaic.coneIndicesInZones)
       coneIndicesInThisZone = theConeMosaic.coneIndicesInZones{zoneIndex};
       if (ismember(idxMin, coneIndicesInThisZone))
           fprintf('Cone %d with min cone aperture sigma (%f) is in zone %d, with blur sigma %f\n', ...
               idxMin, minConeApertureSigma, zoneIndex, theConeMosaic.blurApertureDiameterMicronsZones(zoneIndex)*theConeMosaic.coneApertureModifiers.sigma);
       end
       if (ismember(idxMax, coneIndicesInThisZone))
           fprintf('Cone %d with max cone aperture sigma (%f) is in zone %d, with blur sigma %f\n', ...
               idxMax, maxConeApertureSigma, zoneIndex, theConeMosaic.blurApertureDiameterMicronsZones(zoneIndex)*theConeMosaic.coneApertureModifiers.sigma);
       end
    end
    
end