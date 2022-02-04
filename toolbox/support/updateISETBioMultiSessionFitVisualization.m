function updateISETBioMultiSessionFitVisualization(visStruct, iRGCindex, iCone, ...
    indicesOfModelConesDrivingTheRGCcenters, theConeMosaic, ...
    centerConeCharacteristicRadiusDegs, surroundConeIndices, surroundConeWeights, ...
    fittedParams, rmsErrorsAllTestSessions, rmsErrorsTrain, ...
    examinedSpatialFrequencies, fittedSTFs, ...
    theMeasuredSTFdata, theMeasuredSTFerrorData, ...
    fitTitle, dTrainSession, dTestSession)



    % mean over all cross-validated sessions
    rmsErrors = squeeze(mean(rmsErrorsAllTestSessions,1, 'omitnan'));

    % max (over all cones) of the mean(over sessions) rmsError
    maxRMSerror = max(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');

    % min (over all cones) of the mean(over sessions) rmsError
    [minRMSerror, minRMSerrorConeIndex] = min(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');

    % Plot the spatial map of rms errors (for different assumed RF center cone positions)
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
        text(visStruct.axMap, -12, 18, ...
            sprintf('RMSE map (range: %2.2f - %2.2f)', minRMSerror, maxRMSerror), ...
            'FontWeight', 'normal', 'FontSize', 15);
    end


    % Plot the relationship between RMSerrors for the different test sessions
    cla(visStruct.axSessionsRMSE);

    errorRange(1)= round(max([0 min([min(rmsErrorsTrain(rmsErrorsTrain>0)) min(rmsErrorsAllTestSessions(rmsErrorsAllTestSessions>0))])-1]));
    errorRange(2)= round(max([max(rmsErrorsTrain(:)) max(rmsErrorsAllTestSessions(:))])+1);
    plot(visStruct.axSessionsRMSE, [errorRange(1) errorRange(2)], [errorRange(1) errorRange(2)], 'k-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0);
    hold(visStruct.axSessionsRMSE, 'on');

    p1 = scatter(visStruct.axSessionsRMSE, ...
        squeeze(rmsErrorsTrain(iRGCindex, 1:iCone)), ...
        squeeze(rmsErrorsAllTestSessions(1, iRGCindex, 1:iCone)), ...
        81, 'filled', ...
        'MarkerFaceColor', [0.7 0.2 0.8], 'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.3);
    
    p2 = scatter(visStruct.axSessionsRMSE, ...
        squeeze(rmsErrorsTrain(iRGCindex, 1:iCone)), ...
        squeeze(rmsErrorsAllTestSessions(2, iRGCindex, 1:iCone)), ...
        81, 'filled', ...
        'MarkerFaceColor', [0.3 0.7 0.2], 'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.3);

%     p3 = scatter(visStruct.axSessionsRMSE, ...
%         squeeze(rmsErrorsTrain(iRGCindex, 1:iCone)), ...
%         0.5*(squeeze(rmsErrorsAllTestSessions(1, iRGCindex, 1:iCone))+squeeze(rmsErrorsAllTestSessions(2, iRGCindex, 1:iCone))), ...
%         64, 'filled', ...
%         'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerEdgeColor', [0.25 0.25 0.25], ...
%         'MarkerFaceAlpha', 0.5);

    
    plot(visStruct.axSessionsRMSE, ...
        squeeze(rmsErrorsTrain(iRGCindex, minRMSerrorConeIndex))*[1 1], ...
        squeeze(rmsErrorsAllTestSessions(1:2, iRGCindex, minRMSerrorConeIndex)), ...
        'k-', 'LineWidth', 1.0);

    scatter(visStruct.axSessionsRMSE, ...
        squeeze(rmsErrorsTrain(iRGCindex, minRMSerrorConeIndex)), ...
        squeeze(rmsErrorsAllTestSessions(1, iRGCindex, minRMSerrorConeIndex)), ...
        144, 'h', 'filled', 'LineWidth', 1.0,...
        'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.7 0.2 0.8], ...
        'MarkerFaceAlpha', 0.8);

    scatter(visStruct.axSessionsRMSE, ...
        squeeze(rmsErrorsTrain(iRGCindex, minRMSerrorConeIndex)), ...
        squeeze(rmsErrorsAllTestSessions(2, iRGCindex, minRMSerrorConeIndex)), ...
        144, 'h', 'filled', 'LineWidth', 1.0, ...
        'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.3 0.7 0.2], ...
        'MarkerFaceAlpha', 0.8);

    

    legend(visStruct.axSessionsRMSE, [p1, p2], {sprintf('session %d', dTestSession(1)), sprintf('session %d', dTestSession(2))}, ...
        'location', 'SouthEast');
    % Finish fit plot     
    set(visStruct.axSessionsRMSE, 'FontSize', 18);
    set(visStruct.axSessionsRMSE, 'XLim', errorRange, 'XTick', 0:5:50, ...
        'YLim', errorRange, 'YTick', 0:5:50);
    grid(visStruct.axSessionsRMSE, 'on');
    axis(visStruct.axSessionsRMSE, 'square');
    xlabel(visStruct.axSessionsRMSE, sprintf('training RMSE (session-%d)', dTrainSession));
    ylabel(visStruct.axSessionsRMSE, 'cv-RMSE');
    %title(visStruct.axSessionsRMSE, fitTitle, 'FontWeight', 'normal', 'FontSize', 15);
    
    



    % Plot the actual RF cone weights for the cone resulting in minRMSerror (minRMSerrorConeIndex)
    conesNum = size(theConeMosaic.coneRFpositionsDegs,1);
    Kc = fittedParams(iRGCindex, minRMSerrorConeIndex,1);
    KsToKc = fittedParams(iRGCindex, minRMSerrorConeIndex,2);
    Ks = Kc * KsToKc;
    
    theConeWeights = zeros(1, conesNum);
    theConeWeights(surroundConeIndices{minRMSerrorConeIndex}) = -Ks * surroundConeWeights{minRMSerrorConeIndex};
    theConeWeights(indicesOfModelConesDrivingTheRGCcenters(minRMSerrorConeIndex)) = ...
        theConeWeights(indicesOfModelConesDrivingTheRGCcenters(minRMSerrorConeIndex)) + Kc;

    centerConePositionMicrons = theConeMosaic.coneRFpositionsMicrons(indicesOfModelConesDrivingTheRGCcenters(minRMSerrorConeIndex),:);
    xRangeMicrons = centerConePositionMicrons(1) + 10*[-1 1];
    yRangeMicrons = centerConePositionMicrons(2) + 10*[-1 1];
    exclusivelySurroundConeIndices = find(theConeWeights<0);
    if (isempty(exclusivelySurroundConeIndices))
        maxActivationRange = Kc;
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
        'activationRange', min(theConeWeights)*1.2*[1 -1], ...
        'horizontalActivationColorBarInside', true, ...
        'colorbarTickLabelColor', [0 0 0], ...
        'activationColorMap', brewermap(1024, '*RdBu'), ...
        'noYLabel', true, ...
        'fontSize', 18, ...
        'plotTitle', ' ');  


    % Plot the cone mosaic
    labelConesWithIndices = find(...
        (abs(theConeWeights(:))> 0.05*max(theConeWeights(:))) | ...
        (theConeMosaic.coneTypes == theConeMosaic.SCONE_ID));

    cla(visStruct.axConeMosaic);
    theConeMosaic.visualize(...
        'figureHandle', visStruct.hFig, 'axesHandle', visStruct.axConeMosaic, ...
        'domain', 'microns', ...
        'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
        'domainVisualizationTicks', struct('x', -40:2:40, 'y', -40:2:40), ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'labelConesWithIndices', labelConesWithIndices, ...
        'noYLabel', true, ...
        'fontSize', 18, ...
        'plotTitle', ' ');  


    % Plot the best fit so far
    cla(visStruct.axSTFfits);

    rr = 0.5;
    session1Color = [0.7 0.2 0.8]*rr + [1 1 1]*(1-rr);
    session2Color = [0.3 0.7 0.2]*rr + [1  1 1]*(1-rr);

    % Session 1 fitted STF with scaled STF from training model
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, squeeze(fittedSTFs(1, minRMSerrorConeIndex,:)), 'k-', ...
        'Color', session1Color*0.5, 'LineWidth', 4.0);
    hold(visStruct.axSTFfits, 'on');
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, squeeze(fittedSTFs(1, minRMSerrorConeIndex,:)), 'k-', ...
        'Color', session1Color, 'LineWidth', 1.5);
    % Session 1 std.err STF
    for iSF = 1:numel(examinedSpatialFrequencies)
        plot(visStruct.axSTFfits, examinedSpatialFrequencies(iSF)*[1 1], ...
            theMeasuredSTFdata(1,iSF) + theMeasuredSTFerrorData(1, iSF)*[-1 1], '-', ...
            'Color', session1Color*0.5, 'LineWidth', 3.0);
        plot(visStruct.axSTFfits, examinedSpatialFrequencies(iSF)*[1 1], ...
            theMeasuredSTFdata(1,iSF) + theMeasuredSTFerrorData(1, iSF)*[-1 1], '-', ...
            'Color', session1Color, 'LineWidth', 1.5);
    end
    % Session 1 mean STF
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, theMeasuredSTFdata(1,:), 'o', ...
        'MarkerSize', 14, 'MarkerFaceColor', session1Color, 'MarkerEdgeColor', session1Color*0.5, ...
        'LineWidth', 2.0);

    % Session 2 fitted STF with scaled STF from training model
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, squeeze(fittedSTFs(2, minRMSerrorConeIndex,:)), 'k-', ...
        'Color', session2Color*0.5, 'LineWidth', 4.0);
    
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, squeeze(fittedSTFs(2, minRMSerrorConeIndex,:)), 'k-', ...
        'Color', session2Color, 'LineWidth', 1.5);
    % Session 2 std.err STF
    for iSF = 1:numel(examinedSpatialFrequencies)
        plot(visStruct.axSTFfits, examinedSpatialFrequencies(iSF)*[1 1], ...
            theMeasuredSTFdata(2,iSF) + theMeasuredSTFerrorData(2, iSF)*[-1 1], '-', ...
            'Color', session2Color*0.5, 'LineWidth', 3.0);
        plot(visStruct.axSTFfits, examinedSpatialFrequencies(iSF)*[1 1], ...
            theMeasuredSTFdata(2,iSF) + theMeasuredSTFerrorData(2, iSF)*[-1 1], '-', ...
            'Color', session2Color, 'LineWidth', 1.5);
    end
    % Session 2 mean STF
    plot(visStruct.axSTFfits, examinedSpatialFrequencies, theMeasuredSTFdata(2,:), 'o', ...
        'MarkerSize', 14, 'MarkerFaceColor', session2Color, 'MarkerEdgeColor', session2Color*0.5, ...
        'LineWidth', 2.0);

    % Finish fit plot     
    set(visStruct.axSTFfits, 'XScale', 'log', 'FontSize', 18);
    set(visStruct.axSTFfits, 'XLim', [4 55], 'XTick', [5 10 20 40 60], 'YLim', [-0.1 0.75], 'YTick', [0:0.1:1]);
    grid(visStruct.axSTFfits, 'on');
    axis(visStruct.axSTFfits, 'square');
    xlabel(visStruct.axSTFfits, 'spatial frequency (c/deg)');
    ylabel(visStruct.axSTFfits, '\Delta F / F');


    % Plot the RF center and surround weighting profiles
    cla(visStruct.axRF);

    xArcMin = -4:0.01:4;
    xDegs = xArcMin/60;
    xMicrons = centerConePositionMicrons(1) + xDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion; 

    hold(visStruct.axRF, 'on');
    
    % Compute the minRMSerror profile
    Kc = fittedParams(iRGCindex, minRMSerrorConeIndex,1);
    KsToKc = fittedParams(iRGCindex, minRMSerrorConeIndex,2);
    Ks = Kc * KsToKc;
    RcDegs = centerConeCharacteristicRadiusDegs(minRMSerrorConeIndex);
    RsDegs = fittedParams(iRGCindex, minRMSerrorConeIndex,3)*RcDegs;
    centerProfile = Kc * exp(-(xDegs/RcDegs).^2);
    surroundProfile = Ks * exp(-(xDegs/RsDegs).^2);
    referenceProfile = centerProfile - surroundProfile;
    maxReferenceProfile = max(referenceProfile);

    % Plot the RGC profile for all other which result in higher RMSerrors 
    for iiCone = 1:iCone
        if (iiCone ~= minRMSerrorConeIndex)
            Kc = fittedParams(iRGCindex, iiCone,1);
            KsToKc = fittedParams(iRGCindex, iiCone,2);
            Ks = Kc * KsToKc;
            RcDegs = centerConeCharacteristicRadiusDegs(iiCone);
            RsDegs = fittedParams(iRGCindex, iiCone,3)*RcDegs;
            centerProfile = Kc * exp(-(xDegs/RcDegs).^2);
            surroundProfile = Ks * exp(-(xDegs/RsDegs).^2);
            rfProfile = centerProfile-surroundProfile;
            rfProfile = rfProfile/max(rfProfile)*maxReferenceProfile;
            linePlotHandle2 = plot(visStruct.axRF, xMicrons, rfProfile, '-', 'Color', [0.0 0.0 0.0], 'LineWidth', 1.5);

            % Opacity of lines : 0.5
            linePlotHandle2.Color = [linePlotHandle2.Color 0.25];
        end
    end
    

    % Plot the minRMSerror profile
    Kc = fittedParams(iRGCindex, minRMSerrorConeIndex,1);
    KsToKc = fittedParams(iRGCindex, minRMSerrorConeIndex,2);
    Ks = Kc * KsToKc;
    RcDegs = centerConeCharacteristicRadiusDegs(minRMSerrorConeIndex);
    RsDegs = fittedParams(iRGCindex, minRMSerrorConeIndex,3)*RcDegs;
    centerProfile = Kc * exp(-(xDegs/RcDegs).^2);
    surroundProfile = Ks * exp(-(xDegs/RsDegs).^2);

    % Plot the minRMSerror  center profile
    faceColor = 1.7*[100 0 30]/255;
    edgeColor = [0.7 0.2 0.2];
    faceAlpha = 0.4;
    lineWidth = 1.0;
    baseline = 0;
    shadedAreaPlot(visStruct.axRF, xMicrons, centerProfile, ...
         baseline, faceColor, edgeColor, faceAlpha, lineWidth);
    
    
    % Plot the minRMSerror surround profile
    faceColor = [75 150 200]/255;
    edgeColor = [0.3 0.3 0.7];
    shadedAreaPlot(visStruct.axRF, xMicrons, -surroundProfile, ...
         baseline, faceColor, edgeColor, faceAlpha, lineWidth);

    % Plot the minRMS RGC profile
    plot(visStruct.axRF, xMicrons, centerProfile-surroundProfile, 'r-', 'LineWidth', 4, 'Color', [0.4 0 0]);
    plot(visStruct.axRF, xMicrons, centerProfile-surroundProfile, 'r-', 'LineWidth', 1.5);


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
    set(visStruct.axRF, 'YColor', 'none', 'YLim', max(centerProfile)*[-0.5 1.05], 'YTick', [0], ...
        'XLim', xRangeMicrons, 'XTick', -40:2:40, 'FontSize', 18);
    xlabel(visStruct.axRF,'retinal space (microns)');
    xtickangle(visStruct.axRF, 0);

    if (isempty(rmsErrorsTrain))
        title(visStruct.axRF, sprintf('Rs/Rc: %2.2f, Kc/Ks: %2.2f, RMSE: %2.2f', ...
            RsDegs/RcDegs, 1./KsToKc, ...
            rmsErrors(iRGCindex,minRMSerrorConeIndex)), ...
            'FontWeight', 'normal', 'FontSize', 15);
    else
        title(visStruct.axRF, sprintf('Rs/Rc: %2.2f, Kc/Ks: %2.2f, RMSE: %2.2f/%2.2f (test/train)', ...
            RsDegs/RcDegs, 1./KsToKc, ...
            rmsErrors(iRGCindex,minRMSerrorConeIndex), ...
            rmsErrorsTrain(iRGCindex,minRMSerrorConeIndex)), ...
            'FontWeight', 'normal', 'FontSize', 15);
    end


    


    % add frame to video
    drawnow;
    visStruct.videoOBJ.writeVideo(getframe(visStruct.hFig));


end
