function plotExtractedDoGparams(theConeMosaic, DoGmodelParamsLcenterRGCs, DoGmodelParamsMcenterRGCs)

    
    if (nargin == 0) % ((isempty(DoGmodelParamsLconeRGCs)) && (isempty(DoGmodelParamsMconeRGCs)))
        p = extractedDoGParams();

        KcToKsRatiosLcenterRGCs = p.LcenterRGC.KcToKsRatios;
        RsToRcRatiosLcenterRGCs = p.LcenterRGC.RsToRcRatios;

        KcToKsRatiosMcenterRGCs = p.McenterRGC.KcToKsRatios;
        RsToRcRatiosMcenterRGCs = p.McenterRGC.RsToRcRatios;
    else
        KcToKsRatiosLcenterRGCs = DoGmodelParamsLcenterRGCs(:,3);
        RsToRcRatiosLcenterRGCs = DoGmodelParamsLcenterRGCs(:,2);
        RcMicronsLcenterRGCs = DoGmodelParamsLcenterRGCs(:,1);
        
        KcToKsRatiosMcenterRGCs = DoGmodelParamsMcenterRGCs(:,3);
        RsToRcRatiosMcenterRGCs = DoGmodelParamsMcenterRGCs(:,2);
        RcMicronsMcenterRGCs = DoGmodelParamsMcenterRGCs(:,1);
    end
    
    integratedSurroundToCenterRatiosLcenterRGCs = (1./KcToKsRatiosLcenterRGCs) .* (RsToRcRatiosLcenterRGCs).^2;
    integratedSurroundToCenterRatiosMcenterRGCs = (1./KcToKsRatiosMcenterRGCs) .* (RsToRcRatiosMcenterRGCs).^2;
    cellsNum = numel(RsToRcRatiosLcenterRGCs)+numel(RsToRcRatiosMcenterRGCs);
        
    
    rowsNum = 2;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.12, ...
           'leftMargin',     0.08, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.08, ...
           'topMargin',      0.02);
    
       
       [Rc, Rs] = CronerKaplanFig4Data();
       
       hFig = figure(999); clf;
       set(hFig, 'Position', [40 40 900 900], 'Color', [1 1 1]);
       ax = subplot('Position', sv(2,1).v);
       color  = [1 0.1 0.5];
       randomEccLcenter = 0.01+rand(1,numel(RcMicronsLcenterRGCs))*0.03;
       randomEccMcenter = 0.01+rand(1,numel(RcMicronsMcenterRGCs))*0.03;
       scatter(ax, randomEccLcenter, RcMicronsLcenterRGCs, 100, 'o', ...
           'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', color, 'MarkerEdgeColor', color*0.5);
       hold(ax, 'on');
       scatter(ax, randomEccLcenter, RcMicronsLcenterRGCs.*RsToRcRatiosLcenterRGCs, 100, 's', ...
           'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', color*0.75, 'MarkerEdgeColor', color*0.5);
       
       color  = [0.1 1 0.5];
       scatter(ax, randomEccMcenter, RcMicronsMcenterRGCs, 100, 'o', ...
           'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', color, 'MarkerEdgeColor', color*0.5);
       scatter(ax, randomEccMcenter, RcMicronsMcenterRGCs.*RsToRcRatiosMcenterRGCs, 100, 's', ...
           'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', color*0.75, 'MarkerEdgeColor', color*0.5);
       
       scatter(ax, Rc.eccDegs, Rc.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 100, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.2 0.2 0.2]);
       
       scatter(ax, Rs.eccDegs, Rs.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 100, 's', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0.2 0.2 0.2]);
    
       
       
       whichEye = 'right eye';
       useParfor = true;
       rfPosMicrons(:,1) = logspace(log10(1), log10(150), 100);
       rfPosMicrons(:,2) = rfPosMicrons(:,1)*0;
      
       [rfSpacingMicrons, eccentricitiesMicrons] = WilliamsLabData.constants.M838coneMosaicSpacingFunction(rfPosMicrons, whichEye, useParfor);
       coneRcMicrons = 0.204*rfSpacingMicrons*sqrt(2);
       plot(ax, eccentricitiesMicrons/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, coneRcMicrons, 'k-', 'LineWidth', 2);
       
       obj = WatsonRGCModel();
       eccSupport = logspace(log10(0.01), log10(100), 50);
       coneSpacingDegs = obj.coneRFSpacingAndDensityAlongMeridian(eccSupport, 'temporal meridian', 'deg', 'deg^2');
       coneSpacingMicrons = coneSpacingDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
       coneRcMicrons = 0.204*coneSpacingMicrons*sqrt(2);
       scatter(ax, eccSupport, coneRcMicrons, 64, 'filled', 'o', 'MarkerFaceAlpha', 0.3, 'MarkerFaceColor', [1 0.5 .2], 'MarkerEdgeColor', [1 0 0]);
       
       hL = legend(ax,...
           {'Rc (L-center RGCs)', 'Rs (L-center RGCs)', 'Rc (M-center RGCs)', 'Rs (M-center RGCs)', 'C&K''93 Rc', 'C&K''93 Rs', 'cone radius (M838)', 'cone radius (Curcio)'},...
           'Location', 'SouthEast');
       set(hL, 'color', 'none', 'Box', 'off');
       set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.01 0.03 0.1 0.3 1 3 10 30 100],  'XTickLabel', {'0.01', '0.03', '0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [0.3 1 3 10 30 100 300], 'YTickLabel', {'0.3', '1', '3', '10', '30', '100', '300'}, ...
         'XLim', [0.01 50], 'YLim', [0.3 100], 'FontSize', 16);
       axis(ax, 'square');
       grid(ax, 'on');
       xlabel(ax, 'eccentricity (degs)');
       ylabel(ax,'R(c/s) (microns)');
    
       
       
       
       ax = subplot('Position', sv(1,1).v);
       color  = [1 0.1 0.5];
       scatter(ax, 1:numel(RsToRcRatiosLcenterRGCs), 1./RsToRcRatiosLcenterRGCs, 196, 'o', 'filled', ...
           'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', color*0.5);
       hold(ax, 'on');
       
       color  = [0.1 1 0.5];
       scatter(ax, numel(RsToRcRatiosLcenterRGCs)+(1:numel(RsToRcRatiosMcenterRGCs)), 1./RsToRcRatiosMcenterRGCs, 196, 'o', 'filled', ...
           'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', color*0.5);
       axis(ax, 'square');
       grid(ax, 'on');
       nn = round(cellsNum/4);
       xTicks = 0:nn:cellsNum;
       set(ax, 'XLim', [0 cellsNum+1], 'XTick', xTicks, 'YLim', [0 1], ...
           'YTick',      0:0.1:1, ...
           'YScale', 'linear');
       xlabel(ax, 'cell index');
       ylabel(ax, 'Rc/Rs ratio');
       set(ax, 'FontSize', 16);
       
       
       ax = subplot('Position', sv(1,2).v);
       color  = [1 0.1 0.5];
       scatter(ax, 1:numel(RsToRcRatiosLcenterRGCs), 1./KcToKsRatiosLcenterRGCs, 196, 'o', 'filled', ...
            'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', color*0.5);
       hold(ax, 'on');
       
       color  = [0.1 1 0.5];
       scatter(ax, numel(RsToRcRatiosLcenterRGCs)+(1:numel(RsToRcRatiosMcenterRGCs)), 1./KcToKsRatiosMcenterRGCs, 196, 'o', 'filled', ...
           'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', color*0.5);
       axis(ax, 'square');
       
       set(ax, 'XLim', [0 cellsNum+1], 'XTick', xTicks, ...
           'YLim', [1e-4 1], ...
           'YTick',      [ .0001 .0003 .001    .003    .01    .03     .1      .3   1], ...
           'YTickLabel', {'.0001', '.0003', '.001', '.003', '.01', '.03', '0.1', '0.3', '1'}, ...
           'YScale', 'log');
       grid(ax, 'on');
       xlabel(ax, 'cell index');
       ylabel(ax, 'Ks/Kc ratio');
       set(ax, 'FontSize', 16);
       
       
%        ax = subplot('Position', sv(2,1).v);
%        color  = [1 0.1 0.5];
%        scatter(ax, 1./RsToRcRatiosLcenterRGCs, 1./KcToKsRatiosLcenterRGCs, 196, 'o', 'filled', ...
%            'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.65, 'MarkerEdgeColor', color*0.5);
%        hold(ax, 'on');
%        
%        color  = [0.1 1 0.5];
%        scatter(ax, 1./RsToRcRatiosMcenterRGCs, 1./KcToKsRatiosMcenterRGCs, 196, 'o', 'filled', ...
%            'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.65, 'MarkerEdgeColor', color*0.5);
%        xlabel(ax, 'Rc/Rs ratio');
%        ylabel(ax, 'Ks/Kc ratio');
%        grid(ax, 'on');
%        axis(ax, 'square');
%        set(ax, 'XLim', [0 1], 'XTick', 0:0.1:1, 'YLim', [1e-4 1], ...
%            'YTick',      [ .0001 .0003 .001    .003    .01    .03     .1      .3   1], ...
%            'YTickLabel', {'.0001', '.0003', '.001', '.003', '.01', '.03', '0.1', '0.3', '1'}, ...
%            'YScale', 'log');
%        set(ax, 'FontSize', 16, 'Color', 'none');
       
       ax = subplot('Position', sv(2,2).v);
       [nLcones, edges] = histcounts(integratedSurroundToCenterRatiosLcenterRGCs, 0:0.1:1.2);
       [nMcones, edges] = histcounts(integratedSurroundToCenterRatiosMcenterRGCs, 0:0.1:1.2);
       dx = 0.0*(edges(2)-edges(1));
       h = bar(ax, edges(1:end-1)+dx, [nLcones' nMcones'],1);
       h(1).FaceColor = [1 0.1 0.5];
       h(2).FaceColor = [0.1 1 0.5];
       h(1).FaceAlpha = 0.9;
       h(2).FaceAlpha = 0.9;
       axis(ax, 'square');
       set(ax, 'XLim', [0 1.1], 'XTick', 0:0.1:1.1, 'FontSize', 16, 'YTick', 0:5:100, 'YLim', [0 max([nLcones nMcones])+2]);
       grid(ax, 'on');
       xlabel(ax, 'integrated surround/center sensitivity');
       NicePlot.exportFigToPDF('DoGparams.pdf', hFig, 300);
end
