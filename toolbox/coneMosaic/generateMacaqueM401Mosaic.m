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

    monkeyID = 'M401';
    reComputeMosaic = false;
    if (reComputeMosaic)
        sizeDegs = 1.2;  
        
        cm = cMosaic(...
            'sizeDegs', sizeDegs*[1.0 1.0], ...                                 % SIZE: x=1.2 degs, y=1.2 degs
            'eccentricityDegs', [0  .0 0], ...                                    % ECC:  x=0.0 degs, y= 0.0 degs
            'computeMeshFromScratch', true, ...                                 % generate mesh on-line
            'customMinRFspacing', minConeSpacingMicrons(), ...
            'customRFspacingFunction', @Williams401_spacingFunction, ...        % custom cone spacing function
            'customDegsToMMsConversionFunction', @Williams401_rhoDegsToMMs, ... % custom visual degs -> retinal mm conversion function
            'customMMsToDegsConversionFunction', @Williams401_rhoMMsToDegs, ... % customretinal  mm -> visual degs conversion function
            'micronsPerDegree', WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...   % custom mean microns per degree for macaque retina
            'coneDensities',  [0.48 0.48 0.04], ...                             % macaque cone density
            'tritanopicRadiusDegs', 0.0, ...                                    % no tritanopic area
            'randomSeed', randi(9999999), ...                                   % set the random seed, so at to generate a different mosaic each time
            'maxMeshIterations', 1000 ...                                       % stop iterative procedure after this many iterations
        );

        % Cone aperture modifiers
        % The cone light gathering aperture is described by a Gaussian function with 
        % sigma equal to 0.204 x inner segment diameter (which here we assume is equal to the cone spacing).
        sigmaGaussian = 0.204;
        
        % Set cone aperture modifiers
        cm.coneApertureModifiers = struct(...
            'smoothLocalVariations', true, ...
            'apertureShape', 'Gaussian');
        
        % Save the generated mosaic
        mosaicFileName = coneMosaicFilename(monkeyID);
        save(mosaicFileName, 'cm');
    
   else
        mosaicFileName = coneMosaicFilename(monkeyID);
        load(mosaicFileName, 'cm');
        
        newConeApertureModifiers = cm.coneApertureModifiers;
        newConeApertureModifiers.smoothLocalVariations = true;
        newConeApertureModifiers.apertureShape = 'Gaussian';
        cm.coneApertureModifiers = newConeApertureModifiers;
        save(mosaicFileName, 'cm');
        
    end
    
    % Contrast the measured and the model cone diameters
    load('cone_data_M401_OS_2015.mat', 'cone_locxy_diameter');
    measuredConeDiameterData.horizontalEccMicrons = cone_locxy_diameter(:,1);
    measuredConeDiameterData.verticalEccMicrons = cone_locxy_diameter(:,2);
    measuredConeDiameterData.medianConeDiametersMicrons = cone_locxy_diameter(:,3);
    
    
    % Visualize the generated mosaic
    visualizationLimits = 130 * [-1 1 -1 1];
    domainVisualizationTicks =  struct(...
        'x', -150:50:150, ...
        'y', -150:50:150);
    
    hFig = figure(1);
    set(hFig, 'Color', [1 1 1], 'Position', [100 100 1000 500]);
    ax = subplot('Position', [0.07 0.05 0.4 0.9]);
    

    cm.visualize('figureHandle', hFig, 'axesHandle', ax, 'domain', 'microns', ...
        'domainVisualizationLimits', visualizationLimits, ...
        'domainVisualizationTicks', domainVisualizationTicks, ...
        'visualizedConeAperture', 'geometricArea', ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M401');
    
    ax = subplot('Position', [0.56 0.05 0.4 0.9]);
    % Visualize the achieved density map
    coneDensityLevelsConesPerMM2 = 100000:18200:250000;
    cm.visualize('figureHandle', hFig, 'axesHandle', ax, 'domain', 'microns', ...
                'domainVisualizationLimits', visualizationLimits, ...
                'domainVisualizationTicks', domainVisualizationTicks, ...
                'densityContourOverlay',true, ...
                'visualizeCones', false, ...
                'crossHairsOnFovea', true, ...
                'densityContourLevels', coneDensityLevelsConesPerMM2, ...
                'densityContourLevelLabelsDisplay', true, ...
                'densityColorMap', colormap(), ...
                'verticalDensityColorBar', true, ...
                'plotTitle', 'cone density map in ISETBio model of M401');
            
    contrastMeasuredAndModelConeDiameters(cm, measuredConeDiameterData);
end

function minSpacingMicrons = minConeSpacingMicrons
    % Load tabulated data for Williams lab monkey 401
    load('cone_data_M401_OS_2015.mat', 'cone_locxy_diameter');
    horizontalEccMicrons = cone_locxy_diameter(:,1);
    verticalEccMicrons = cone_locxy_diameter(:,2);
    medianConeDiameterMicronsRawData = cone_locxy_diameter(:,3);
    
    % Spacing is 5% larger than diameters
    medianConeSpacingMicronsRawData = medianConeDiameterMicronsRawData;
    
    [minSpacingMicrons, idx] = min(medianConeSpacingMicronsRawData );
    fprintf('Min cone spacing of raw data is at ecc: %f %f microns\n', horizontalEccMicrons(idx), verticalEccMicrons(idx));
    
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

