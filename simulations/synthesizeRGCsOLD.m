function synthesizeRGCsOLD(monkeyID, apertureParams,  coneCouplingLambda, opticalDefocusDiopters, eccCenterMicrons, eccRadiusMicrons)
    
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    
    if (~isempty(coneCouplingLambda))
        pdfFileName = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f_SynthesizedRGCs_ROI_%2.1f_%2.1fmicrons_Radius_%2.1fmicrons.pdf', ...
                monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters, ...
                eccCenterMicrons(1),  eccCenterMicrons(2), eccRadiusMicrons));
        fittedParamsFileName = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f_FittedRetinalDoGmodelParams_ROI_%2.1f_%2.1fmicrons_Radius_%2.1fmicrons.mat', ...
                monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters, ...
                eccCenterMicrons(1),  eccCenterMicrons(2), eccRadiusMicrons));
    else
       pdfFileName = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f_SynthesizedRGCs_ROI_%2.1f_%2.1fmicrons_Radius_%2.1fmicrons.pdf', ...
                monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters, ...
                eccCenterMicrons(1),  eccCenterMicrons(2), eccRadiusMicrons));
       fittedParamsFileName = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f_FittedRetinalDoGmodelParams_ROI_%2.1f_%2.1fmicrons_Radius_%2.1fmicrons.mat', ...
                monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters, ...
                eccCenterMicrons(1),  eccCenterMicrons(2), eccRadiusMicrons));
    end
   
    load(fittedParamsFileName, 'fittedRetinalDoGmodelParams');
    plotDoGModelParams(fittedRetinalDoGmodelParams);
    
    synthesizeRGCweights(fittedRetinalDoGmodelParams)
    
end

function plotDoGModelParams(fittedRetinalDoGmodelParams)
    rowsNum = 2;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
        'colsNum', colsNum, ...
        'rowsNum', rowsNum, ...
        'heightMargin',  0.08, ...
        'widthMargin',    0.06, ...
        'leftMargin',     0.06, ...
        'rightMargin',    0.01, ...
        'bottomMargin',   0.08, ...
        'topMargin',      0.02);
               
    hFig = figure(1); clf;
    set(hFig, 'Position', [100 100 1050 900], 'Color', [1 1 1]);
    
    % Histogram of Rs:Rc
    ax = subplot('Position', sv(1,1).v);
    edges = 0.1:0.25:3;
    randomSamplesToGenerate = 1000;
    randomRsRcSamples = makeJointHistogramPlot(ax, fittedRetinalDoGmodelParams.RsRcRatioLcenter, fittedRetinalDoGmodelParams.RsRcRatioMcenter, ...
        edges, [0.5 3], 0:0.5:3, [0 7], 'Rs/Rc ratio', randomSamplesToGenerate);
    
    % Histogram of Kc:Ks
    ax = subplot('Position', sv(1,2).v);
    edges = 0:0.5:15;
    makeJointHistogramPlot(ax, 1./fittedRetinalDoGmodelParams.KsKcRatioLcenter, 1./fittedRetinalDoGmodelParams.KsKcRatioMcenter, ...
        edges, [0 15], 0:2:15, [0 7], 'Kc/Ks ratio', []);
    
    % Histogram of integrated strengths
    ax = subplot('Position', sv(2,1).v);
    kc = fittedRetinalDoGmodelParams.KcLcenter;
    ks = fittedRetinalDoGmodelParams.KcLcenter .* fittedRetinalDoGmodelParams.KsKcRatioLcenter;
    rc = fittedRetinalDoGmodelParams.meanLconeRcDegs;
    rs = rc * fittedRetinalDoGmodelParams.RsRcRatioLcenter;
    centerStrengthsLcenter = kc .* (pi * rc.^2);
    surroundStrengthsLcenter = ks .* (pi * rs.^2);
    integratedStrengthRatiosLcenter = centerStrengthsLcenter./surroundStrengthsLcenter;
    
    kc = fittedRetinalDoGmodelParams.KcMcenter;
    ks = fittedRetinalDoGmodelParams.KcMcenter .* fittedRetinalDoGmodelParams.KsKcRatioMcenter;
    rc = fittedRetinalDoGmodelParams.meanMconeRcDegs;
    rs = rc * fittedRetinalDoGmodelParams.RsRcRatioMcenter;
    centerStrengthsMcenter = kc .* (pi * rc.^2);
    surroundStrengthsMcenter = ks .* (pi * rs.^2);
    integratedStrengthRatiosMcenter = centerStrengthsMcenter./surroundStrengthsMcenter;
    
    edges = 0.1:0.15:2.5;
    xRange = [0.7 2.2];
    xTicks = 0:0.2:2.5;
    yRange = [0 10];
    makeJointHistogramPlot(ax, integratedStrengthRatiosLcenter, integratedStrengthRatiosMcenter, ...
        edges, xRange, xTicks, yRange, 'C/S integrated ratio', []);
    
    
    ax = subplot('Position', sv(2,2).v);
    makeJointScatterPlot(ax, fittedRetinalDoGmodelParams.RsRcRatioLcenter, 1./fittedRetinalDoGmodelParams.KsKcRatioLcenter, ...
                             fittedRetinalDoGmodelParams.RsRcRatioMcenter, 1./fittedRetinalDoGmodelParams.KsKcRatioMcenter);
end

function makeJointScatterPlot(ax, RsRcRatioLcenter, KcKsRatioLcenter, RsRcRatioMcenter, KcKsRatioMcenter)
    lColor = [1 0.1 0.5];
    mColor = [0.1 1 0.5];
    scatter(ax, RsRcRatioLcenter, KcKsRatioLcenter, 144, 'ko', 'filled', ...
        'MarkerFaceColor', lColor, 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', lColor*0.5, 'LineWidth', 1.5);
    hold(ax, 'on');
    scatter(ax, RsRcRatioMcenter, KcKsRatioMcenter, 144, 'ko', 'filled', ...
        'MarkerFaceColor', mColor, 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', mColor*0.5, 'LineWidth', 1.5);
    x = linspace(1,20,1000);
    y = x.^2;
    plot(ax, x,y, 'k-', 'LineWidth', 1.5);
    set(ax, 'XLim', [0.9 4], 'YLim', [0.9 15], 'XTick', 0:0.5:15, 'YTick', 0:1:15, 'FontSize', 18);
    axis(ax, 'square');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'Rs/Rc ratio');
    ylabel(ax, 'Kc/Ks ratio');
end


function  generatedRandomSamples = makeJointHistogramPlot(ax, Ldata, Mdata, edges, xRange, xTicks, yRange, xLabelString, generatedSamplesNum)

    allData = [Ldata Mdata];

    if (isempty(edges))
        edges = linspace(min(allData), max(allData), 5);
    end
    
    % Generate histogram of all data
    
    [N, edges] = histcounts(allData, edges);
    
    % Generate random samples based on the histogram of all the data
    if ((~isempty(generatedSamplesNum)) && (generatedSamplesNum > 0))
        generatedRandomSamples = generateRandomSamplesFromData(xRange, edges, N, generatedSamplesNum);
    else
        generatedRandomSamples = [];
    end
    
    % Plot the histogram of all data
    dx = 0.5*(edges(2)-edges(1));
    h = bar(ax, edges(1:end-1)+dx, N, 1);
    h.FaceColor = [0.7 0.7 0.7];
    h.EdgeColor = 'none';
    hold(ax, 'on');

    % Compute separate histograms for L- and M-cone data
    [nL, edges] = histcounts(Ldata, edges);
    [nM, edges] = histcounts(Mdata, edges);
    
    % Plot the separate histograms
    h = bar(ax, edges(1:end-1)+dx, [nL' nM'],1);
    h(1).FaceColor = [1 0.1 0.5];
    h(2).FaceColor = [0.1 1 0.5];

    if (isempty(xRange))
        xRange = [min(allData) max(allData)];
    end
    
    if (isempty(xTicks))
        xTicks = linspace(xRange(1), xRange(2), 5);
    end
    
    if (isempty(yRange))
        yRange = [0 max(N)+1];
    end
    
    set(ax, 'XLim', xRange, 'XTick', xTicks, 'YLim', yRange, 'YTick', 0:1:10, 'FontSize', 18);
    xlabel(ax, xLabelString);
    ylabel(ax, '# of cells');
    axis(ax, 'square');
end

function  randomSamples = generateRandomSamplesFromData(xRange, edges, N, generatedSamplesNum)
    % Generate a smooth function
    dx = 0.5*(edges(2)-edges(1));
    highResData = linspace(xRange(1),xRange(2),30);
    highResCounts = interp1(edges(1:end-1)+dx, N, highResData, 'makima');
    highResCounts(highResCounts<0) = 0;
    
    % Transform the counts to probabilities
    highResProbs = highResCounts / sum(highResCounts);
    
    % Probability density
    probabilityDensity = highResProbs(:);
    
    % Generate cumulative distribution
    CDF = cumsum(probabilityDensity);
    
    % Generate nRand random numbers in [0 1]
    uniformRandomNumbers = rand(generatedSamplesNum,1);
    randomSamples = zeros(1,generatedSamplesNum);                 
    for k = 1:generatedSamplesNum
        for bin = 1:numel(CDF)-1
            if (uniformRandomNumbers(k)>=CDF(bin) && uniformRandomNumbers(k)<CDF(bin+1))
                randomSamples(k) = highResData(bin+1);
            end
        end
    end
    
end
