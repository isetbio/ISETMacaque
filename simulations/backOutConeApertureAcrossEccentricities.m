function backOutConeApertureAcrossEccentricities

    zernikeDataBase = 'Artal2012';          % Choose between 'Polans2015' and 'Artal2012'
    visualizeFits = true;
    generateVideos = true;

    for subjectRankOrder = 1:54
        retinalQuadrant = 'nasal retina';       % Choose b/n {'temporal retina', 'nasal retina'}
        doIt(retinalQuadrant, zernikeDataBase, subjectRankOrder, visualizeFits, generateVideos);
    
        retinalQuadrant = 'temporal retina';       % Choose b/n {'temporal retina', 'nasal retina'}
        doIt(retinalQuadrant, zernikeDataBase, subjectRankOrder, visualizeFits, generateVideos);
    end


end

function doIt(retinalQuadrant, zernikeDataBase, subjectRankOrder, visualizeFits, generateVideos)

    switch (zernikeDataBase)
        case 'Artal2012'
            rankedSujectIDs = ArtalOptics.constants.subjectRanking('right eye');
            testSubjectID = rankedSujectIDs(subjectRankOrder);
            if ( (contains(retinalQuadrant, 'inferior')) || ...
                 (contains(retinalQuadrant, 'superior')) )
                error('The Artal2012 measurements are only on the horizontal meridian.\n');
            end
        case 'Polans2015'
            rankedSujectIDs = PolansOptics.constants.subjectRanking('right eye');
            testSubjectID = rankedSujectIDs(subjectRankOrder);

        otherwise
            error('Unknown zernike database: ''%ss'.', zernikeDataBase)
    end

    

    switch (retinalQuadrant)
        case 'temporal retina'
            horizontalEccDegs = 0:30;
            verticalEccDegs = zeros(1,numel(horizontalEccDegs));
            eccDegsForPlotting = abs(horizontalEccDegs);
        case 'nasal retina'
            horizontalEccDegs = -(0:30);
            verticalEccDegs = zeros(1,numel(horizontalEccDegs));
            eccDegsForPlotting = abs(horizontalEccDegs);
        case 'inferior retina'
            verticalEccDegs = -(0:30);
            horizontalEccDegs = zeros(1,numel(verticalEccDegs));
            eccDegsForPlotting = abs(verticalEccDegs);
        case 'superior retina'
            verticalEccDegs = (0:30);
            horizontalEccDegs = zeros(1,numel(verticalEccDegs));
            eccDegsForPlotting = abs(verticalEccDegs);
        otherwise
            error('Unknow retinal quadrant: ''%s''\n.', retinalQuadrant);
    end


    conesNumRightEye = zeros(1, numel(horizontalEccDegs));
    conesNumLeftEye = conesNumRightEye;
    coneCharacteristicRadiusDegsRightEye = conesNumRightEye;
    visualConeCharacteristicRadiusDegsRightEye = conesNumRightEye;
    coneCharacteristicRadiusDegsLeftEye = conesNumRightEye;
    visualConeCharacteristicRadiusDegsLeftEye = conesNumRightEye;

    dataFileName = sprintf('%s_SubjectRank%d_%s', ...
            zernikeDataBase, subjectRankOrder, upper(strrep(retinalQuadrant, ' ', '_')));

    if (visualizeFits)
        hFigRightEye = figure(100); clf;
        set(hFigRightEye, 'Color', [1 1 1], 'Position', [10 10 1600 400]);
    
        hFigLeftEye = figure(101); clf;
        set(hFigLeftEye, 'Color', [1 1 1], 'Position', [10 10 1600 400]);

        if (generateVideos)
            videoOBJRightEye = VideoWriter(sprintf('%s_RE', dataFileName), 'MPEG-4');
            videoOBJRightEye.FrameRate = 30;
            videoOBJRightEye.Quality = 100;
            videoOBJRightEye.open();
    
            videoOBJLeftEye = VideoWriter(sprintf('%s_LE', dataFileName), 'MPEG-4');
            videoOBJLeftEye.FrameRate = 30;
            videoOBJLeftEye.FrameRate = 30;
            videoOBJLeftEye.Quality = 100;
            videoOBJLeftEye.open();
        else
            videoOBJRightEye = [];
            videoOBJLeftEye = [];
        end

    else
        hFigRightEye = [];
        hFigLeftEye = [];
        videoOBJRightEye = [];
        videoOBJLeftEye = [];
    end


    for i = 1:numel(horizontalEccDegs)
        whichEye = 'right eye';
        eccDegs = [-horizontalEccDegs(i) verticalEccDegs(i)];
        dStruct = estimateConeCharacteristicRadiusInVisualSpace(whichEye, eccDegs, ...
                zernikeDataBase, testSubjectID, hFigRightEye, videoOBJRightEye);
        conesNumRightEye(i) = dStruct.a;
        coneCharacteristicRadiusDegsRightEye(i) = dStruct.b;
        visualConeCharacteristicRadiusDegsRightEye(i) = dStruct.c;


        whichEye = 'left eye';
        eccDegs = [horizontalEccDegs(i) verticalEccDegs(i)];
        dStruct = estimateConeCharacteristicRadiusInVisualSpace(whichEye, eccDegs, ...
                zernikeDataBase, testSubjectID, hFigLeftEye, videoOBJLeftEye);
        conesNumLeftEye(i) = dStruct.a;
        coneCharacteristicRadiusDegsLeftEye(i) = dStruct.b;
        visualConeCharacteristicRadiusDegsLeftEye(i) = dStruct.c;
    end


    if (~isempty(videoOBJLeftEye))
        videoOBJLeftEye.close();
    end

    if (~isempty(videoOBJRightEye))
        videoOBJRightEye.close();
    end

    % Compute ratios
    ratiosRightEye = visualConeCharacteristicRadiusDegsRightEye ./ ...
                           coneCharacteristicRadiusDegsRightEye;
    ratiosLeftEye = visualConeCharacteristicRadiusDegsLeftEye ./ ...
                           coneCharacteristicRadiusDegsLeftEye;


    % Plot
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 100 1250 520]);
    ax = subplot(1,2,1);
    plot(ax, eccDegsForPlotting, conesNumRightEye, 'rs-', 'MarkerSize', 10, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.5); 
    hold(ax, 'on');
    plot(ax, eccDegsForPlotting, conesNumLeftEye, 'bs-', 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
    set(ax, 'XLim', [-1 31], 'XTick', 0:2:30);
    xtickangle(ax, 0);
    grid(ax, 'on');
    legend(ax,{'right eye', 'left eye'})
    ylabel(ax,'# of cones/deg2')
    xlabel(ax, sprintf('eccentricity, %s (degs)', retinalQuadrant));
    set(ax, 'FontSize', 16)

    ax = subplot(1,2,2);
    meanRatios = mean([ratiosRightEye(:) ratiosLeftEye(:)],2,'omitnan');
    plot(ax, eccDegsForPlotting, ratiosLeftEye, 'ro-', 'MarkerSize', 10, 'LineWidth', 1.5, 'MarkerFaceColor', [1 0.5 0.5]); hold on
    plot(ax, eccDegsForPlotting, ratiosRightEye, 'bo-', 'MarkerSize', 10, 'LineWidth', 1.5, 'MarkerFaceColor', [0.5 0.5 1]);
    plot(ax, eccDegsForPlotting, meanRatios, 'ko-', 'LineWidth', 1.5, 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 0.8]);
    set(ax, 'XLim', [-1 31], 'XTick', 0:2:30);
    xtickangle(ax, 0);
    grid(ax, 'on');
    legend(ax,{'right eye', 'left eye', 'mean L+R'}, 'Location', 'northwest')
    ylabel(ax,'visual cone Rc/anatomical cone Rc')
    xlabel(ax, sprintf('eccentricity, %s (degs)', retinalQuadrant));
    set(ax, 'FontSize', 16)
    drawnow;
    
    p = getpref('ISETMacaque');
    fName = fullfile(p.generatedDataDir, 'coneApertureBackingOut', sprintf('%s.pdf', dataFileName));
    NicePlot.exportFigToPDF(fName, hFig, 300);

    % Export data
    
    fName = fullfile(p.generatedDataDir, 'coneApertureBackingOut', sprintf('%s.mat', dataFileName));
    fprintf('Exported data in %s\n', fName);
    save(fName, 'eccDegsForPlotting', ...
        'visualConeCharacteristicRadiusDegsRightEye', ...
        'visualConeCharacteristicRadiusDegsLeftEye', ...
        'coneCharacteristicRadiusDegsRightEye', ...
        'coneCharacteristicRadiusDegsLeftEye', ...
        'conesNumRightEye', 'conesNumLeftEye');

end



function dStruct = estimateConeCharacteristicRadiusInVisualSpace(...
    whichEye, eccDegs, zernikeDataBase, testSubjectID, hFig, videoOBJ)

    cm = cMosaic('whichEye', whichEye, ...
            'sizeDegs', [1 1], ...
            'eccentricityDegs', eccDegs, ...
            'customDegsToMMsConversionFunction', @RGCmodels.Watson.convert.rhoDegsToMMs, ...
            'customMMsToDegsConversionFunction', @RGCmodels.Watson.convert.rhoMMsToDegs, ...
            'wave', 550);
    conesNumInRetinalPatch = numel(cm.coneTypes);

    if (conesNumInRetinalPatch < 6)
        dStruct.a = conesNumInRetinalPatch;
        dStruct.b = nan;
        dStruct.c = nan;
        return;
    end

    % Estimate mean cone aperture in the mosaic'c center
    coneDistancesFromMosaicCenter = sqrt(sum(bsxfun(@minus, cm.coneRFpositionsDegs, cm.eccentricityDegs).^2,2));
    [~,idx] = sort(coneDistancesFromMosaicCenter);
    meanConeSpacingDegsInMosaicCenter = mean(cm.coneRFspacingsDegs(idx(1:6)));
    coneCharacteristicRadiusDegs = 0.204 * sqrt(2.0) * meanConeSpacingDegsInMosaicCenter;

    switch (zernikeDataBase)
        case 'Artal2012'
            subtractCentralRefraction = ArtalOptics.constants.subjectRequiresCentralRefractionCorrection(...
                cm.whichEye, testSubjectID);
    
        case 'Polans2015'
            subtractCentralRefraction = PolansOptics.constants.subjectRequiresCentralRefractionCorrection(...
                cm.whichEye, testSubjectID);
    end

    % Estimate visual cone Rc
    visualConeCharacteristicRadiusDegs = analyzeEffectOfPSFonConeAperture(...
                    coneCharacteristicRadiusDegs, cm, ...
                    zernikeDataBase, testSubjectID, subtractCentralRefraction, hFig, videoOBJ);

    dStruct.a = conesNumInRetinalPatch;
    dStruct.b = coneCharacteristicRadiusDegs;
    dStruct.c = visualConeCharacteristicRadiusDegs;
end


function theVisuallyProjectedConeCharacteristicRadiusDegs =  analyzeEffectOfPSFonConeAperture(...
    coneCharacteristicRadiusDegs, cm, zernikeDataBase, testSubjectID, subtractCentralRefraction, hFig, videoOBJ)


    [oiEnsemble, psfEnsemble] = ...
                    cm.oiEnsembleGenerate(cm.eccentricityDegs, ...
                    'zernikeDataBase', zernikeDataBase, ...
                    'subjectID', testSubjectID, ...
                    'pupilDiameterMM', 3.0, ...
                    'zeroCenterPSF', true, ...
                    'subtractCentralRefraction', subtractCentralRefraction, ...
                    'wavefrontSpatialSamples', 701, ...
                    'warningInsteadOfErrorForBadZernikeCoeffs', true);

    if (isempty(oiEnsemble))
        theVisuallyProjectedConeCharacteristicRadiusDegs = nan;
        return;
    end


    thePSFData = psfEnsemble{1};
    
    targetWavelength = 550;
    [~, wIndex] = min(abs(thePSFData.supportWavelength-targetWavelength));
    thePSF = squeeze(thePSFData.data(:,:,wIndex));
    [Xarcmin, Yarcmin] = meshgrid(thePSFData.supportX, thePSFData.supportY);

    [theCentroid, RcX, RcY, theRotationAngle] = estimatePSFgeometry(thePSFData.supportX, thePSFData.supportY,thePSF);


    GaussianConeAperture = exp(-(((Xarcmin-theCentroid(1))/60)/coneCharacteristicRadiusDegs).^2) .* ...
                           exp(-(((Yarcmin-theCentroid(2))/60)/coneCharacteristicRadiusDegs).^2);

    % Convolve cone aperture with the PSF
    theVisuallyProjectedConeAperture = conv2(thePSF, GaussianConeAperture, 'same');
    theVisuallyProjectedConeAperture = theVisuallyProjectedConeAperture  / max(theVisuallyProjectedConeAperture(:));

    % Fit a 2D Gaussian to the visually projected cone aperture and extract
    % the characteristic radius of that Gaussian
    [theVisuallyProjectedConeApertureFittedGaussian, ...
     theVisuallyProjectedConeCharacteristicRadiusDegs, XLims, YLims] = ...
        fit2DGaussian(thePSFData.supportX, thePSFData.supportY,theVisuallyProjectedConeAperture);

    xRange = XLims(2)-XLims(1);
    yRange = YLims(2)-YLims(1);
    xyRange = max([xRange yRange]);
    if (xyRange < 10)
        xTick = -100:1:100;
    elseif (xyRange < 30)
        xTick = -100:2:100;
    elseif (xyRange < 50)
        xTick = -100:5:100;
    elseif (xyRange < 100)
        xTick = -200:10:200;
    else
        xTick = -400:20:400;
    end

    if (~isempty(hFig))
        figure(hFig); clf;
        cLUT= brewermap(1024, 'blues');
        zLevels = 0:0.1:1.0;
        ax = subplot(1,4,1);
        contourf(ax,thePSFData.supportX, thePSFData.supportY, GaussianConeAperture, zLevels);
        set(ax, 'XLim', XLims, 'YLim', YLims, 'FontSize', 14, 'Color', squeeze(cLUT(1,:)), 'XTick', xTick, 'YTick', xTick);
        axis(ax,'xy'); axis(ax, 'square'); 
        grid(ax, 'on');
        xlabel(ax,'arc min');
        xtickangle(ax, 0);
        title(ax,sprintf('cone aperture @ ecc (degs): %2.0f,%2.0f\n%s', cm.eccentricityDegs(1), cm.eccentricityDegs(2),  cm.whichEye));
    
        ax = subplot(1,4,2);
        contourf(ax,thePSFData.supportX, thePSFData.supportY, thePSF/max(thePSF(:)), zLevels);
        set(ax, 'XLim', XLims, 'YLim', YLims, 'FontSize', 14, 'Color', squeeze(cLUT(1,:)), 'XTick', xTick, 'YTick', xTick);
        axis(ax,'xy'); axis(ax, 'square'); 
        grid(ax, 'on');
        xlabel(ax,'arc min');
        xtickangle(ax, 0);
        title(ax,sprintf('PSF(%2.0fnm) @ ecc (degs): %2.0f,%2.0f \n%s, subjectID: %d, %s', ...
            thePSFData.supportWavelength(wIndex), cm.eccentricityDegs(1), cm.eccentricityDegs(2), zernikeDataBase, testSubjectID, cm.whichEye));
        
        ax = subplot(1,4,3);
        contourf(ax,thePSFData.supportX, thePSFData.supportY, theVisuallyProjectedConeAperture, zLevels);
        set(ax, 'XLim', XLims, 'YLim', YLims, 'FontSize', 14, 'Color', squeeze(cLUT(1,:)), 'XTick', xTick, 'YTick', xTick);
        axis(ax,'xy'); axis(ax, 'square'); 
        grid(ax, 'on');
        xlabel(ax,'arc min');
        xtickangle(ax, 0);
        title(ax,sprintf('visually projected cone aperture\n conv(coneAperture, PSF)'));
    
        ax = subplot(1,4,4);
        contourf(ax,thePSFData.supportX, thePSFData.supportY, theVisuallyProjectedConeApertureFittedGaussian, zLevels);
        set(ax, 'XLim', XLims, 'YLim', YLims, 'FontSize', 14, 'Color', squeeze(cLUT(1,:)), 'XTick', xTick, 'YTick', xTick);
        axis(ax,'xy'); axis(ax, 'square'); 
        grid(ax, 'on');
        xlabel(ax,'arc min');
        xtickangle(ax, 0);
        title(ax,sprintf('fitted Gaussian ellipsoid\n (visual/anatomical coneRc ratio: %2.1f)', theVisuallyProjectedConeCharacteristicRadiusDegs/coneCharacteristicRadiusDegs));
    
        colormap(cLUT);
        drawnow;

        if (~isempty(videoOBJ))
            videoOBJ.writeVideo(getframe(hFig));
        end
    end
end

function [theCentroid, RcX, RcY, theRotationAngle] = estimatePSFgeometry(supportX, supportY, theVisualConeAperture)
    % Compute orientation, centroid, and major/minor axis lengths
    binaryImage = theVisualConeAperture;
    m1 = min(binaryImage(:));
    m2 = max(binaryImage(:));
    binaryImage = imbinarize((binaryImage - m1)/(m2-m1));
    s = regionprops('table', binaryImage,'Orientation', 'Centroid', 'MinorAxisLength', 'MajorAxisLength');
    theCentroid = s.Centroid(1,:);
    theMinorAxisLength = s.MinorAxisLength(1);
    theMajorAxisLength = s.MajorAxisLength(1);
    theRotationAngle = s.Orientation(1);

    % The computed centroid and axis lengths are in pixels. Convert them to units of spatial support
    % to serve as initial Gaussian parameter values
    xx = [round(theCentroid(1)-theMajorAxisLength*0.5) round(theCentroid(1)+theMajorAxisLength*0.5)];
    yy = [round(theCentroid(2)-theMinorAxisLength*0.5) round(theCentroid(2)+theMinorAxisLength*0.5)];

    xx(1) = max([1 xx(1)]);
    xx(2) = min([numel(supportX) xx(2)]);

    yy(1) = max([1 yy(1)]);
    yy(2) = min([numel(supportY) yy(2)]);

    RcY = (supportY(yy(2)) - supportY(yy(1)))/5.0;
    RcX = (supportX(xx(2)) - supportX(xx(1)))/5.0;
    theCentroid(1) = supportX(round(theCentroid(1)));
    theCentroid(2) = supportY(round(theCentroid(2)));
end


function [theFitted2DGaussian, theFittedGaussianCharacteristicRadiusDegs, XLims, YLims] = ...
    fit2DGaussian(supportX, supportY, theVisualConeAperture)

    [X,Y] = meshgrid(supportX, supportY);
    xydata(:,:,1) = X;
    xydata(:,:,2) = Y;

    theVisualConeAperture = theVisualConeAperture / max(theVisualConeAperture(:));
    [theCentroid, RcX, RcY, theRotationAngle] = estimatePSFgeometry(supportX, supportY, theVisualConeAperture);

    % Form parameter vector: [gain, xo, RcX, yo, RcY, rotationAngleDegs]
    p0 = [...
        max(theVisualConeAperture(:)), ...
        theCentroid(1), ...
        RcX, ...
        theCentroid(2), ...
        RcY, ...
        theRotationAngle];

    % Form lower and upper value vectors
    lb = [ 0 min(supportX) 0*(max(supportX)-min(supportX))    min(supportY) 0*(max(supportY)-min(supportY))  theRotationAngle-90];
    ub = [ 1 max(supportX)    max(supportX)-min(supportX)     max(supportY)    max(supportY)-min(supportY)   theRotationAngle+90];

    % Do the fitting
    [fittedParams,resnorm,residual,exitflag] = lsqcurvefit(@gaussian2D,p0,xydata,theVisualConeAperture,lb,ub);

    xo = fittedParams(2);
    yo = fittedParams(4);
    RcX = fittedParams(3);
    RcY = fittedParams(5);
    XLims = xo + max([RcX RcY])*[-3 3];
    YLims = yo + max([RcX RcY])*[-3 3];

    % Compute the fitted 2D Gaussian
    theFitted2DGaussian = gaussian2D(fittedParams,xydata);

    % Compute the fitted Gaussian Rc in degs
    theFittedGaussianCharacteristicRadiusDegs = sqrt(RcX^2+RcY^2)/60;
end

function F = gaussian2D(params,xydata)
    % Retrieve spatial support
    X = squeeze(xydata(:,:,1));
    Y = squeeze(xydata(:,:,2));

    % Retrieve params
    gain = params(1);
    xo = params(2);
    yo = params(4);
    RcX = params(3);
    RcY = params(5);
    rotationAngle = params(6);

    % Apply axes rotation
    Xrot = X * cosd(rotationAngle) -  Y*sind(rotationAngle);
    Yrot = X * sind(rotationAngle) +  Y*cosd(rotationAngle);
    xorot = xo * cosd(rotationAngle) -  yo*sind(rotationAngle);
    yorot = xo * sind(rotationAngle) +  yo*cosd(rotationAngle);

    % Compute 2D Gaussian
    F = gain * exp(-((Xrot-xorot)/RcX).^2) .* exp(-((Yrot-yorot)/RcY).^2);
end