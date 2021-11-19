% Regenerate Figure 6 of McGregor et al (2018)
%  
% Syntax:
%   regenerateFigure6();
%
% Description: Regenerate Figure 6 of McGregor et al (2018) "Functional architecture of the
% foveola revealed in the living primate", doi: 10.1371/journal.pone.0207102
% Also contrast the measured density to the density achieved by the ISETBio
% synthesized mosaic .
%     
%

% History:
%    08/11/21  NPC  ISETBIO Team, Copyright 2021 Wrote it.


function regenerateFigure6()
    % Load the data
    [xMicrons, yMicrons, coneDensityMapConesPerMM2] = getData();
    
    % Spatial support and contour levels
    [xGridMicrons, yGridMicrons] = meshgrid(xMicrons, yMicrons);
    xGridDegs = xGridMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    yGridDegs = yGridMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    
    coneDensityLevelsConesPerMM2 = 100000:18200:250000;
    %coneDensityLevelsConesPerMM2 = 40000:18200:250000;
    
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1662 819]);
    % Plot the cone density map in retinal microns
    ax = subplot('Position', [0.56 0.05 0.40 0.94]);
    contourf(xGridMicrons, yGridMicrons, coneDensityMapConesPerMM2, coneDensityLevelsConesPerMM2 );
    hold on;
    plot([xGridMicrons(1) xGridMicrons(end)], [0 0], 'k-');
    plot([0 0], [yGridMicrons(1) yGridMicrons(end)], 'k-');
    axis 'image'
    set(gca, 'XTick', -200:50:200, 'YTick', -200:50:200, 'FontSize', 20, 'XLim', 120*[-1 1], 'YLim', 120*[-1 1]);
    xlabel('(nasal retina)  < ----- eccentricity (microns)  ---- > (temporal retina)');
    ylabel('(ingerior retina)  < ------- eccentricity (microns)    -----> (superior retina)');
    title('measured density data, central segment (m401)');
    
    colorbar
    
    % Plot the cone density map in degrees
    ax = subplot('Position', [0.06 0.05 0.40 0.94]);
    contourf(xGridDegs,yGridDegs, coneDensityMapConesPerMM2, coneDensityLevelsConesPerMM2);
    hold on;
    plot([xGridDegs(1) xGridDegs(end)], [0 0], 'k-');
    plot([0 0], [yGridDegs(1) yGridDegs(end)], 'k-');
    xtickDegs = round((-200:50:200)/WilliamsLabData.constants.micronsPerDegreeRetinalConversion *100)/100;
    ytickDegs = round((-200:50:200)/WilliamsLabData.constants.micronsPerDegreeRetinalConversion *100)/100;
    set(gca, 'XTick', xtickDegs, 'YTick', ytickDegs, 'FontSize', 20);
    xlabel('(nasal retina)  < ----- eccentricity (degrees)  ---- > (temporal retina)');
    ylabel('(inferior retina)  < ------- eccentricity (degrees)    -----> (superior retina)');
    colorbar
    axis 'image'
    title('measured density data, full range (m401)');
    
    rootDirName = ISETmacaqueRootPath();
    mosaicFileName = fullfile(rootDirName, 'dataResources/coneMosaicM401.mat');
    load(mosaicFileName, 'cm');
    
    hFig = figure(2); clf;
    set(hFig, 'Position', [10 10 1662 819]);
    % Plot the cone density map in retinal microns
    ax = subplot('Position', [0.55 0.05 0.40 0.94]);
    
    % Visualize the generated mosaic
    cm.visualize('figureHandle', hFig, 'axesHandle', ax, 'domain', 'microns', ...
        'domainVisualizationLimits', [-120 120 -120 120], ...
        'domainVisualizationTicks', struct('x', -150:50:150, 'y', -150:50:150), ...
        'fontSize', 20, ...
        'labelCones', true, 'plotTitle', 'synthesized mosaic (based on M401 density data)');
    
    % Visualize the achieved density map
    ax = subplot('Position', [0.05 0.05 0.40 0.94]);
    cm.visualize('figureHandle', hFig, 'axesHandle', ax,  'domain', 'microns', ...
                'domainVisualizationLimits', [-120 120 -120 120], ...
                'domainVisualizationTicks', struct('x', -150:50:150, 'y', -150:50:150), ...
                'densityContourOverlay',true, ...
                'labelCones', false, ...
                'crossHairsOnFovea', true, ...
                'densityContourLevels', coneDensityLevelsConesPerMM2, ...
                'densityContourLevelLabelsDisplay', true, ...
                'densityColorMap', colormap(), ...
                'verticalDensityColorBar', true, ...
                'fontSize', 20, ...
                'plotTitle', 'density plot of synthesized mosaic');
            
    
end

function [xMicrons, yMicrons, coneDensityMapConesPerMM2] = getData()
    % Load the cone mosaic data from animal 401, studied in McGregor et al,
    % 
    load('cone_data_M401_OS_2015.mat', 'cone_locxy_diameter');
    horizontalEccMicrons = cone_locxy_diameter(:,1);
    verticalEccMicrons = cone_locxy_diameter(:,2);
    coneDiameterMicrons = cone_locxy_diameter(:,3);
    coneSpacingMicrons = coneDiameterMicrons;
    
    % Compute density from cone spacing assuming a perfect hegagonal grid
    coneDensity = RGCmodels.Watson.convert.spacingToDensityForHexGrid( coneSpacingMicrons/1e3);
    
    % Interpolate density map on a uniform grid
    interpolationMethod = 'linear';
    extrapolationMethod = 'linear';
    F = scatteredInterpolant(horizontalEccMicrons,verticalEccMicrons, coneDensity, ...
        interpolationMethod, extrapolationMethod);
    
    % Spatial support
    xMicrons = -200:4:200; yMicrons = -150:4:150;
    
    % Uniform grid
    [xq, yq] = meshgrid(xMicrons,yMicrons);
    
    % Intepolate
    coneDensityMapConesPerMM2 = F(xq,yq);
    
    
%     figure(1);
%     subplot(1,3,1)
%     plot(horizontalEccMicrons(:), verticalEccMicrons, 'ko');
%     axis 'image'
%     set(gca, 'XTick', -200:50:200, 'YTick', -200:50:200, 'FontSize', 14);
    
end
