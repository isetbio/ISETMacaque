function c = loadConeMosaicData(monkeyID, maxRecordedRGCeccArcMin)
% Load the provided cone mosaic data
%
% Syntax:
%   c = loadConeMosaicData(monkeyID, maxRecordedRGCeccArcMin)
%
% Description:
%   Load the provided cone mosaic data
%
% Inputs:
%    monkeyID                  - String, 'M838'
%    maxRecordedRGCeccArcMin   - max ecc of recorded RGCs (only used to
%                                estimate the foveal cone Rc)
%
% Outputs:
%    c     - struct with:
%            'coneDiameterMicrons': inner segment aperture diameter
%                 (microns) for measured positions
%            'conePositionMicrons': measured (x,y) cone positions (microns)
%            'fovealConeCharacteristicRadiusDegs': min characteristic radius
%                  within a radius of 6 arc min (~ 20 microns) of the fovea
%
% Optional key/value pairs:
%    None
%         

    filename = sprintf('cone_data_%s_OD_2021.mat', monkeyID);
    variableName = sprintf('cone_locxy_diameter_%sOD', strrep(monkeyID, 'M', ''));
    load(filename, variableName);
    
    c = [];
    eval(sprintf('c.coneDiameterMicrons = %s(:,3);', variableName));
    eval(sprintf('c.conePositionMicrons = %s(:,1:2);', variableName));
    coneEccMicrons = sqrt(sum(c.conePositionMicrons.^2,2));

    % Estimate foveal cone characteristc radius
    maxEccMicrons = maxRecordedRGCeccArcMin/60 * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    idx = find(coneEccMicrons < maxEccMicrons);
    fovealConeDiameterMicrons = min(c.coneDiameterMicrons(idx));
    fovealConeCharacteristicRadiusMicrons = 0.204*fovealConeDiameterMicrons*sqrt(2.0);
    c.fovealConeCharacteristicRadiusDegs = fovealConeCharacteristicRadiusMicrons/WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
end
