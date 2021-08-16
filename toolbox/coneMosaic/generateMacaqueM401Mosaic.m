function generateMacaqueM401Mosaic
% Generate a macaque cone mosaic based on the M401 cone density data
%
% Syntax:
%   generateMacaqueM401Mosaic
%
% Description: Generate a macaque cone mosaic based on the M401 cone spacing data
%              Also shows how to generate a cone mosaic using a custom cone
%              spacing function and custom retinal mm <-> visual angle degs
%              conversion functions.
%
%
% History:
%    08/16/21  NPC  ISETBIO TEAM, 2021

    cm = cMosaic(...
        'sizeDegs', [1.2 1.2], ...                                          % SIZE: x=1.2 degs, y=1.2 degs
        'eccentricityDegs', [0.0 0], ...                                    % ECC:  x=0.0 degs, y= 0.0 degs
        'computeMeshFromScratch', true, ...                                 % generate mesh on-line
        'customRFspacingFunction', @Williams401_spacingFunction, ...        % custom cone spacing function
        'customDegsToMMsConversionFunction', @Williams401_rhoDegsToMMs, ... % custom visual degs -> retinal mm conversion function
        'customMMsToDegsConversionFunction', @Williams401_rhoMMsToDegs, ... % customretinal  mm -> visual degs conversion function
        'micronsPerDegree', WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...   % custom mean microns per degree for macaque retina
        'coneDensities',  [0.48 0.48 0.04], ...                             % macaque cone density
        'tritanopicRadiusDegs', 0.0, ...                                    % no tritanopic area
        'randomSeed', randi(9999999), ...                                   % set the random seed, so at to generate a different mosaic each time
        'maxMeshIterations', 1000 ...                                       % stop iterative procedure after this many iterations
    );

    % Save the generated mosaic
    rootDirName = ISETmacaqueRootPath();
    mosaicFileName = fullfile(rootDirName, 'dataResources/coneMosaicM401.mat');
    save(mosaicFileName, 'cm');
    
    % Visualize the generated mosaic
    cm.visualize('domain', 'microns', ...
        'domainVisualizationLimits', [-150 150 -100 100], ...
        'domainVisualizationTicks', struct('x', -150:50:150, 'y', -150:50:150), ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M401');
    
    % Visualize the achieved density map
    coneDensityLevelsConesPerMM2 = 100000:18200:250000;
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', [-150 150 -100 100], ...
                'domainVisualizationTicks', struct('x', -150:50:150, 'y', -150:50:150), ...
                'densityContourOverlay',true, ...
                'labelCones', false, ...
                'crossHairsOnFovea', true, ...
                'densityContourLevels', coneDensityLevelsConesPerMM2, ...
                'densityContourLevelLabelsDisplay', true, ...
                'densityColorMap', colormap(), ...
                'verticalDensityColorBar', true);
end


% Custom cone spacing function specific to monkey 401 from the Williams lab
function [rfSpacingMicrons, eccentricitiesMicrons] = Williams401_spacingFunction(rfPosMicrons, whichEye, useParfor)

    % Load tabulated data for Williams lab monkey 401
    load('cone_data_M401_OS_2015.mat', 'cone_locxy_diameter');
    horizontalEccMicrons = cone_locxy_diameter(:,1);
    verticalEccMicrons = cone_locxy_diameter(:,2);
    coneDiameterMicrons = cone_locxy_diameter(:,3);
    
    % Assume cone spacing == cone diameter
    coneSpacingMicrons = coneDiameterMicrons;
    
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

% Degs -> MM conversion function specific to monkey 401
function eccMMs = Williams401_rhoDegsToMMs(eccDegs)
% Convert retinal distance in degs to retinal distance in mm
    eccMicrons = eccDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    eccMMs = eccMicrons / 1e3;
end

% MM -> Degs conversion function specific to monkey 401
function eccDegs = Williams401_rhoMMsToDegs(eccMMs)
% Convert retinal distance in MMs to retinal distance in degs
    eccDegs = eccMMs * 1e3 / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
end

