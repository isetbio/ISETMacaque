classdef constants
% Constants from the Williams Lab data

    properties (Constant)
        micronsPerDegreeRetinalConversion = 199.26;
        axialLengthMM = 16.56;
        pupilDiameterMM = 6.7;
        imagingPeakWavelengthNM = 561;
        imagingFullWidthHalfMaxBandwidthNM = 5;
        pixelSizeMicronsOnRetina = 1.03;
        sfTuningStimulusFOVdegs = 1.3;
        
        % The retinal stimulus power over an area of 2.54 x 1.92 is 2.5microWatts
        calibrationROI = struct(...
            'XrangeDegs', 2.54, ...
            'YrangeDegs', 1.92, ...
            'energyMicroWatts', 2.5);

    end
    
end
