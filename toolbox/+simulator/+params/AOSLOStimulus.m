function s = AOSLOStimulus(varargin)
% Stimulus params for the AOSLO stimulus
%
% Syntax:
%   s = AOSLOStimulus();
%
% Description:
%   Stimulus params for the AOSLO stimulus
%
% Inputs:
%    none
%
% Outputs:
%    s      - struct with stimulus params
%
% Optional key/value pairs:
%    'spatialFrequency'   : spatial frequency of the grating
%    'spatialPhaseDegs'   : spatial phase of the grating
%    'contrast'           : stimulus contrast

    p = inputParser;
    p.addParameter('spatialFrequency', [], @(x)(isempty(x)||(isscalar(x))));
    p.addParameter('spatialPhaseDegs', [], @(x)(isempty(x)||(isscalar(x))));
    p.addParameter('contrast', [], @(x)(isempty(x)||(isscalar(x))));
    p.addParameter('sceneRadianceScalingFactor', 1, @(x)(isempty(x)||(isscalar(x))));
    p.parse(varargin{:});
    theSpatialFrequency = p.Results.spatialFrequency;
    theSpatialPhaseDegs = p.Results.spatialPhaseDegs;
    theContrast = p.Results.contrast;
    theSceneRadianceScalingFactor = p.Results.sceneRadianceScalingFactor;
    
    s = struct(...
            'type', 'monochromaticAO', ...
            'stimulationDurationCycles', 4, ...
            'orientation', 90, ...
            'fovDegs', [], ...                % variable
            'spatialFrequencyCPD', 0, ...     % variable
            'spatialPhaseDegs', 0, ...        % variable
            'contrast', 0, ...
            'frameDurationSeconds', 1/WilliamsLabData.constants.galvanoMeterScannerRefreshRate, ...
            'pixelSizeDegs', WilliamsLabData.constants.pixelSizeMicronsOnRetina/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...  % half of the device pixel size
            'sceneSpatialUpsampleFactor', WilliamsLabData.constants.sceneSpatialUpsampleFactor, ... % actual stim pixel size too close to cone aperture, so upsample the scene to have a well-sampled cone aperture
            'imagingPeakWavelengthNM', WilliamsLabData.constants.imagingPeakWavelengthNM, ...
            'imagingFullWidthHalfMaxBandwidthNM', WilliamsLabData.constants.imagingFullWidthHalfMaxBandwidthNM, ...
            'wavelengthSupport', WilliamsLabData.constants.imagingPeakWavelengthNM + (-20:2:20), ...
            'sceneRadianceScalingFactor', theSceneRadianceScalingFactor, ...
            'viewingDistanceMeters', 20.0 ... 
        );
    
    if (isempty(theContrast))
        % Background scene
        % Compute the scaling factor using a 3 deg, uniform field stimulus to compute the energy over a
        % retinal region of 2.54x1.92 (which we know from measurements that it has a power of 2.5 microWatts)
        s.fovDegs = 3;
    else
        % Stimulus frame params for the test stimulus
        s.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
        s.contrast = theContrast;
        s.spatialFrequencyCPD = theSpatialFrequency;
        s.spatialPhaseDegs = theSpatialPhaseDegs;
    end
end
