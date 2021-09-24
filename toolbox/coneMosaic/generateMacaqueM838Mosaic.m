function generateMacaqueM838Mosaic
% Generate a macaque cone mosaic based on the M838 cone density data
%
% Syntax:
%   generateMacaqueM838Mosaic
%
% Description: Generate a macaque cone mosaic based on the M838 cone spacing data
%              Also shows how to generate a cone mosaic using a custom cone
%              spacing function and custom retinal mm <-> visual angle degs
%              conversion functions.
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    if (1==1)
        sizeDegs = 1.2;  
        %sizeDegs = 1.1;  
        %sizeDegs = 1.0;  
        %sizeDegs = 0.85;
        %sizeDegs = 0.75; 
        %sizeDegs = 0.5;  
        
        cm = cMosaic(...
            'sizeDegs', sizeDegs*[1.0 1.0], ...                                          % SIZE: x=1.2 degs, y=1.2 degs
            'eccentricityDegs', [0.0 0], ...                                    % ECC:  x=0.0 degs, y= 0.0 degs
            'computeMeshFromScratch', true, ...                                 % generate mesh on-line
            'customMinRFspacing', minConeSpacingMicrons(), ...
            'customRFspacingFunction', @Williams838_spacingFunction, ...        % custom cone spacing function
            'customDegsToMMsConversionFunction', @Williams838_rhoDegsToMMs, ... % custom visual degs -> retinal mm conversion function
            'customMMsToDegsConversionFunction', @Williams838_rhoMMsToDegs, ... % customretinal  mm -> visual degs conversion function
            'micronsPerDegree', WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...   % custom mean microns per degree for macaque retina
            'coneDensities',  [0.48 0.48 0.04], ...                             % macaque cone density
            'tritanopicRadiusDegs', 0.0, ...                                    % no tritanopic area
            'randomSeed', randi(9999999), ...                                   % set the random seed, so at to generate a different mosaic each time
            'maxMeshIterations', 1000 ...                                       % stop iterative procedure after this many iterations
        );

    % Save the generated mosaic
    rootDirName = ISETmacaqueRootPath();
    mosaicFileName = fullfile(rootDirName, 'dataResources/coneMosaicM838.mat');
    save(mosaicFileName, 'cm');
    
    else
        rootDirName = ISETmacaqueRootPath();
        mosaicFileName = fullfile(rootDirName, 'dataResources/coneMosaicM838.mat');
        load(mosaicFileName, 'cm');
    end
    
    contrastConeDiameters(cm);
    
        
    visualizationLimits = [-100 100 -100 100];
    domainVisualizationTicks =  struct(...
        'x', visualizationLimits(1):50:visualizationLimits(2), ...
        'y', visualizationLimits(3):50:visualizationLimits(4));
    
    % Visualize the generated mosaic
    cm.visualize('domain', 'microns', ...
        'domainVisualizationLimits', visualizationLimits, ...
        'domainVisualizationTicks', domainVisualizationTicks, ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M401');
    
    % Visualize the achieved density map
    coneDensityLevelsConesPerMM2 = 70000:18200:290000;
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', visualizationLimits, ...
                'domainVisualizationTicks', domainVisualizationTicks, ...
                'densityContourOverlay',true, ...
                'labelCones', false, ...
                'crossHairsOnFovea', true, ...
                'densityContourLevels', coneDensityLevelsConesPerMM2, ...
                'densityContourLevelLabelsDisplay', true, ...
                'densityColorMap', colormap(), ...
                'verticalDensityColorBar', true);
end


function contrastConeDiameters(cm)
     % Load tabulated data for Williams lab monkey 838
    load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
    horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
    verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
    medianConeDiameterMicronsRawData = cone_locxy_diameter_838OD(:,3);
    medianConeDiameterMicronsModel = zeros(1, numel(medianConeDiameterMicronsRawData));
    
    roiWidthMicrons = 5;
    roiHeightMicrons = 5;
    
    for iPos = 1:numel(horizontalEccMicrons)
        xoMicrons = horizontalEccMicrons(iPos);
        yoMicrons = verticalEccMicrons(iPos);
            
        roi = struct(...
            'shape', 'ellipse', ...
            'units', 'microns', ...
            'center', [xoMicrons yoMicrons], ...
            'rotation', 0, ...
            'minorAxisDiameter', roiWidthMicrons, ...
            'majorAxisDiameter', roiHeightMicrons);

        roi = struct(...
            'shape', 'rect', ...
            'units', 'microns', ...
            'center', [xoMicrons yoMicrons], ...
            'width', roiWidthMicrons, ...
            'height', roiHeightMicrons);

        idx = cm.indicesOfConesWithinROI(roi);
        
        medianConeDiameterMicronsModel(iPos) = median(cm.coneRFspacingsMicrons(idx));
    end
    
    min1 = min(medianConeDiameterMicronsRawData);
    min2 = min(medianConeDiameterMicronsModel);
    max1 = max(medianConeDiameterMicronsRawData);
    max2 = max(medianConeDiameterMicronsModel);
    
    diameterRange = [min([min1 min2]) max([max1 max2])];
    figure();
    plot(medianConeDiameterMicronsRawData, medianConeDiameterMicronsModel, 'k.');
    hold on;
    plot([diameterRange(1) diameterRange(2)], [diameterRange(1) diameterRange(2)], 'r-');
    set(gca, 'XLim', diameterRange, 'YLim', diameterRange);
    axis 'square';
    xlabel('median cone diameter (microns) - data');
    ylabel('median cone diameter (microns) - model');
end


function minSpacingMicrons = minConeSpacingMicrons
     % Load tabulated data for Williams lab monkey 838
    load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
    horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
    verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
    medianConeDiameterMicronsRawData = cone_locxy_diameter_838OD(:,3);
    
    % Spacing is 5% larger than diameters
    medianConeSpacingMicronsRawData = 1.05 * medianConeDiameterMicronsRawData;
    
    [minSpacingMicrons, idx] = min(medianConeSpacingMicronsRawData );
    fprintf('Min cone spacing of raw data is at ecc: %f %f microns\n', horizontalEccMicrons(idx), verticalEccMicrons(idx));
    
end

% Custom cone spacing function specific to monkey 838 from the Williams lab
function [rfSpacingMicrons, eccentricitiesMicrons] = Williams838_spacingFunction(rfPosMicrons, whichEye, useParfor)

    % Load tabulated data for Williams lab monkey 838
    load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
    horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
    verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
    coneDiameterMicrons = cone_locxy_diameter_838OD(:,3);
    
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

% Degs -> MM conversion function specific to monkey 838
function eccMMs = Williams838_rhoDegsToMMs(eccDegs)
% Convert retinal distance in degs to retinal distance in mm
    eccMicrons = eccDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    eccMMs = eccMicrons / 1e3;
end

% MM -> Degs conversion function specific to monkey 838
function eccDegs = Williams838_rhoMMsToDegs(eccMMs)
% Convert retinal distance in MMs to retinal distance in degs
    eccDegs = eccMMs * 1e3 / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
end

