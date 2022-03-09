function generate(monkeyID, reCompute)
% Generate a macaque cone mosaic based on an animal's cone density data
%
% Syntax:
%   simulator.coneMosaic.compute(monkeyID)
%
% Description: Generate a macaque cone mosaic based on an animals' cone spacing data
%              Also shows how to generate a cone mosaic using a custom cone
%              spacing function and custom retinal mm <-> visual angle degs
%              conversion functions.
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021


    if (reCompute)
        sizeDegs = 1.3;  
        
        % Cone aperture modifiers
        % The cone light gathering aperture is described by a Gaussian function with 
        % sigma equal to 0.204 x inner segment diameter (cone diameter)
        sigmaGaussian = 0.204;  % From McMahon et al, 2000

        % Set cone aperture modifiers
        coneApertureModifiers = struct(...
            'smoothLocalVariations', true, ...
            'sigma',  sigmaGaussian, ...
            'shape', 'Gaussian');
        
        cm = cMosaic(...
            'sizeDegs', sizeDegs*[1.0 1.0], ...                                 % SIZE: x=1.2 degs, y=1.2 degs
            'eccentricityDegs', [0.0 0], ...                                    % ECC:  x=0.0 degs, y= 0.0 degs
            'computeMeshFromScratch', true, ...                                 % generate mesh on-line
            'coneDiameterToSpacingRatio', WilliamsLabData.constants.coneDiameterToConeSpacingRatio, ...
            'customMinRFspacing', WilliamsLabData.constants.M838coneMosaicMinConeSpacingMicrons(), ...
            'customRFspacingFunction', @WilliamsLabData.constants.M838coneMosaicSpacingFunction, ...        % custom cone spacing function
            'customDegsToMMsConversionFunction', @WilliamsLabData.constants.M838coneMosaicRhoDegsToMMs, ... % custom visual degs -> retinal mm conversion function
            'customMMsToDegsConversionFunction', @WilliamsLabData.constants.M838coneMosaicRhoMMsToDegs, ... % customretinal  mm -> visual degs conversion function
            'coneApertureModifiers', coneApertureModifiers, ...
            'eccVaryingConeAperture', true, ...
            'eccVaryingConeBlur', true, ...
            'coneDensities',  [0.48 0.48 0.04], ...                             % macaque cone density
            'tritanopicRadiusDegs', 0.0, ...                                    % no tritanopic area
            'randomSeed', randi(9999999), ...                                   % set the random seed, so at to generate a different mosaic each time
            'maxMeshIterations', 1000 ...                                       % stop iterative procedure after this many iterations
        );
        
        % Save the generated mosaic
        mosaicFileName = simulator.filename.coneMosaic(monkeyID);
        save(mosaicFileName, 'cm');
    
    else
        % Load the generated mosaic
        mosaicFileName = simulator.filename.coneMosaic(monkeyID);
        load(mosaicFileName, 'cm');
    end
    
    
    % Contrast the measured and the model cone diameters
    load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
    measuredConeDiameterData.horizontalEccMicrons = cone_locxy_diameter_838OD(:,1);
    measuredConeDiameterData.verticalEccMicrons = cone_locxy_diameter_838OD(:,2);
    measuredConeDiameterData.medianConeDiametersMicrons = cone_locxy_diameter_838OD(:,3);
    
    
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
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'backgroundColor', [0 0 0], ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M838');
    
    ax = subplot('Position', [0.56 0.05 0.4 0.9]);
    % Visualize the achieved density map
    coneDensityLevelsConesPerMM2 = 70000:18200:290000;
    cm.visualize('figureHandle', hFig, 'axesHandle', ax, 'domain', 'microns', ...
                'domainVisualizationLimits', visualizationLimits, ...
                'domainVisualizationTicks', domainVisualizationTicks, ...
                'densityContourOverlay',true, ...
                'visualizeCones', false, ...
                'crossHairsOnFovea', true, ...
                'densityContourLevels', coneDensityLevelsConesPerMM2, ...
                'densityContourLevelLabelsDisplay', true, ...
                'densityColorMap', colormap(), ...
                'verticalDensityColorBar', ~true, ...
                'plotTitle', 'cone density map in ISETBio model of M838');
            
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', [-10 10 -10 10], ...
                'domainVisualizationTicks', struct('x', -10:2:10, 'y', -10:2:10), ...
                'visualizedConeAperture', 'lightCollectingArea4sigma', ...
                'visualizedConeApertureThetaSamples', 60, ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M838 - cone apertures (4 * sigma)');
    
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', [-10 10 -10 10], ...
                'domainVisualizationTicks', struct('x', -10:2:10, 'y', -10:2:10), ...
                'visualizedConeAperture', 'lightCollectingArea6sigma', ...
                'visualizedConeApertureThetaSamples', 60, ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M838 - cone apertures (6 * sigma)');
    
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', [-10 10 -10 10], ...
                'domainVisualizationTicks', struct('x', -10:2:10, 'y', -10:2:10), ...
                'visualizedConeAperture', 'geometricArea', ...
                'visualizedConeApertureThetaSamples', 60, ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M838 - cone diameters');
    
    cm.visualize('domain', 'microns', ...
                'domainVisualizationLimits', [-10 10 -10 10], ...
                'domainVisualizationTicks', struct('x', -10:2:10, 'y', -10:2:10), ...
                'visualizedConeAperture', 'coneSpacing', ...
                'visualizedConeApertureThetaSamples', 60, ...
        'labelCones', true, 'plotTitle', 'ISETBio modeling of M838 - cone spacings');
    
    
    simulator.analyze.measuredVsModelConeDiameters(cm, measuredConeDiameterData);
end




