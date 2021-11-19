function plotRetinalRCsTogetherWithCronerKaplanRetinalRCs(modelConeMeasuredCharacteristicRadiiMicrons, freeRcFitsMicrons)

    % Get the data
    [eccentricityDegs, retinalRcDegs, PcellDendriticTreeRadii] = CronerKaplanFig13Data();
    
    hFig = figure(1000); clf;
    set(hFig, 'Position', [10 10 500 500], 'Color', [1 1 1]);
    ax = subplot('Position', [0.1 0.1 0.89 0.89]);
    
    scatter(ax,eccentricityDegs, retinalRcDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 169, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0 0 0]);
    hold(ax,'on');
    scatter(ax,PcellDendriticTreeRadii.eccDegs, PcellDendriticTreeRadii.RcDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 133, ...
        'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [1 0.5 0.1], 'MarkerEdgeColor', [1 0 0]);
    
    % The ISETBio cone characteristic radii
    scatter(ax, 0.01 + rand(1,numel(modelConeMeasuredCharacteristicRadiiMicrons))*0.03, modelConeMeasuredCharacteristicRadiiMicrons, 200, 'o',...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.1 0.8 0.5], 'MarkerEdgeColor', [0 0.5 0]);
        
    % The freeRc fit characteristic radii
    scatter(ax, 0.01 + rand(1,numel(freeRcFitsMicrons))*0.03, freeRcFitsMicrons, 200, 's',...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.1 0.5 0.8], 'MarkerEdgeColor', [0 0 0.5]);
   
    
    legend(ax,{'retinal Rc (Croner&Kaplan ''93)', 'Pcell denritic radii (Perry et al. ''84)', 'ISETBio model cones', 'M838 deltaF/Fo'}, ...
        'Location', 'NorthWest');
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.01 0.03 0.1 0.3 1 3 10 30 100],  'XTickLabel', {'0.01', '0.03', '0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [0.3 1 3 10 30], 'YTickLabel', {'0.3' '1' '3' '10' '30'}, ...
         'XLim', [0.01 40], 'YLim', [0.4 40], 'FontSize', 16);
     
     
    %axis(ax,'square');
    grid(ax,'on');
    xlabel(ax,'eccentricity (deg)');
    ylabel(ax,'Rc (microns)');
    drawnow;
end
