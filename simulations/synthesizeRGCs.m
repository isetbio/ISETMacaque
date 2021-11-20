function synthesizeRGCs(monkeyID, apertureParams,  coneCouplingLambda, opticalDefocusDiopters, eccCenterMicrons, eccRadiusMicrons, PolansSubject, visualStimulus)
    
    % Synthesize responses filename
    responseFileName = responsesFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus);
    
    load(responseFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'examinedSpatialFrequencies');
    
    
    p = extractedDoGParams();
    meanRetinalKcToKsRatioLconeRGC = mean(p.LcenterRGC.KcToKsRatios);
    meanRetinalKcToKsRatioMconeRGC = mean(p.McenterRGC.KcToKsRatios);
    meanRetinalRsToRcRatioLconeRGC = mean(p.LcenterRGC.RsToRcRatios);
    meanRetinalRsToRcRatioMconeRGC = mean(p.McenterRGC.RsToRcRatios);
    
    % Average L and M cone data
    meanRetinalKcToKsRatioLconeRGC = mean([meanRetinalKcToKsRatioLconeRGC meanRetinalKcToKsRatioMconeRGC]);
    meanRetinalKcToKsRatioMconeRGC = meanRetinalKcToKsRatioLconeRGC;
    meanRetinalRsToRcRatioLconeRGC = mean([meanRetinalRsToRcRatioLconeRGC meanRetinalRsToRcRatioMconeRGC]);
    meanRetinalRsToRcRatioMconeRGC = meanRetinalRsToRcRatioLconeRGC;
    
    meanRetinalIntegratedCenterToSurroundSensitivityLconeRGC = meanRetinalKcToKsRatioLconeRGC .* (1./meanRetinalRsToRcRatioLconeRGC).^2;
    meanRetinalIntegratedSurroundToCenterSensitivityLconeRGC = 1/meanRetinalIntegratedCenterToSurroundSensitivityLconeRGC;
    meanRetinalIntegratedCenterToSurroundSensitivityMconeRGC = meanRetinalKcToKsRatioMconeRGC .* (1./meanRetinalRsToRcRatioMconeRGC).^2;
    meanRetinalIntegratedSurroundToCenterSensitivityMconeRGC = 1/meanRetinalIntegratedCenterToSurroundSensitivityMconeRGC;

    % Select model cones within the region of interest
    foveolaROI = struct(...
        'units', 'microns', ...
        'shape', 'rect', ...
        'center', eccCenterMicrons, ...
        'width',  eccRadiusMicrons*2, ...
        'height', eccRadiusMicrons*2, ...
        'rotation', 0);
    coneIndicesWithinROI = theConeMosaic.indicesOfConesWithinROI(foveolaROI);
    coneTypesWithinROI = theConeMosaic.coneTypes(coneIndicesWithinROI);
    RGCcenterPositionsWithinROI = theConeMosaic.coneRFpositionsMicrons(coneIndicesWithinROI,:);
    

    % Transform into a modulation response
    coneMosaicSpatiotemporalContrastResponseModulations = bsxfun(@times, bsxfun(@minus, ...
        coneMosaicSpatiotemporalActivation, coneMosaicBackgroundActivation), 1./coneMosaicBackgroundActivation);
    
    wThreshold = 1/100;
    validRGCs = 0;
    validRGCsConeTypes = [];
    
    allConesNum = size(theConeMosaic.coneRFpositionsMicrons,1);
    RFsWithinROI = zeros(numel(coneIndicesWithinROI), allConesNum);
    sConeIndicesInAllOfTheMosaic = find(theConeMosaic.coneTypes == cMosaic.SCONE_ID);
    
    for iCone = 1:numel(coneIndicesWithinROI)
        theConeIndex = coneIndicesWithinROI(iCone);
        theConeType = coneTypesWithinROI(iCone);
        theConePositionMicrons = RGCcenterPositionsWithinROI(iCone,:);
        
        if (theConeType == cMosaic.SCONE_ID)
            % Ignore S-cone - not feeding into a a midget RGC center
            continue;
        end
        validRGCs = validRGCs+1;
        validRGCsConeTypes(validRGCs) = theConeType;
        
        % Compute distance from this cone to all cones of the mosaic
        distancesToAllConesOfTheMosaic = sqrt(sum((bsxfun(@minus, theConeMosaic.coneRFpositionsMicrons, theConePositionMicrons)).^2,2));
        
        % Center characteristic radius
        Rc = theConeMosaic.apertureBlurSigmaMicronsOfConeFromItsBlurZone(theConeIndex) * sqrt(2.0);
                
        % Compute surround radius
        switch (theConeType)
            case cMosaic.LCONE_ID
                Rs = Rc * meanRetinalRsToRcRatioLconeRGC;
            case cMosaic.MCONE_ID
                Rs = Rc * meanRetinalRsToRcRatioMconeRGC;
        end
        
        
        % Compute weights to all cones of the mosaic
        weightsToAllConesOfTheMosaic = exp(-(distancesToAllConesOfTheMosaic/Rs).^2);
        
        % Zero connectivity to S-cones
        weightsToAllConesOfTheMosaic(sConeIndicesInAllOfTheMosaic) = 0;
        
        % Zero connectivity to cones whose weighting is < wThreshold
        weightsToAllConesOfTheMosaic(find(weightsToAllConesOfTheMosaic < wThreshold)) = 0;
        
        % Find which cones will feed into the surround
        surroundConeIndices = find(weightsToAllConesOfTheMosaic > 0);
        surroundConeWeights = weightsToAllConesOfTheMosaic(surroundConeIndices);
        
        % Unit volume
        surroundConeWeights = surroundConeWeights / sum(surroundConeWeights);
        
        % Adjust to match required meanIntegratedCenterToSurroundSensitivity
        switch (theConeType)
            case cMosaic.LCONE_ID
                surroundConeWeights = surroundConeWeights * meanRetinalIntegratedSurroundToCenterSensitivityLconeRGC;
            case cMosaic.MCONE_ID
                surroundConeWeights = surroundConeWeights * meanRetinalIntegratedSurroundToCenterSensitivityMconeRGC;
        end
        
        
        % Generate RF weights map
        RFsWithinROI(validRGCs,surroundConeIndices) = -surroundConeWeights;
        RFsWithinROI(validRGCs,theConeIndex) = 1;
        
        % Pool cones feeding into the surround
        surroundResponses = sum(bsxfun(@times, ...
            coneMosaicSpatiotemporalContrastResponseModulations(:,:, surroundConeIndices), ...
            reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)])),3);
        
        centerResponses = coneMosaicSpatiotemporalContrastResponseModulations(:,:, theConeIndex);
        synthesizedRGCResponses(:,:,validRGCs) = centerResponses - surroundResponses;
    end
    
    
    nSFs = size(synthesizedRGCResponses,1);
    nTimeBins = size(synthesizedRGCResponses,2);
    nRGCs = size(synthesizedRGCResponses,3);
    
    intepolatedSinusoidSamplesNum = 100;
    theFittedSineWaveResponses = zeros(nRGCs, nSFs, intepolatedSinusoidSamplesNum);
    timeHR = linspace(temporalSupportSeconds(1), temporalSupportSeconds(end), intepolatedSinusoidSamplesNum);
    
    showSineWaveFits = ~true;
    
    % Fit sinusoids to the responses
    if (showSineWaveFits)
        hFig = figure(555); clf;
        set(hFig, 'Position', [10 10 2900 1400], 'Color', [1 1 1]);

        rowsNum = 3;
        colsNum = 5;
        sv = NicePlot.getSubPlotPosVectors(...
                       'colsNum', colsNum, ...
                       'rowsNum', rowsNum, ...
                       'heightMargin',  0.02, ...
                       'widthMargin',    0.01, ...
                       'leftMargin',     0.04, ...
                       'rightMargin',    0.01, ...
                       'bottomMargin',   0.04, ...
                       'topMargin',      0.02);
                   sv = sv'; 
    end
         
    rowsNum = 3;
    colsNum = 4;
    sv2 = NicePlot.getSubPlotPosVectors(...
                       'colsNum', colsNum, ...
                       'rowsNum', rowsNum, ...
                       'heightMargin',  0.02, ...
                       'widthMargin',    0.02, ...
                       'leftMargin',     0.03, ...
                       'rightMargin',    0.00, ...
                       'bottomMargin',   0.05, ...
                       'topMargin',      0.00);
    sv2 = sv2';   
    

    % Compute OTFs
    synthesizedRGCOTFs = zeros(nRGCs, nSFs);
    
    for iRGC = 1:nRGCs
        % Retrieve the RGCs response time series
        theRGCresponses = squeeze(synthesizedRGCResponses(:,:,iRGC));
        maxR = max(abs(theRGCresponses(:)));
        theRGCresponses = theRGCresponses / maxR;
        
        switch (validRGCsConeTypes(iRGC))
            case cMosaic.LCONE_ID
                coneColor = [1 0.1 0.5];
            case cMosaic.MCONE_ID
                coneColor = [0.1 1 0.5];
        end
            
        % Fit sinusoid to time series to extract this RGC's OTF
        for iSF = 1:nSFs
            % Retrieve the time series response for this spatial frequency
            theResponseTimeSeries = theRGCresponses(iSF,:);
            
            % Fit sinusoid to the response
            [theFittedSineWaveResponses(iRGC,iSF,:), fittedParams] = fitSinusoidToResponseTimeSeries(...
                temporalSupportSeconds, theResponseTimeSeries', ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, timeHR);
            % Extract the amplitude param
            synthesizedRGCOTFs(iRGC,iSF) = fittedParams(1);
            
            
            if (showSineWaveFits)
                ax = subplot('Position', sv(iSF).v);
                scatter(ax, temporalSupportSeconds*1000, theResponseTimeSeries*maxR, 100, 'filled', ...
                    'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'MarkerFaceAlpha', 0.6);
                hold(ax, 'on');
                plot(ax, timeHR*1000, squeeze(theFittedSineWaveResponses(iRGC,iSF,:))*maxR, 'k-', 'Color', coneColor*0.5, 'LineWidth', 1.5); 
                plot(ax,[temporalSupportSeconds(1) temporalSupportSeconds(end)]*1000, [0 0 ], 'k-');
                hold(ax, 'off');
                set(ax, 'YLim', [-1 1],  'YTick', -1:0.5:1)
                set(ax,'XTick', 0:100:1000,'FontSize', 12);
                title(ax,sprintf('%2.1f c/deg (RGC #%d)', examinedSpatialFrequencies(iSF), iRGC), 'FontWeight', 'bold');
                if (iSF == nSFs)
                    xlabel(ax, 'time (ms)');
                else
                    set(ax, 'XTick', []);
                end
               
            end
        end
        
        
        if (showSineWaveFits)
             drawnow
             pause
        end
        
    end
    
    % Clear-up some memory
    fprintf('Clearing up memory\n');
    clear 'coneMosaicBackgroundActivation'
    clear 'coneMosaicSpatiotemporalActivation'
    
    if ((opticalDefocusDiopters == 0) && (isempty(PolansSubject)))
        fprintf(2,'Deconvolving optics/stimulus so as to estimate retinal RGC SF tuning functions \n');
        % If diffraction-limited optics, deconvolve OTF and stimulus OTF
        
        % Load in the diffractionLimitedOTF
        session = 'mean';
        [~,~,~, ~,~,~,diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, session);
        
        % Compute the stimulus OTF
        stimulusOTF = computeStimulusOTF(diffractionLimitedOTF.sf);

        % Max amplitude before
        maxBefore = max(synthesizedRGCOTFs, [],2);
        
        % Deconvolve
        synthesizedRGCOTFsDeconvolved = bsxfun(@times, synthesizedRGCOTFs, 1./stimulusOTF);
        synthesizedRGCOTFsDeconvolved = bsxfun(@times, synthesizedRGCOTFsDeconvolved, 1./diffractionLimitedOTF.otf);
        
        % Adjust to unit max
        maxAfter = max(synthesizedRGCOTFsDeconvolved, [],2);
        gains = maxBefore ./ maxAfter;
        
        for iRGC = 1:numel(gains)
            synthesizedRGCOTFs(iRGC,:) = synthesizedRGCOTFsDeconvolved(iRGC,:) * gains(iRGC);
        end
    end
        
    useMeasuredDataInsteadOfSynthesizedData = ~true;
    if (useMeasuredDataInsteadOfSynthesizedData)
        fprintf(2,'Using MEASURED SF curves, NOT SYNTHESIZED\n');
        clear 'synthesizedRGCOTFs'
        clear 'validRGCsConeTypes'
        % Load in the diffractionLimitedOTF
        session = 'mean';
        [dFresponsesLcenterRGCs, dFresponsesMcenterRGCs, ~, ~, ~, ~, diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, session);
        
        idx = 1:size(dFresponsesLcenterRGCs,1);
        validRGCsConeTypes(idx) = cMosaic.LCONE_ID;
        synthesizedRGCOTFs(idx,:) = dFresponsesLcenterRGCs;
        
        idx = idx(end) + (1:size(dFresponsesMcenterRGCs,1));
        validRGCsConeTypes(idx) = cMosaic.MCONE_ID;
        synthesizedRGCOTFs(idx,:) = dFresponsesMcenterRGCs;
        nRGCs = size(synthesizedRGCOTFs,1);
        
        % Data have diffraction-limited OTF removed. Also Remove stimulusOTF
        synthesizedRGCOTFs = bsxfun(@times, synthesizedRGCOTFs, 1./diffractionLimitedOTF.otf);
    end
    
    
    % Plot the MTFs
    hFig = figure(556); clf;
    plotEachCellSeparately = ~true;
    if (plotEachCellSeparately)
        set(hFig, 'Position', [10 10 2900 1400], 'Color', [1 1 1]);
    else
        set(hFig, 'Position', [10 10 500 500], 'Color', [1 1 1]);
    end
    
    
    sfHR = linspace(1,100, 200);
    
    DoGmodelParamsLconeRGCs = [];
    DoGmodelParamsMconeRGCs = [];
    iLconeRGC = 0;
    iMconeRGC = 0;
    
    
    for iRGC = 1:nRGCs
        
        theSynthesizedOTF = squeeze(synthesizedRGCOTFs(iRGC,:));
        
         % Fit synthesized OTF
        [theFittedSynthesizedOTF, theFreeRcDoGParams, theFreeRcRMSError] = ...
                fitDogModelToOTF(...
                    examinedSpatialFrequencies, theSynthesizedOTF, [], ...
                    [], sfHR, 1.25, 'lsqcurvefit');
        % Extract fit params
        freeRcDegs = theFreeRcDoGParams(2);
        freeRcMicrons = freeRcDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        Rc = freeRcMicrons;
        RsOverRc = theFreeRcDoGParams(4);
        Rs = RsOverRc * Rc;
        KsOverKc = theFreeRcDoGParams(3);

        switch (validRGCsConeTypes(iRGC))
             case cMosaic.LCONE_ID
                iLconeRGC = iLconeRGC + 1;
                DoGmodelParamsLconeRGCs(iLconeRGC,:) = [Rc RsOverRc 1/KsOverKc];
             case cMosaic.MCONE_ID
                iMconeRGC = iMconeRGC + 1;
                DoGmodelParamsMconeRGCs(iMconeRGC,:) = [Rc RsOverRc 1/KsOverKc];
        end
            
        allFittedSynthesizedOTFs(iRGC,:) = theFittedSynthesizedOTF;
        
        if (plotEachCellSeparately)         
            [col,row] = ind2sub(size(sv2), iRGC);
       
            switch (validRGCsConeTypes(iRGC))
                 case cMosaic.LCONE_ID
                    coneColor = [1 0.1 0.5];
                 case cMosaic.MCONE_ID
                     coneColor = [0.1 1 0.5];
            end

        
            ax = subplot('Position', sv2(iRGC).v);
            plot(ax,examinedSpatialFrequencies, theSynthesizedOTF, 'o', ...
                'MarkerSize', 14, 'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'LineWidth', 1.5); 
            hold(ax, 'on');
       
            plot(ax, sfHR, theFittedSynthesizedOTF, '-', 'Color', [1 0.1 0.5]*0.5, 'LineWidth', 1.5);
            text(ax, 1.05, 0.12, sprintf('Rc: %2.2f um\nKc/Ks: %2.2f\nRs/Rc: %2.2f', ...
                           Rc, ...
                           1/KsOverKc, ...
                           RsOverRc), ...
                           'FontSize', 14, 'FontName', 'source code pro', 'Color', [0.3 0.3 0.3]);      
            plot(ax,[1 80], [0 0], 'k-');
            set(ax, 'YLim', [-0.1 1.05], 'XLim', [1 100], 'XTick', [1 2 5 10 20 50 100], 'YTick', -0.2:0.2:1, 'XScale', 'log', 'FontSize', 18);
            grid(ax,'on');
            axis(ax, 'square');
 
            if (row == size(sv2,2))
                xlabel(ax,'spatial frequency (c/deg)');
            else
                set(ax, 'XTickLabel', {});
            end
            if (col == 1)
                ylabel(ax,'MTF');
            else
                set(ax, 'YTickLabel', {});
            end
        

            if (iRGC == nRGCs)
                % All fits together
                ax = subplot('Position', sv2(nRGCs+1).v);
                hLinePlot = plot(ax, sfHR, theFittedSynthesizedOTF, '-', 'LineWidth', 1.5, 'Color', coneColor); hold(ax, 'on');
                hLinePlot.Color(4) = 0.4;
                set(ax, 'YLim', [-0.1 1.05], 'XLim', [1 100], 'XTick', [1 2 5 10 20 50 100], 'YTick', -0.2:0.2:1, 'XScale', 'log', 'FontSize', 18);
                grid(ax,'on');
                axis(ax, 'square');
                xlabel(ax,'spatial frequency (c/deg)');
                set(ax, 'YTickLabel', {});
            end
        end % plotEachCellSeparately
    end
    
    if (~plotEachCellSeparately)
        % All fits together
        ax = subplot('Position', [0.11 0.11 0.85 0.86]);
        hold(ax, 'on');
         
        if (useMeasuredDataInsteadOfSynthesizedData)
            for iRGC = 1:nRGCs
                switch (validRGCsConeTypes(iRGC))
                     case cMosaic.LCONE_ID
                        coneColor = [1 0.1 0.5];
                     case cMosaic.MCONE_ID
                         coneColor = [0.1 1 0.5]*0.8;
                end
                plot(ax, diffractionLimitedOTF.sf, synthesizedRGCOTFs(iRGC,:), 'o-', 'MarkerSize', 12, 'LineWidth', 1.5, ...
                    'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'Color', coneColor*0.5); 
               
            end
        else
           for iRGC = 1:nRGCs
                switch (validRGCsConeTypes(iRGC))
                     case cMosaic.LCONE_ID
                        coneColor = [1 0.1 0.5];
                     case cMosaic.MCONE_ID
                         coneColor = [0.1 1 0.5]*0.8;
                end
                hLinePlot = plot(ax, sfHR, allFittedSynthesizedOTFs(iRGC,:), '-', 'LineWidth', 1.5, 'Color', coneColor); hold(ax, 'on');
                hLinePlot.Color(4) = 0.4;
           end
        end
        
        set(ax, 'YLim', [-0.1 1.05], 'XLim', [1 100], 'XTick', [1 2 5 10 20 50 100], 'YTick', -0.2:0.2:1, 'XScale', 'log', 'FontSize', 18);
        grid(ax,'on');
        box(ax, 'on');
        axis(ax, 'square');
        xlabel(ax,'spatial frequency (c/deg)');
        ylabel(ax, 'MTF');
    end
    
    NicePlot.exportFigToPDF('SynthesizedSFcurves.pdf', hFig, 300);
    
    
    plotExtractedDoGparams(theConeMosaic, DoGmodelParamsLconeRGCs, DoGmodelParamsMconeRGCs)
  
   
    
    if (1==2)
         close all
    hFig = figure(557); clf;
    set(hFig, 'Position', [10 10 2900 1400], 'Color', [1 1 1]);
    for iRGC = 1:nRGCs
        ax = subplot('Position', sv2(iRGC).v);
        [row,col] = ind2sub(size(sv2), iRGC);
        
        noXLabel = true;
        noYLabel = true;
        if (col == size(sv2,1))
            noXLabel = ~true;
        end
        if (row == 1)
            noYLabel = ~true;
        end
        
        activationWeights = reshape(RFsWithinROI(iRGC,:), [1 1 allConesNum]);
        activationRange = 1.2*abs(min(activationWeights(:)))*[-1 1];
        theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [-20 20 -20 20], ...
            'domainVisualizationTicks', struct('x', -20:20:20, 'y', -20:20:20), ...
            'crossHairsOnFovea', true, ...
            'noXLabel', noXLabel, ...
            'noYLabel', noYLabel, ...
            'visualizedConeApertureThetaSamples', 18, ...
            'activation', activationWeights, ...
            'activationRange', activationRange, ...
            'visualizedConeAperture', 'lightCollectingArea6sigma', ...  % lightCollectingAreaCharacteristicDiameter
            'activationColorMap', brewermap(1024, '*RdBu').^0.5, ...
            'backgroundColor', [1 1 1], ...
            'FontSize', 18, ...
            'plotTitle', ' ');
    end
    ax = subplot('Position', sv2(iRGC+1).v);
    theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [-20 20 -20 20], ...
            'domainVisualizationTicks', struct('x', -20:20:20, 'y', -20:20:20), ...
            'visualizedConeApertureThetaSamples', 18, ...
            'crossHairsOnFovea', true, ...
            'visualizedConeAperture', 'lightCollectingArea6sigma', ...  % lightCollectingAreaCharacteristicDiameter
            'backgroundColor', [0 0 0], ...
            'FontSize', 18, ...
            'plotTitle', ' ');
        
    NicePlot.exportFigToPDF('SynthesizedRGCWeights.pdf', hFig, 300);
    end
end
    
    
    
   