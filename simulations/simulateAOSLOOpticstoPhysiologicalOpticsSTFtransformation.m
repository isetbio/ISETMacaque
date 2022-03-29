function simulateAOSLOOpticstoPhysiologicalOpticsSTFtransformation

    % Assume a Gaussian
    blurFactors = [0.035 0.07 0.1];
    spatialFrequencySupport = logspace(log10(1), log10(200),200);
    spatialFrequenciesExamined = logspace(log10(5), log10(60), 14);

    % Compute expected RcDegs for an eccentricity of 0.2 degs
    eccDegsSupport = 0.1;
    [~, ~, ~, ~, RcAlpha, RcBeta] = CronerKaplanData.RcRsVersusEccentricity('generateFigure', false);
    retinalMRGC.DoGparams.RcDegs = RcAlpha * eccDegsSupport.^RcBeta;

    % From AOSLO fit
    meanRsRcRatio = 2.4;
    integratedSCratio = 0.9691;

    retinalMRGC.DoGparams.Kc = 10000;
    retinalMRGC.DoGparams.RsDegs = retinalMRGC.DoGparams.RcDegs * meanRsRcRatio;
    retinalMRGC.DoGparams.Ks = integratedSCratio/((retinalMRGC.DoGparams.RsDegs/retinalMRGC.DoGparams.RcDegs)^2) * retinalMRGC.DoGparams.Kc;

    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1400 1000]);

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 3, ...
       'rowsNum', 3, ...
       'heightMargin',  0.08, ...
       'widthMargin',    0.1, ...
       'leftMargin',     0.04, ...
       'rightMargin',    0.02, ...
       'bottomMargin',   0.07, ...
       'topMargin',      0.03);

    for iBlur = 1:numel(blurFactors)
        alpha = blurFactors(iBlur);
        opticsMTF  = exp(-(alpha*spatialFrequencySupport).^2);
        ax1 = subplot('Position', subplotPosVectors(iBlur,1).v);
        ax2 = subplot('Position', subplotPosVectors(iBlur,2).v);
        ax3 = subplot('Position', subplotPosVectors(iBlur,3).v);
        computeSTF(ax1, ax2, ax3, spatialFrequencySupport, spatialFrequenciesExamined, ...
            opticsMTF, retinalMRGC, ...
            (iBlur == 1), ...
            (iBlur == numel(blurFactors)));
    end

    NicePlot.exportFigToPDF('AOSLOtoPhysiologicalOpticsSTFtransformation.pdf', hFig, 300);
end

function computeSTF(ax1, ax2, ax3, sf, sfExamined, opticsMTF, retinalMRGC, showTitle, showXLabel)
    retinalMTFcenter   = retinalMRGC.DoGparams.Kc * pi * retinalMRGC.DoGparams.RcDegs^2 * exp(-(pi*retinalMRGC.DoGparams.RcDegs*sf).^2);
    retinalMTFsurround = retinalMRGC.DoGparams.Ks * pi * retinalMRGC.DoGparams.RsDegs^2 * exp(-(pi*retinalMRGC.DoGparams.RsDegs*sf).^2);
    
    visualMTFcenter = retinalMTFcenter .* opticsMTF;
    visualMTFsurround = retinalMTFsurround .* opticsMTF;

    
    plotStuff(ax2, sf, sfExamined, opticsMTF, [], [], [], 'physiological optics MTF', showTitle, showXLabel);

    rightYaxisMax = 1.0; rightYaxisTicks = 0:0.2:1;
    plotStuff(ax1, sf, sfExamined, retinalMTFcenter, retinalMTFsurround, ...
        rightYaxisMax, rightYaxisTicks, 'STF (AOSLO optics)', showTitle, showXLabel, 'AOSLO');

    rightYaxisMax = 0.301; rightYaxisTicks = 0:0.1:1;
    plotStuff(ax3, sf, sfExamined, visualMTFcenter, visualMTFsurround, ...
        rightYaxisMax, rightYaxisTicks, 'STF (physiological optics)', showTitle, showXLabel, 'PHYSIO');
end


function plotStuff(ax, sf, sfExamined, center, surround, rightYaxisMax, rightYaxisTicks, ...
    titleString, showTitle, showXLabel, dataLabel)

    maxSF = 125;
    if (isempty(surround))
        shadedAreaPlot(ax, sf, center, 0, [0.8 0.8 0.4], [0.8 0.8 0.4]*0.5, 0.5, 2);
        set(ax, 'YTick', 0:0.2:1, 'YLim', [0 1.02], 'YColor', [0.1 0.2 0.7])
        set(ax, 'XScale', 'log', 'XLim', [1 maxSF], 'XTick', [1 3 10 30 100]);
    else
        hold(ax, 'on');
        yyaxis(ax, 'left')
        if (strcmp(dataLabel, 'AOSLO'))
            compositeSTFcolor = [0.9 0.9 0.9];
            compositeSTFLineColor = [0 0 0];
        else
            compositeSTFcolor = [1 0.5 0.5];
            compositeSTFLineColor = [1 0 0];
        end
        compositeSTF = abs(center-surround);
        centerColor = 0.7*[0.9 0.65 0.8]+[0.3 0.3 0.3];
        surroundColor = 0.7*[0.3 0.9 0.9]+[0.3 0.3 0.3];
        p2 = shadedAreaPlot(ax, sf, center, 0, centerColor, centerColor*0.5, 1.0, 1.5);
        p1 = shadedAreaPlot(ax, sf, surround, 0, surroundColor, surroundColor*0.5, 1.0, 2);
        
        
        set(ax, 'YTick', 0:0.2:1, 'YLim', [0 1.02], 'YColor', [0.1 0.2 0.7])
        yyaxis(ax, 'right')
        for i = 1:numel(sfExamined)
            [~,kk(i)] = min(abs(sfExamined(i)-sf));
        end

        plot(ax,sf, compositeSTF, '-', 'Color', min(compositeSTFLineColor+[0.5 0.5 0.5],[1 1 1]), 'LineWidth', 4.0);
        plot(ax,sf, compositeSTF, '-', 'Color', compositeSTFLineColor, 'LineWidth', 1.5);
        scatter(ax, sfExamined, compositeSTF(kk), 14*14, 'filled', ...
            'MarkerFaceColor', compositeSTFcolor, 'MarkerEdgeColor', compositeSTFLineColor, 'LineWidth', 2.0);
        
        set(ax, 'XScale', 'log', 'XLim', [1 maxSF], 'XTick', [1 3 10 30 100], ...
            'YTick', rightYaxisTicks, 'YLim', [0 rightYaxisMax], 'YColor', 'k');
        lgd = legend(ax,[p2 p1], {'center', 'surround'}, 'FontSize', 14);
        set(lgd,'Box','off');
    end
   
    grid(ax, 'on'); box(ax, 'off');
    set(ax, 'FontSize', 24);

    if (showXLabel)
        xlabel(ax, 'spatial frequency (c/deg)')
    end

    if (showTitle)
        title(ax,titleString, 'FontWeight', 'normal')
    end

end

function p = shadedAreaPlot(ax,x,y, baseline, faceColor, edgeColor, faceAlpha, lineWidth)

    x = [x fliplr(x)];
    y = [y y*0+baseline];

    px = reshape(x, [1 numel(x)]);
    py = reshape(y, [1 numel(y)]);
    pz = -10*eps*ones(size(py)); 
    p = patch(ax,px,py,pz,'FaceColor',faceColor,'EdgeColor', edgeColor, 'FaceAlpha', faceAlpha, 'LineWidth', lineWidth);
end
