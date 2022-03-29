function measuredAndSyntheticSTFcombo(measuredSTFdataStruct, ...
    modelMeasuredSTFdataStruct, syntheticSTFdataStruct, ...
    modelSyntheticSTFdataStruct, titleString, pdfFileName)

    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 10 1500 1190]);

    ax1 = subplot('Position', [0.05 0.10 0.43 0.88]);
    ax2 = subplot('Position', [0.55 0.10 0.43 0.88]);

    
    maxY = max(modelMeasuredSTFdataStruct.valCenterSTF);

    if (maxY < 0.4)
        maxY = 0.1+round(10*maxY)/10;
    else
        maxY = ceil(10*maxY)/10;
    end

    showCenterSurroundComponents = true;
    plotFigure(ax1, maxY, showCenterSurroundComponents, measuredSTFdataStruct, ...
        modelMeasuredSTFdataStruct, syntheticSTFdataStruct, ...
        modelSyntheticSTFdataStruct, titleString);



    maxY = max(modelMeasuredSTFdataStruct.val);
    maxY = max([maxY max(measuredSTFdataStruct.val)]);
    if (maxY < 0.4)
        maxY = 0.1+round(10*maxY)/10;
    else
        maxY = ceil(10*maxY)/10;
    end
    showCenterSurroundComponents = false;
    plotFigure(ax2, maxY, showCenterSurroundComponents, measuredSTFdataStruct, ...
        modelMeasuredSTFdataStruct, syntheticSTFdataStruct, ...
        modelSyntheticSTFdataStruct, titleString);

    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);

end

function plotFigure(ax, maxY, showCenterSurroundComponents, measuredSTFdataStruct, ...
    modelMeasuredSTFdataStruct, syntheticSTFdataStruct, ...
    modelSyntheticSTFdataStruct, titleString)
    

    % The AOSLO measured STF
    p1 = plot(ax, measuredSTFdataStruct.sf, measuredSTFdataStruct.val, 'ko',  ...
        'MarkerSize', 20, 'MarkerEdgeColor',  [0 0. 0.], ...
        'MarkerFaceColor', [0.8 0.8 0.8],'LineWidth', 1.5);
    hold(ax, 'on');

    % The AOSLO model composite STF
    plot(ax,modelMeasuredSTFdataStruct.sf, modelMeasuredSTFdataStruct.val, 'k-', ...
        'Color', [0.5 0.5 0.5], 'LineWidth', 4.0);
    p2 = plot(ax,modelMeasuredSTFdataStruct.sf, modelMeasuredSTFdataStruct.val, 'k-', ...
        'LineWidth', 2.0);

    if (showCenterSurroundComponents)
        % The AOSLO model center STF
        plot(ax, modelMeasuredSTFdataStruct.sf,  modelMeasuredSTFdataStruct.valCenterSTF, 'ko--', ...
            'MarkerSize', 10, 'MarkerEdgeColor',  [0 0. 0.], ...
            'MarkerFaceColor', [0.8 0.8 0.8],'LineWidth', 1.5);
    
        % The AOSLO model surround STF
        plot(ax, modelMeasuredSTFdataStruct.sf,  modelMeasuredSTFdataStruct.valSurroundSTF, 'ks:', ...
            'MarkerSize', 10, 'MarkerEdgeColor',  [0 0. 0.], ...
            'MarkerFaceColor', [0.8 0.8 0.8],'LineWidth', 1.5);
    end


    % The physiological optics computed STFs
    p3 = plot(ax, syntheticSTFdataStruct.sf,  syntheticSTFdataStruct.val, 'o', ...
        'MarkerSize', 20,  'MarkerEdgeColor',  [1.0 0. 0.], 'MarkerFaceColor',  [1.0 0.5 0.5],'LineWidth', 1.5);
    
    if (showCenterSurroundComponents)
        % The physiological optics derived center STF
        plot(ax, syntheticSTFdataStruct.sf,  syntheticSTFdataStruct.valCenterSTF, 'ro--', ...
            'MarkerSize', 10,  'MarkerEdgeColor',  [1.0 0. 0.], 'MarkerFaceColor',  [1.0 0.5 0.5],'LineWidth', 1.5);
        % The physiological optics derived surround STF
        plot(ax, syntheticSTFdataStruct.sf,  syntheticSTFdataStruct.valSurroundSTF, 'rs:', ...
            'MarkerSize', 10,  'MarkerEdgeColor',  [1.0 0. 0.], 'MarkerFaceColor',  [1.0 0.5 0.5],'LineWidth', 1.5);
    end

    % The physiological optics derived STFs DoG model fit
    plot(ax, modelSyntheticSTFdataStruct.sf, modelSyntheticSTFdataStruct.val, 'r-', 'LineWidth', 4.0, 'Color', [1 0.5 0.5]);
    p4 = plot(ax, modelSyntheticSTFdataStruct.sf, modelSyntheticSTFdataStruct.val, 'r-', 'LineWidth', 2.0);
    
    showLegend = false;
    if (showLegend)
        lgd = legend(ax,[p1 p2 p3 p4], ...
            {measuredSTFdataStruct.legend,modelMeasuredSTFdataStruct.legend,...
            syntheticSTFdataStruct.legend, modelSyntheticSTFdataStruct.legend}, ...
            'FontSize', 16, 'Location', 'NorthOutside');
        set(lgd,'Box','off');
    end

    
    
    grid(ax, 'on');
    box(ax, 'off');
    
    xlabel(ax,'spatial frequency (c/deg)');

    set(ax, 'XScale', 'log', 'FontSize', 40);
    set(ax, 'XLim', [4 60], 'XTick', [2 5 10 20 40 60], ...
            'YLim', [-0.05 maxY+0.002], 'YTick', -0.1:0.1:10);

    if (~showCenterSurroundComponents)
        text(ax, 50, maxY*0.97,titleString, 'FontSize', 30);
    end
    
    
end

