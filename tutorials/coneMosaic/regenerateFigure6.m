% Regenerate Figure 6 of McGregor et al (2018) "Functional architecture of the
% foveola revealed in the living primate", doi: 10.1371/journal.pone.0207102
%
% Syntax:
%   regenerateFigure6();
%
% Description:
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
    
    figure(1); clf;
    % Plot the cone density map in retinal microns
    subplot(1,2,1);
    contourf(xGridMicrons, yGridMicrons, coneDensityMapConesPerMM2, coneDensityLevelsConesPerMM2 );
    hold on;
    plot([xGridMicrons(1) xGridMicrons(end)], [0 0], 'k-');
    plot([0 0], [yGridMicrons(1) yGridMicrons(end)], 'k-');
    set(gca, 'XTick', -200:50:200, 'YTick', -200:50:200, 'FontSize', 14);
    xlabel('retinal eccentricity (microns)');
    ylabel('retinal eccentricity (microns)');
    axis 'image'
    colorbar
    
    % Plot the cone density map in degrees
    subplot(1,2,2)
    contourf(xGridDegs,yGridDegs, coneDensityMapConesPerMM2, coneDensityLevelsConesPerMM2);
    hold on;
    plot([xGridDegs(1) xGridDegs(end)], [0 0], 'k-');
    plot([0 0], [yGridDegs(1) yGridDegs(end)], 'k-');
    xtickDegs = round((-200:50:200)/WilliamsLabData.constants.micronsPerDegreeRetinalConversion *100)/100;
    ytickDegs = round((-200:50:200)/WilliamsLabData.constants.micronsPerDegreeRetinalConversion *100)/100;
    set(gca, 'XTick', xtickDegs, 'YTick', ytickDegs, 'FontSize', 14);
    xlabel('retinal eccentricity (degrees)');
    ylabel('retinal eccentricity (degrees)');
    colorbar
    axis 'image'
    
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
    F = scatteredInterpolant(horizontalEccMicrons,verticalEccMicrons, coneDensity);
    
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
