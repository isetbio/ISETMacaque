function plot1DConeApertureArray()
    
    % Monkey to employ
    monkeyID = 'M838';
    
    % Stimulus params
    stimulusParams = simulator.params.AOSLOStimulus();

    % Set the cone mosaic params
    cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', 5/1000, ...
        'wavelengthSupport', stimulusParams.wavelengthSupport);

    % Generate the cone mosaic
    theConeMosaic = simulator.coneMosaic.modify(monkeyID, cMosaicParams);

    % Find cones in the central [-10 + 10] microns
    visualizedDomainRangeMicrons = [-8 8 -8 8];
    theLineROI = regionOfInterest('shape', 'line', 'from', [-7 3.5], 'to', [7 -4.3], 'thickness', 0.4, 'units', 'microns');

    % Compute the indices of cones that lie within theLineROI
    indicesOfConesInROI = theLineROI.indicesOfPointsInside(theConeMosaic.coneRFpositionsMicrons);

    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [70 70 630 885]);
    ax = subplot('Position', [0.12 0.35 0.85 0.65]);
    
    backgroundColor = [0.85 0.85 0.85];

    theConeMosaic.visualize('figureHandle', hFig, ...
        'axesHandle', ax, ...
        'domain', 'microns', ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'visualizedConeApertureThetaSamples', 30, ...
        'domain', 'microns', ...
        'domainVisualizationLimits', visualizedDomainRangeMicrons, ...
        'domainVisualizationTicks', struct('x', -10:5:10, 'y', -10:5:10), ...
        'crossHairsOnMosaicCenter', ~true, ...
        'backgroundColor', backgroundColor, ...
        'labelConesWithIndices', indicesOfConesInROI, ...
        'noYLabel', ~true, ...
        'noXlabel', ~true, ...
        'plotTitle', ' ', ...
        'fontSize', 24);
    
    hold(ax, 'on');
    theLineROI.visualize('figureHandle', hFig, 'axesHandle', ax, ...
        'fillColor', [0 0 0 0.5], ...
        'xLims', visualizedDomainRangeMicrons(1:2), ...
        'yLims', visualizedDomainRangeMicrons(3:4), ...
        'noXLabel', true, ...
        'fontSize', 24);


    ax = subplot('Position', [0.12 0.08 0.85 0.2]);
    xSupport = -20:0.02:20;
    for iCone = 1:numel(indicesOfConesInROI)
        theConeIndex = indicesOfConesInROI(iCone);
        switch (theConeMosaic.coneTypes(theConeIndex))
            case cMosaic.LCONE_ID
                coneColor = [1 0.1000 0.5000];
            case cMosaic.MCONE_ID
                coneColor = [0.1000 1 0.5000];
            case cMosaic.SCONE_ID
                coneColor = [0.6000 0.1000 1];
        end
        coneRc = 0.204*sqrt(2.0)*theConeMosaic.coneRFspacingsMicrons(theConeIndex);
        gaussianProfile = exp(-((xSupport-theConeMosaic.coneRFpositionsMicrons(theConeIndex,1))/coneRc).^2);
        shadedAreaPlot(ax, xSupport, gaussianProfile, 0, ...
            coneColor, coneColor*0.5, 0.5, 1.5, '-'); 
    end
    set(ax, 'XLim', [visualizedDomainRangeMicrons(1) visualizedDomainRangeMicrons(2)], 'YLim', [0 1.0], 'fontSize', 24, 'Color', backgroundColor);
    xlabel(ax, 'space (microns)');
    ylabel(ax, 'sensitivity')
    grid(ax, 'on');

    NicePlot.exportFigToPDF('1DconeArray.pdf', hFig, 300);
end


function shadedAreaPlot(ax,x,y, baseline, faceColor, edgeColor, faceAlpha, lineWidth, lineStyle)
    x = [x fliplr(x)];
    y = [y y*0+baseline];
    px = reshape(x, [1 numel(x)]);
    py = reshape(y, [1 numel(y)]);
    pz = -10*eps*ones(size(py)); 
    patch(ax,px,py,pz,'FaceColor',faceColor,'EdgeColor', edgeColor, ...
        'FaceAlpha', faceAlpha, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
end