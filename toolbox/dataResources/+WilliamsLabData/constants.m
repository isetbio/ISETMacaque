classdef constants
% Constants from the Williams Lab data

    properties (Constant)
        micronsPerDegreeRetinalConversion = 199.26;
        axialLengthMM = 16.56;
        pupilDiameterMM = 6.7;
        imagingPeakWavelengthNM = 561;
        imagingFullWidthHalfMaxBandwidthNM = 5;
        pixelSizeMicronsOnRetina = 1.03;
        sfTuningStimulusFOVdegs = 0.7; % 1.3;
        temporalStimulationFrequencyHz = 6;
        galvanoMeterScannerRefreshRate = 25.3;
    
        % From Chen et al (1993): Serial spatial filters in Vision,
        % figure 4 caption: diameter of cones is 2.3 microns and the
        % inter-cone distance is 2.8 microns.
        % Note: cone diameter = 2 * cone radius = 2 * characteristic radius(gain = 1/e) = 2 * (sqrt(2) * Gaussian sigma)
        coneDiameterToConeSpacingRatio = 1.0; % 2.3/2.8;
        
        % Indices of measured L-cone center RGCs with reliable OTF curves.
        % These are used to compute the mean characteristic radius of the center.
        % Set to empty to use all L-cone center RGCs
        indicesOfLconeRGCsWithReliableDFresponses =  [3 4 6 7 8 10 11];
        
        % Indices of measured M-cone center RGCs with reliable OTF curves.
        % These are used to compute the mean characteristic radius of the center.
        % Set to empty to use all M-cone center RGCs
        indicesOfMconeRGCsWithReliableDFresponses =  [1 2 4];
       
        % The retinal stimulus power over an area of 2.54 x 1.92 is 2.5microWatts
        calibrationROI = struct(...
            'XrangeDegs', 2.54, ...
            'YrangeDegs', 1.92, ...
            'energyMicroWatts', 2.5);
    end
    
    methods (Static)
        % Custom cone spacing function specific to monkey 838 from the Williams lab
        function [rfSpacingMicrons, eccentricitiesMicrons] = M838coneMosaicSpacingFunction(rfPosMicrons, whichEye, useParfor)

            % Load tabulated data for Williams lab monkey 838
            load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
            horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
            verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
            coneDiameterMicrons = cone_locxy_diameter_838OD(:,3);

            % Spacing from diameters
            coneSpacingMicrons = coneDiameterMicrons / WilliamsLabData.constants.coneDiameterToConeSpacingRatio;

            % Interpolate density map on a uniform grid
            interpolationMethod = 'linear';
            extrapolationMethod = 'linear';
            F = scatteredInterpolant(horizontalEccMicrons,verticalEccMicrons, coneSpacingMicrons, ...
                interpolationMethod, extrapolationMethod);

            % Intepolate at rfPosMicrons
            xq = rfPosMicrons(:,1);
            yq = rfPosMicrons(:,2);
            rfSpacingMicrons = F(xq,yq);
            eccentricitiesMicrons = sqrt(sum(rfPosMicrons .^ 2, 2));
        end
        
        % MM -> Degs conversion function specific to monkey 838
        function eccDegs = M838coneMosaicRhoMMsToDegs(eccMMs)
        % Convert retinal distance in MMs to retinal distance in degs
            eccDegs = eccMMs * 1e3 / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        end

        % Degs -> MM conversion function specific to monkey 838
        function eccMMs = M838coneMosaicRhoDegsToMMs(eccDegs)
        % Convert retinal distance in degs to retinal distance in mm
            eccMicrons = eccDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
            eccMMs = eccMicrons / 1e3;
        end

        function minSpacingMicrons = M838coneMosaicMinConeSpacingMicrons
             % Load tabulated data for Williams lab monkey 838
            load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
            horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
            verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
            medianConeDiameterMicronsRawData = cone_locxy_diameter_838OD(:,3);

            % Spacing from diameters
            medianConeSpacingMicronsRawData = medianConeDiameterMicronsRawData / WilliamsLabData.constants.coneDiameterToConeSpacingRatio;

            [minSpacingMicrons, idx] = min(medianConeSpacingMicronsRawData );
            fprintf('Min cone inner segment aperture in the raw data is at ecc: %f %f microns and its value if %2.3f microns\n', ...
                horizontalEccMicrons(idx), verticalEccMicrons(idx), minSpacingMicrons * WilliamsLabData.constants.coneDiameterToConeSpacingRatio);
        end
    end
    
    
end
