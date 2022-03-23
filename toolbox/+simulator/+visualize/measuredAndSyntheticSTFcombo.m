function measuredAndSyntheticSTFcombo(measuredSTFdataStruct, ...
    modelMeasuredSTFdataStruct, syntheticSTFdataStruct, ...
    modelSyntheticSTFdataStruct, titleString, pdfFileName)

    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 10 660 1190]);
    ax = subplot('Position', [0.12 0.10 0.86 0.85]);
    
    % The AOSLO derived STF
    p1 = plot(ax, measuredSTFdataStruct.sf, measuredSTFdataStruct.val, 'ko',  ...
        'MarkerSize', 20, 'MarkerEdgeColor',  [0 0. 0.], ...
        'MarkerFaceColor', [0.8 0.8 0.8],'LineWidth', 1.5);
    set(ax, 'YColor', 'k');
    hold(ax, 'on');
    plot(ax,modelMeasuredSTFdataStruct.sf, modelMeasuredSTFdataStruct.val, 'k-', ...
        'Color', [0.5 0.5 0.5], 'LineWidth', 4.0);
    p2 = plot(ax,modelMeasuredSTFdataStruct.sf, modelMeasuredSTFdataStruct.val, 'k-', ...
        'LineWidth', 2.0);
    
    % The physiological optics derived STFs
    p3 = plot(ax, syntheticSTFdataStruct.sf,  syntheticSTFdataStruct.val, 'ko', ...
        'MarkerSize', 20,  'MarkerEdgeColor',  [1.0 0. 0.], 'MarkerFaceColor',  [1.0 0.5 0.5],'LineWidth', 1.5);
    
    % The physiological optics derived STFs DoG model fit
    plot(ax, modelSyntheticSTFdataStruct.sf, modelSyntheticSTFdataStruct.val, 'r-', 'LineWidth', 4.0, 'Color', [1 0.5 0.5]);
    p4 = plot(ax, modelSyntheticSTFdataStruct.sf, modelSyntheticSTFdataStruct.val, 'r-', 'LineWidth', 2.0);
    
    lgd = legend(ax,[p1 p2 p3 p4], ...
        {measuredSTFdataStruct.legend,modelMeasuredSTFdataStruct.legend,...
        syntheticSTFdataStruct.legend, modelSyntheticSTFdataStruct.legend}, ...
        'FontSize', 16);
    set(lgd,'Box','off');
    
    maxY = max([max(measuredSTFdataStruct.val) max(modelMeasuredSTFdataStruct.val)]);
    if (maxY < 0.4)
        maxY = 0.1+round(10*maxY)/10;
    else
        maxY = round(10*(1.2*maxY))/10;
    end
    
    set(ax, 'XScale', 'log', 'FontSize', 40);
    set(ax, 'XLim', [3 70], 'XTick', [2 5 10 20 40 60], 'YLim', [-0.05 maxY], 'YTick', -0.1:0.05:0.8, ...
        'YTickLabel', {'-0.1', '', '0', '', '0.1', '', '0.2', '', '0.3', '', '0.4', '', '0.5', '', '0.6', '', '0.7', '', 0.8});
    grid(ax, 'on');
    box(ax, 'off');
    xlabel(ax,'spatial frequency (c/deg)');
    title(ax,titleString);
    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);
    
end

