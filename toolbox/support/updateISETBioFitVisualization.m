function updateISETBioFitVisualization(visStruct, iRGCindex, iCone, ...
    indicesOfModelConesDrivingTheRGCcenters, theConeMosaic, ...
    centerConeCharacteristicRadiusDegs, ...
    centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum,...
    surroundConeIndices, surroundConeWeights, ...
    fittedParams, rmsErrors, rmsErrorsTrain, examinedSpatialFrequencies, fittedSTFs, ...
    theMeasuredSTFdata, theMeasuredSTFerrorData, fitTitle)

    % Plot the spatial map of rms errors (for different assumed RF center cone positions)
    maxRMSerror = max(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');
    [minRMSerror, minRMSerrorConeIndex] = min(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');

    % Clear the axMap axes
    cla(visStruct.axMap);
    hold(visStruct.axMap, 'on');

    for allConeIndices = 1:iCone
        if (maxRMSerror == minRMSerror)
            err = 1.0;
        else
            err = (rmsErrors(iRGCindex, allConeIndices)-minRMSerror)/(maxRMSerror-minRMSerror);
        end
        markerSize = 6 + round(14 * err);

        centerModelConeIndex = indicesOfModelConesDrivingTheRGCcenters(allConeIndices);
        centerConePosMicrons = theConeMosaic.coneRFpositionsMicrons(centerModelConeIndex,:);

        if (allConeIndices == minRMSerrorConeIndex)
            lineWidth = 1.5;
            color = [1 0 0];
        else
            lineWidth = 0.5;
            color = [0.7 0.7 0.7];
        end

        plot(visStruct.axMap, centerConePosMicrons(1), centerConePosMicrons(2), 'ko', ...
            'MarkerSize', markerSize, 'MarkerFaceColor', color, 'LineWidth', lineWidth);

        set(visStruct.axMap, 'XLim', [-20 20], 'YLim', [-20 20], 'FontSize', 18);
        axis(visStruct.axMap, 'square');
        xlabel(visStruct.axMap, 'retinal space (microns)');
        title(visStruct.axMap, sprintf('RMSE map (range: %2.2f - %2.2f)', minRMSerror, maxRMSerror), ...
            'FontWeight', 'normal', 'FontSize', 15);
    end


    % Plot the fit
    cla(visStruct.axFit);
    hold(visStruct.axFit, 'on')

    % All center cone STFs in gray
    for iiCone = 1:iCone
        linePlotHandle = plot(visStruct.axFit, examinedSpatialFrequencies, squeeze(fittedSTFs(1,iRGCindex, iiCone,:)), ...
            'k-', 'LineWidth', 1.5, 'Color', [0.0 0.0 0.0]);
        % Opacity of lines : 0.5
        linePlotHandle.Color = [linePlotHandle.Color 0.25];
    end

    % The best fitting center cone STF in red
    plot(visStruct.axFit, examinedSpatialFrequencies, squeeze(fittedSTFs(1,iRGCindex, minRMSerrorConeIndex,:)), ...
        '-', 'LineWidth', 4.0, 'Color', [0.4 0 0]);
    plot(visStruct.axFit, examinedSpatialFrequencies, squeeze(fittedSTFs(1,iRGCindex, minRMSerrorConeIndex,:)), ...
        '-', 'LineWidth', 1.5, 'Color', [1 0 0]);
        
                    
    % The error bars
    for iSF = 1:numel(examinedSpatialFrequencies)
        plot(visStruct.axFit, examinedSpatialFrequencies(iSF) *[1 1], ...
                 theMeasuredSTFdata(iSF) + theMeasuredSTFerrorData(iSF)*[-1 1], ...
                 '-', 'Color', [1 0 0], 'LineWidth', 4);
        plot(visStruct.axFit, examinedSpatialFrequencies(iSF) *[1 1], ...
                 theMeasuredSTFdata(iSF) + theMeasuredSTFerrorData(iSF)*[-1 1], ...
                 '-', 'Color', [1 0.5 0.5], 'LineWidth', 1.5);
    end

    % The mean data points
    plot(visStruct.axFit, examinedSpatialFrequencies, theMeasuredSTFdata, ...
          'ro', 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 14, 'LineWidth', 1.5);

    % Finish fit plot     
    set(visStruct.axFit, 'XScale', 'log', 'FontSize', 18);
    set(visStruct.axFit, 'XLim', [4 55], 'XTick', [5 10 20 40 60], 'YLim', [-0.1 0.75], 'YTick', [0:0.1:1]);
    grid(visStruct.axFit, 'on');
    axis(visStruct.axFit, 'square');
    xlabel(visStruct.axFit, 'spatial frequency (c/deg)');
    ylabel(visStruct.axFit, '\Delta F / F');
    title(visStruct.axFit, fitTitle, 'FontWeight', 'normal', 'FontSize', 15);


    % Plot the actual RF cone weights for the cone resulting in minRMSerror (minRMSerrorConeIndex)
    conesNum = size(theConeMosaic.coneRFpositionsDegs,1);
    Kc = fittedParams(iRGCindex, minRMSerrorConeIndex,1);


    KsToKc = fittedParams(iRGCindex, minRMSerrorConeIndex,2);
    Ks = Kc * KsToKc;
    
    theBestFitSurroundConeIndices = surroundConeIndices{minRMSerrorConeIndex};
    theBestFitSurroundConeWeights = surroundConeWeights{minRMSerrorConeIndex};
    theBestFitCenterConeIndices = centerConeIndices{minRMSerrorConeIndex};
    theBestFitCenterConeWeights = centerConeWeights{minRMSerrorConeIndex};

    theConeWeights = zeros(1, conesNum);
    theConeWeights(theBestFitSurroundConeIndices) = -Ks * theBestFitSurroundConeWeights;
    
    theConeWeights(theBestFitCenterConeIndices) = ...
        theConeWeights(theBestFitCenterConeIndices) + Kc*theBestFitCenterConeWeights;

    centerConePositionMicrons = theConeMosaic.coneRFpositionsMicrons(indicesOfModelConesDrivingTheRGCcenters(minRMSerrorConeIndex),:);
    centerConePositionDegs = theConeMosaic.coneRFpositionsDegs(indicesOfModelConesDrivingTheRGCcenters(minRMSerrorConeIndex),:);
    xRangeMicrons = centerConePositionMicrons(1) + 10*[-1 1];
    yRangeMicrons = centerConePositionMicrons(2) + 10*[-1 1];

    exclusivelySurroundConeIndices = find(theConeWeights<0);
    if (isempty(exclusivelySurroundConeIndices))
        maxActivationRange = Kc*max(theBestFitCenterConeWeights);
    else
        maxActivationRange = max(abs(theConeWeights(exclusivelySurroundConeIndices)));
    end

    cla(visStruct.axConeWeights);
    theConeMosaic.visualize(...
        'figureHandle', visStruct.hFig, 'axesHandle', visStruct.axConeWeights, ...
        'domain', 'microns', ...
        'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
        'domainVisualizationTicks', struct('x', -40:2:40, 'y', -40:2:40), ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'activation', theConeWeights, ...
        'activationRange', 1.2*maxActivationRange*[-1 1], ...
        'activationColorMap', brewermap(1024, '*RdBu'), ...
        'noYLabel', true, ...
        'fontSize', 18, ...
        'plotTitle', ' ');          
    


    % Plot the RF center and surround weighting profiles
    cla(visStruct.axRF);

    xArcMin = -4:0.01:4;
    xMicrons = centerConePositionMicrons(1) + xArcMin/60 * WilliamsLabData.constants.micronsPerDegreeRetinalConversion; 
    xDegs = centerConePositionDegs(1) + xArcMin/60;
    hold(visStruct.axRF, 'on');
    
    % Compute the minRMSerror profile
    theBestFitCenterConeIndices = centerConeIndices{minRMSerrorConeIndex};
    theBestFitCenterConeWeights = centerConeWeights{minRMSerrorConeIndex};
    theBestFitCentroidPosition = centroidPosition{minRMSerrorConeIndex};
    
    Kc = fittedParams(iRGCindex, minRMSerrorConeIndex,1);
    KsToKc = fittedParams(iRGCindex, minRMSerrorConeIndex,2);
    Ks = Kc * KsToKc;
    RcDegs = centerConeCharacteristicRadiusDegs(minRMSerrorConeIndex);
    RsDegs = fittedParams(iRGCindex, minRMSerrorConeIndex,3)*RcDegs;

    for iCenterCone = 1:numel(theBestFitCenterConeIndices)
        theConePosDegs = theConeMosaic.coneRFpositionsDegs(theBestFitCenterConeIndices(iCenterCone),:);
        theConeGain = theBestFitCenterConeWeights(iCenterCone);
        if (iCenterCone == 1)
            centerProfile = theConeGain * exp(-((xDegs-theConePosDegs(1))/RcDegs).^2);
        else
            centerProfile = centerProfile + theConeGain * exp(-((xDegs-theConePosDegs(1))/RcDegs).^2);
        end
    end
    referenceCenterProfile = Kc * centerProfile;


    referenceSurroundProfile = Ks * exp(-((xDegs-theBestFitCentroidPosition(1))/RsDegs).^2);
    referenceProfile = referenceCenterProfile - referenceSurroundProfile;
    maxReferenceProfile = max(referenceProfile);

    % Plot the minRMSerror  center profile
    faceColor = 1.7*[100 0 30]/255;
    edgeColor = [0.7 0.2 0.2];
    faceAlpha = 0.4;
    lineWidth = 1.0;
    baseline = 0;
    shadedAreaPlot(visStruct.axRF, xMicrons, referenceCenterProfile, ...
         baseline, faceColor, edgeColor, faceAlpha, lineWidth);
    
    % Plot the minRMSerror surround profile
    faceColor = [75 150 200]/255;
    edgeColor = [0.3 0.3 0.7];
    shadedAreaPlot(visStruct.axRF, xMicrons, -referenceSurroundProfile, ...
         baseline, faceColor, edgeColor, faceAlpha, lineWidth);

    % Plot the minRMS RGC profile
    plot(visStruct.axRF, xMicrons, referenceProfile, 'r-', 'LineWidth', 4, 'Color', [0.4 0 0]);
    plot(visStruct.axRF, xMicrons, referenceProfile, 'r-', 'LineWidth', 1.5);


    % Plot the RGC profile for all other examined cone positions which result in higher RMSerrors 
    for iiCone = 1:iCone
        if (iiCone ~= minRMSerrorConeIndex)
            Kc = fittedParams(iRGCindex, iiCone,1);
            KsToKc = fittedParams(iRGCindex, iiCone,2);
            Ks = Kc * KsToKc;
            RcDegs = centerConeCharacteristicRadiusDegs(iiCone);
            RsDegs = fittedParams(iRGCindex, iiCone,3)*RcDegs;

            theCurrentFitCenterConeIndices = centerConeIndices{iiCone};
            theCurrentFitCenterConeWeights = centerConeWeights{iiCone};
            theCurrentFitCentroidPosition = centroidPosition{iiCone};

            for iCenterCone = 1:numel(theCurrentFitCenterConeIndices)
                theConePosDegs = theConeMosaic.coneRFpositionsDegs(theCurrentFitCenterConeIndices(iCenterCone),:);
                theConeGain = theCurrentFitCenterConeWeights(iCenterCone);
                
                if (iCenterCone == 1)
                    centerProfile = theConeGain * exp(-((xDegs-theConePosDegs(1))/RcDegs).^2);
                else
                    centerProfile = centerProfile + theConeGain * exp(-((xDegs-theConePosDegs(1))/RcDegs).^2);
                end
            end
            centerProfile = Kc * centerProfile;
            surroundProfile = Ks * exp(-((xDegs-theCurrentFitCentroidPosition(1))/RsDegs).^2);

            rfProfile = centerProfile-surroundProfile;
            rfProfile = rfProfile/max(rfProfile)*maxReferenceProfile;
            linePlotHandle2 = plot(visStruct.axRF, xMicrons, rfProfile, '-', 'Color', [0.0 0.0 0.0], 'LineWidth', 1.5);
            % Opacity of lines : 0.5
            linePlotHandle2.Color = [linePlotHandle2.Color 0.25];
        end
    end
    

    % Plot the cones aperture schematics
    coneDiameterArcMin = RcDegs/sqrt(2.0)/0.204*60;
    for k = -6:6
        xOutline = coneDiameterArcMin*(k+[-0.48 0.48 0.3 0.3 -0.3 -0.3 -0.48]);
        yOutline = max(centerProfile)*([-0.2 -0.2 -0.3 -0.5 -0.5 -0.3 -0.2]-0.1);
        xOutlineMicrons = centerConePositionMicrons(1) + xOutline/60* WilliamsLabData.constants.micronsPerDegreeRetinalConversion;                   
        
        patch(visStruct.axRF, xOutlineMicrons, yOutline, -10*eps*ones(size(xOutline)), ...
            'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0.2 0.2 0.2], ...
            'LineWidth', 0.5, 'FaceAlpha', 0.5);
    end

    hold(visStruct.axRF, 'off');
    set(visStruct.axRF, 'YColor', 'none', 'YLim', max(referenceCenterProfile)*[-0.5 1.05], 'YTick', [0], ...
        'XLim', xRangeMicrons, 'XTick', -40:2:40, 'FontSize', 18);
    xlabel(visStruct.axRF,'retinal space (microns)');
    xtickangle(visStruct.axRF, 0);

    % Compute Rs/Rc and Kc/Ks ratios
    if (numel(theBestFitCenterConeIndices) == 1)
        radiusRatio = RsDegs/RcDegs;
    else
        % More than 1 cone in RF center, so compute radiusRatio based on sqrt(cones)
        radiusRatio = sqrt(numel(theBestFitSurroundConeIndices) / numel(theBestFitCenterConeIndices));
    end
    sensitivityRatio = Kc/Ks
    sensitivityRatio = (Kc * max(theBestFitCenterConeWeights)) / (Ks * max(theBestFitSurroundConeWeights))
    
    

    if (isempty(rmsErrorsTrain))
        title(visStruct.axRF, sprintf('Rs/Rc: %2.2f, Kc/Ks: %2.2f, RMSE: %2.2f', ...
            radiusRatio, sensitivityRatio, ...
            rmsErrors(iRGCindex,minRMSerrorConeIndex)), ...
            'FontWeight', 'normal', 'FontSize', 15);
    else
        title(visStruct.axRF, sprintf('Rs/Rc: %2.2f, Kc/Ks: %2.2f, RMSE: %2.2f/%2.2f (test/train)', ...
            radiusRatio, sensitivityRatio, ...
            rmsErrors(iRGCindex,minRMSerrorConeIndex), ...
            rmsErrorsTrain(iRGCindex,minRMSerrorConeIndex)), ...
            'FontWeight', 'normal', 'FontSize', 15);
    end



    % add frame to video
    drawnow;
    visStruct.videoOBJ.writeVideo(getframe(visStruct.hFig));

end