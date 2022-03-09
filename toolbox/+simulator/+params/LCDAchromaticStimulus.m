function s = LCDAchromaticStimulus(varargin)
% Stimulus params for the achromatic stimulus
%
% Syntax:
%   s = LCDAchromaticStimulus();
%
% Description:
%   Stimulus params for the achromatic LCD stimulus
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
   p.parse(varargin{:});
   theSpatialFrequency = p.Results.spatialFrequency;
   theSpatialPhaseDegs = p.Results.spatialPhaseDegs;
   theContrast = p.Results.contrast;
   
   wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-500:5:500);
   % Only doing L/M cone simulation, so skip short wavelengths
   idx = find((wavelengthSupport >= 465)&&(wavelengthSupport<=750));
   wavelengthSupport = wavelengthSupport(idx);
            
   s = struct(...
       'type', 'LCDdisplayAchromatic', ...
       'stimulationDurationCycles', 4, ...
       'orientation', 90, ...
       'fovDegs', WilliamsLabData.constants.sfTuningStimulusFOVdegs, ...
       'spatialFrequencyCPD', 0, ...     % variable
       'spatialPhaseDegs', 0, ...        % variable
       'contrast', 0, ...
       'frameDurationSeconds', 1/WilliamsLabData.constants.galvanoMeterScannerRefreshRate, ...
       'pixelSizeDegs', WilliamsLabData.constants.pixelSizeMicronsOnRetina/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...  % half of the device pixel size
       'sceneSpatialUpsampleFactor', WilliamsLabData.constants.sceneSpatialUpsampleFactor, ... % actual stim pixel size too close to cone aperture, so upsample the scene to have a well-sampled cone aperture
       'wavelengthSupport', wavelengthSupport, ...
       'viewingDistanceMeters', 20.0, ...                   % focused at infinity
       'backgroundChromaticity', [0.31 0.32], ...
       'backgroundLuminanceCdM2', 100, ...  
       'lmsConeContrasts', [1 1 1]);
    
   if (~isempty(theContrast))
       % Background scene
       % Do nothing more
   else
       % Stimulus frame params for the test stimulus
       s.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
       s.spatialFrequencyCPD = theSpatialFrequency;
       s.spatialPhaseDegs = theSpatialPhaseDegs;
       s.contrast = 1;
   end
   
end
