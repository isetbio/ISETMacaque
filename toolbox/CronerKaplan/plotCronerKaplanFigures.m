function plotCronerKaplanFigures()
    generateFigure5B();
    generateFigure13A();
    generateFigure4(); 
   
    generateCenterRadiiHistogramsFigure();
end

function generateFigure4()
    [Rc, Rs] = CronerKaplanFig4Data();
    
    rowsNum = 1;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.07, ...
           'leftMargin',     0.06, ...
           'rightMargin',    0.02, ...
           'bottomMargin',   0.07, ...
           'topMargin',      0.02);
       
    % Generate figure
    hFig = figure(4); clf;
    set(hFig, 'Position', [10 10 1000 500], 'Color', [1 1 1]);
     
    ax = subplot('Position', sv(1,1).v);
    scatter(ax, Rc.eccDegs, Rc.radiusDegs, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, ...
        'MarkerFaceColor', [1 0.1 0.3], 'MarkerEdgeColor', [1 0 0]);
    eccSupport = logspace(log10(0.01), log10(100), 100);
    obj = WatsonRGCModel();
    coneSpacingDegs = obj.coneRFSpacingAndDensityAlongMeridian(eccSupport, 'temporal meridian', 'deg', 'deg^2');
    coneRadiusMicrons = coneSpacingDegs/2*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    
    hold(ax, 'on');
    scatter(ax, Rs.eccDegs, Rs.radiusDegs, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, ...
        'MarkerFaceColor', [0.3 0.1 1], 'MarkerEdgeColor', [0 0 1]);
    plot(ax, eccSupport, coneSpacingDegs/2, 'k-', 'LineWidth', 1.5);
    legend(ax,{'center', 'surround', 'cone radius'});
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.1 0.3 1 3 10 30 100], 'XTickLabel', {'0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [0.01 0.03 0.1 0.3 1 3 10], 'YTickLabel', {'0.01', '0.03', '0.1', '0.3', '1', '3', '10'}, ...
         'XLim', [0.1 100], 'YLim', [0.01 10], 'FontSize', 16);
    axis(ax,'square');
    grid(ax, 'on');
    xlabel(ax, 'eccentricity (degs)');
    ylabel(ax,'visual Rc/Rs (deg)');
   
    
    ax = subplot('Position', sv(1,2).v);
    scatter(ax, Rc.eccDegs, Rc.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 169, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [1 0.1 0.3], 'MarkerEdgeColor', [1 0 0]);
    hold(ax, 'on');
    scatter(ax, Rs.eccDegs, Rs.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 169, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.3 0.1 1], 'MarkerEdgeColor', [0 0 1]);
    
    
    whichEye = 'right eye';
    useParfor = true;
    rfPosMicrons(:,1) = logspace(log10(1), log10(100), 100);
    rfPosMicrons(:,2) = rfPosMicrons(:,1)*0;
    [rfSpacingMicrons, eccentricitiesMicrons] = WilliamsLabData.constants.M838coneMosaicSpacingFunction(rfPosMicrons, whichEye, useParfor);
    plot(ax, eccentricitiesMicrons/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, rfSpacingMicrons/2, 'k-', 'LineWidth', 1.5);
    plot(ax, eccSupport, coneRadiusMicrons, 'k--', 'LineWidth', 1.5);
    
    legend(ax,{'center', 'surround', 'cone radius (M838)', 'coneRadius (Curcio)'});
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.1 0.3 1 3 10 30 100],  'XTickLabel', {'0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [1 3 10 30 100 300 1000]*2, 'YTickLabel', {'2', '6', '20', '60', '200', '600', '2000'}, ...
         'XLim', [0.1 100], 'YLim', [2 2000], 'FontSize', 16);
    axis(ax,'square');
    grid(ax, 'on');
    xlabel(ax, 'eccentricity (degs)');
    ylabel(ax,'visual Rc/Rs (microns)');
    
end


function generateCenterRadiiHistogramsFigure()
    % Get the data
    [~, retinalRcDegs, PcellDendriticTreeRadii] = CronerKaplanFig13Data();
    PcellRcDegs = PcellDendriticTreeRadii.RcDegs;
    [visualRcDegs,~] = CronerKaplanFig5BData();
    
    [Rc, Rs] = CronerKaplanFig4Data();
    visualRcDegs = cat(1, visualRcDegs, Rc.radiusDegs);
    
    retinalRcMicrons = retinalRcDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    visualRcMicrons = visualRcDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    PcellRcMicrons = PcellRcDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    
    rowsNum = 3;
    colsNum = 1;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.08, ...
           'rightMargin',    0.02, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.02);
    
    RcMicronsBins = 0.5:0.5:20;
       
    % Generate figure
    hFig = figure(3); clf;
    set(hFig, 'Position', [100 10 500 1300], 'Color', [1 1 1]);
    
    ax = subplot('Position', sv(1,1).v);
    [counts,rcMicrons] = histcounts(visualRcMicrons,RcMicronsBins);
    bar(ax,rcMicrons(1:end-1), counts, 1.0, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', [0 0 0]);
    xlabel(ax, 'visual Rc (microns)');
    set(ax, 'XLim', [-1 RcMicronsBins(end)],'XTick', 0:2:100, 'FontSize', 16);
    
    ax = subplot('Position', sv(2,1).v);
    [counts,rcMicrons] = histcounts(retinalRcMicrons,RcMicronsBins);
    bar(ax,rcMicrons(1:end-1), counts, 1.0, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', [0 0 0]);
    xlabel(ax, 'retinal Rc (microns)');
    set(ax, 'XLim', [-1 RcMicronsBins(end)],'XTick', 0:2:100, 'FontSize', 16);
    
    ax = subplot('Position', sv(3,1).v);
    [counts,rcMicrons] = histcounts(PcellRcMicrons,RcMicronsBins);
    bar(ax,rcMicrons(1:end-1), counts, 1.0, 'FaceColor', [1 0.5 0.1], 'FaceAlpha', 0.5, 'EdgeColor', [1 0 0]);
    xlabel(ax, 'P cell dendritic tree radius (microns)');
    set(ax, 'XLim', [-1 RcMicronsBins(end)],'XTick', 0:2:100, 'FontSize', 16);
    
end


function generateFigure13A()
    % Get the data
    [eccentricityDegs, retinalRcDegs, PcellDendriticTreeRadii] = CronerKaplanFig13Data();
    
    rowsNum = 1;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.07, ...
           'leftMargin',     0.06, ...
           'rightMargin',    0.02, ...
           'bottomMargin',   0.07, ...
           'topMargin',      0.02);
       
    % Generate figure
    hFig = figure(2); clf;
    set(hFig, 'Position', [100 10 1000 500], 'Color', [1 1 1]);
    ax = subplot('Position', sv(1,1).v);
    scatter(ax,eccentricityDegs, retinalRcDegs, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0 0 0]);
    hold(ax,'on');
    scatter(ax,PcellDendriticTreeRadii.eccDegs, PcellDendriticTreeRadii.RcDegs, 133, ...
        'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [1 0.5 0.1], 'MarkerEdgeColor', [1 0 0]);
    legend(ax,{'retinal Rc', 'Pcell denritic radii'});
    set(ax, 'Xscale', 'linear', 'YScale', 'linear', ...
         'XTick', 0:10:50, ...
         'YTick', 0:0.1:0.3, ...
         'XLim', [0 40], 'YLim', [0 0.3], 'FontSize', 16);
    axis(ax,'square');
    grid(ax,'on');
    xlabel(ax,'eccentricity (deg)');
    ylabel(ax,'Rc (degs)');
    

    ax = subplot('Position', sv(1,2).v);
    scatter(ax,eccentricityDegs, retinalRcDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0 0 0]);
    hold(ax,'on');
    scatter(ax,PcellDendriticTreeRadii.eccDegs, PcellDendriticTreeRadii.RcDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 133, ...
        'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [1 0.5 0.1], 'MarkerEdgeColor', [1 0 0]);
    legend(ax,{'retinal Rc', 'Pcell denritic radii'}, 'Location', 'SouthWest');
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.1 0.3 1 3 10 30 100],  'XTickLabel', {'0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [0.3 1 3 10 30], 'YTickLabel', {'0.3' '1' '3' '10' '30'}, ...
         'XLim', [0.4 40], 'YLim', [0.4 40], 'FontSize', 16);
     
     
    axis(ax,'square');
    grid(ax,'on');
    xlabel(ax,'eccentricity (deg)');
    ylabel(ax,'Rc (microns)');
    
    
end

function generateFigure5B()

    % Get the data
    [RcDegs, Kc] = CronerKaplanFig5BData();
    
    rowsNum = 1;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.07, ...
           'leftMargin',     0.06, ...
           'rightMargin',    0.02, ...
           'bottomMargin',   0.07, ...
           'topMargin',      0.02);
       
    % Generate figure
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1000 500], 'Color', [1 1 1]);
     
    ax = subplot('Position', sv(1,1).v);
    scatter(ax, RcDegs, Kc, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0 0 0]);
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.01 0.03 0.1 0.3 1], 'XTickLabel', {'0.01', '0.03', '0.1', '0.3', '1.0'}, ...
         'YTick', [1 3 10 30 100 300 1000], 'YTickLabel', {'1', '3', '10', '30', '100', '300', '1000'}, ...
         'XLim', [0.01 1], 'YLim', [1 1000], 'FontSize', 16);
    axis(ax,'square');
    grid(ax, 'on');
    xlabel(ax,'Rc (deg)');
    ylabel(ax, 'Kc');
    
    ax = subplot('Position', sv(1,2).v);
    scatter(ax, RcDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, Kc, 169, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0 0 0]);
    set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [1 3 10 30 100 300], 'XTickLabel', {'1', '3', '10', '30', '100', '300'}, ...
         'YTick', [1 3 10 30 100 300 1000], 'YTickLabel', {'1', '3', '10', '30', '100', '300', '1000'}, ...
         'XLim', [1 200], 'YLim', [1 1000], 'FontSize', 16);
    axis(ax,'square');
    grid(ax, 'on');
    xlabel(ax,'Rc (microns)');
    ylabel(ax, 'Kc');
    
end


    