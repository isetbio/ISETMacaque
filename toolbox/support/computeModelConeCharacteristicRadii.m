function [measuredCharacteristicRadiiMicrons, actualCharacteristicRadiiMicrons, coneTypes, coneIndices, metaDataOut] = computeModelConeCharacteristicRadii(...
        monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus, ...
        eccCenterMicrons, eccRadiusMicrons, diffractionLimitedOTF, stimulusOTF, deconvolveMeasurementsWithResidualBlur, sfHR, showSineWaveFits)
    
    % Synthesize responses filename
    filename = responsesFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus);
    % Load responses
    load(filename, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'examinedSpatialFrequencies');
    
    % Display some stats
    displayConeMosaicStats(theConeMosaic);
    
    % Select model cones within the region of interest
    foveolaROI = struct(...
        'units', 'microns', ...
        'shape', 'rect', ...
        'center', eccCenterMicrons, ...
        'width',  eccRadiusMicrons*2, ...
        'height', eccRadiusMicrons*2, ...
        'rotation', 0);
    
    foveolaROI = struct(...
        'units', 'microns', ...
        'shape', 'ellipse', ...
        'center', eccCenterMicrons, ...
        'minorAxisDiameter', eccRadiusMicrons*2, ...
        'majorAxisDiameter', eccRadiusMicrons*2, ...
        'rotation', 0);
    
    coneIndices = theConeMosaic.indicesOfConesWithinROI(foveolaROI);
    coneTypes = theConeMosaic.coneTypes(coneIndices);
    selectedConePositions = theConeMosaic.coneRFpositionsMicrons(coneIndices,:);
    
    
    % Compute the test-null response deltas
    backgroundActivations = coneMosaicBackgroundActivation(1,1,coneIndices);
    coneMosaicSpatiotemporalContrastResponseDeltas = bsxfun(@minus, ...
        coneMosaicSpatiotemporalActivation(:,:,coneIndices),  backgroundActivations);

    nSFs = size(coneMosaicSpatiotemporalContrastResponseDeltas,1);
    nTimeBins = size(coneMosaicSpatiotemporalContrastResponseDeltas,2);
    nConesWithinROI = size(coneMosaicSpatiotemporalContrastResponseDeltas,3);
   
    measuredModelConeOTFs = zeros(nConesWithinROI, nSFs);
    intepolatedSinusoidSamplesNum = 100;
    theFittedSineWaveResponses = zeros(nConesWithinROI, nSFs, intepolatedSinusoidSamplesNum);
    timeHR = linspace(temporalSupportSeconds(1), temporalSupportSeconds(end), intepolatedSinusoidSamplesNum);
    integrationTime = theConeMosaic.integrationTime;
     
    rowsNum = 3;
    colsNum = 5;
    sv = NicePlot.getSubPlotPosVectors(...
       'colsNum', colsNum, ...
       'rowsNum', rowsNum, ...
       'heightMargin',  0.08, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.04, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.02);
    sv = sv';
    

    for iCone = 1:nConesWithinROI
        % Retrieve the cone's response time series
        theResponses = squeeze(coneMosaicSpatiotemporalContrastResponseDeltas(:,:,iCone));
        
        if (showSineWaveFits)
            % Setup figure for plotting the cone response time series
            hFig = figure(5000+iCone);
            clf;
            set(hFig, 'Color', [1 1 1],'Position', [10 10 1800 1100], 'Name', sprintf('Sinwave fits to responses of cone %d', iCone));
            color='none';
            switch (coneTypes(iCone))
                case theConeMosaic.LCONE_ID
                    color = theConeMosaic.lConeColor;
                case theConeMosaic.MCONE_ID
                    color = theConeMosaic.mConeColor;
                case theConeMosaic.SCONE_ID
                    color = theConeMosaic.sConeColor;
            end      
        end
            
        for iSF = 1:nSFs
            % Retrieve the time series response for this spatial frequency
            theResponseTimeSeries = theResponses(iSF,:);
            
            % Fit the response deltas
            [theFittedResponse, fittedParams] = fitSinusoidToResponseTimeSeries(...
                temporalSupportSeconds, theResponseTimeSeries, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, timeHR);
            
            % Add back the background activation
            theFittedSineWaveResponses(iCone,iSF,:) = theFittedResponse + backgroundActivations(iCone);
            
            % Transform sinusoid amplitude into  contrast, so as to estimate the cone's
            % OTF (contrast attenuration with SF)
            measuredModelConeOTFs(iCone,iSF) = fittedParams(1) / backgroundActivations(iCone);
            
            if (showSineWaveFits)
                ax = subplot('Position', sv(iSF).v);
                % The fitted response data
                plot(ax,timeHR*1000, ...
                    1e-3*(theFittedResponse+backgroundActivations(iCone))*integrationTime, ...
                    '-', 'Color', color * 0.5, 'LineWidth', 1.5); hold(ax, 'on');
                
                % The response data
                scatter(ax,temporalSupportSeconds*1000, ...
                    1e-3*(theResponseTimeSeries+backgroundActivations(iCone))*integrationTime, ...
                    100, 'filled', 'o', ...
                    'LineWidth', 1.5, 'MarkerEdgeColor', color*0.5, 'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.5); 

                yTicks = 1e-3*backgroundActivations(iCone)*integrationTime*[0:0.5:2];
                set(ax, 'XLim', [temporalSupportSeconds(1) temporalSupportSeconds(end)]*1000, ...
                    'YLim', 1e-3*[-0.05 2.05]*backgroundActivations(iCone)*integrationTime, ...
                    'YTick', yTicks, 'YTickLabel', sprintf('%2.1fk\n', yTicks), ...
                    'XTick', 0:100:1000, 'FontSize', 14);
                grid on
                xlabel(ax,'time (msec)');
                if (iSF == 1)
                    ylabel(ax, 'mean cone excitations / sec');
                end
                title(ax,sprintf('SF = %2.1f cpd (modulation: %2.2f%%)',examinedSpatialFrequencies(iSF), measuredModelConeOTFs(iCone,iSF)*100));
            end
        end
        if (showSineWaveFits)
            pause
        end
    end
    
    
    
    
    
    if (opticalDefocusDiopters ~= 0) && deconvolveMeasurementsWithResidualBlur
        load(customDefocusOTFFilename(opticalDefocusDiopters), ...
                'OTF_ResidualDefocus', 'sfsExamimed');
        % The modelConeOTFs contain the effect of residual blur
        % Deconvolve with the diffraction-limited OTF so we can fit with a
        % Gaussian to extract the characteristic radius.
        % The modelConeOTFs also are blurred by the stimulusOTF. Deconvolve
        % that too.
        totalBlur = OTF_ResidualDefocus .* stimulusOTF;
        totalBlurOTFHR = interp1(examinedSpatialFrequencies, totalBlur, sfHR);
        retinalConeOTFs = bsxfun(@times, measuredModelConeOTFs, 1./totalBlur);
    else
        % The modelConeOTFs contain the effect of diffraction limited optics.
        % Deconvolve with the diffraction-limited OTF so we can fit with a
        % Gaussian to extract the characteristic radius.
        % The modelConeOTFs also are blurred by the stimulusOTF. Deconvolve
        % that too.
        totalBlur = diffractionLimitedOTF.otf .* stimulusOTF;
        totalBlurOTFHR = interp1(examinedSpatialFrequencies, totalBlur, sfHR);
        retinalConeOTFs = bsxfun(@times, measuredModelConeOTFs, 1./totalBlur);
    end
    

    theFittedRetinalConeOTFHR = zeros(nConesWithinROI, numel(sfHR));
    measuredCharacteristicRadiiMicrons = zeros(nConesWithinROI,1);
    actualCharacteristicRadiiMicrons = zeros(nConesWithinROI,1);
    
    plotConeOTFfits = ~true;
    
    for iCone = 1:nConesWithinROI
        fprintf('Fitting cone %d/%d OTF\n', iCone, nConesWithinROI);
        % Fit a Gaussian function to this cone's OTF, taking into account the diffraction-limited OTF
        [theFittedRetinalConeOTFHR(iCone,:), fittedParamsOTF] = ...
            fitGaussianToOTF(diffractionLimitedOTF.sf, squeeze(retinalConeOTFs(iCone,:)), sfHR, 1, 1);
        measuredCharacteristicRadiiMicrons(iCone) = fittedParamsOTF(2) * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;

        actualConeIndex = coneIndices(iCone);
        apertureBlurSigmaMicrons = theConeMosaic.apertureBlurSigmaMicronsOfConeFromItsBlurZone(actualConeIndex);
        actualCharacteristicRadiiMicrons(iCone) = apertureBlurSigmaMicrons*sqrt(2.0);
    
        if (plotConeOTFfits)
            hFig = figure(44);
            if (iCone == 1) 
                clf;
                set(hFig, 'Position', [100 800 1500 400], 'Color', [1 1 1]);
            end
            ax = subplot(1,3,1);
            color = 'none';
            switch (coneTypes(iCone))
                case theConeMosaic.LCONE_ID
                    color = theConeMosaic.lConeColor;
                case theConeMosaic.MCONE_ID
                    color = theConeMosaic.mConeColor;
                case theConeMosaic.SCONE_ID
                    color = theConeMosaic.sConeColor;
            end 
            
            plot(ax,sfHR, theFittedRetinalConeOTFHR(iCone,:), 'k-', 'Color', color*0.6, 'LineWidth', 1.5); hold(ax, 'on')
            plot(ax,diffractionLimitedOTF.sf, squeeze(retinalConeOTFs(iCone,:)), 'ks', 'MarkerFaceColor', color); 
            % plot(ax,diffractionLimitedOTF.sf, totalBlur, 'r--');
            hold(ax, 'off');
            set(ax, 'FontSize', 16, 'YLim', [0 1], 'YTick', 0:0.1:1);
            grid(ax, 'on');
            title(ax,sprintf('apertureRc = %2.2f, measuredRc = %2.2f', actualCharacteristicRadiiMicrons(iCone), measuredCharacteristicRadiiMicrons(iCone)));
            
            
            ax = subplot(1,3,2);
            theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
                'labelConesWithIndices', coneIndices(iCone), ...
                'domainVisualizationLimits', 0.2*[-1 1 -1 1], ...
                'backgroundColor', [0 0 0], ...
                'plotTitle', sprintf('cone %d', iCone));
                
            ax = subplot(1,3,3);
            scatter(ax, actualCharacteristicRadiiMicrons(iCone), measuredCharacteristicRadiiMicrons(iCone), 144, ...
                'o', 'filled', 'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
            hold(ax, 'on');
            xlabel(ax,'aperture Rc');
            ylabel(ax,'measured Rc');
            plot(ax,[0.5 1], [0.5 1], 'k-');
            axis(ax, 'square');
            set(ax, 'XLim', [0.3 1], 'YLim', [0.3 1], 'XTick', 0:0.1:1, 'YTick', 0:0.1:1, 'FontSize', 16);
            grid(ax, 'on')
            set(ax, 'FontSize', 16);
            drawnow
        end
    end

    
    % Add the total blur back in
    theFittedModelConeOTFHR = bsxfun(@times, theFittedRetinalConeOTFHR, totalBlurOTFHR);
    
    contrastMeasuredAndTheoreticalSigma = true;
    if (contrastMeasuredAndTheoreticalSigma)
        figure(23); clf
        hold on;
        
        for iCone = 1:numel(coneTypes)
            color = 'none';
            switch (coneTypes(iCone))
                case theConeMosaic.LCONE_ID
                    color = theConeMosaic.lConeColor;
                case theConeMosaic.MCONE_ID
                    color = theConeMosaic.mConeColor;
                case theConeMosaic.SCONE_ID
                    color = theConeMosaic.sConeColor;
            end
            
            scatter(actualCharacteristicRadiiMicrons(iCone), measuredCharacteristicRadiiMicrons(iCone), 144, ...
            'o', 'filled', 'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
        end
    
        xlabel('aperture Rc');
        ylabel('measured Rc');
        plot([0.5 1], [0.5 1], 'k-');
        axis 'square';
        set(gca, 'XLim', [0.3 1], 'YLim', [0.3 1], 'XTick', 0:0.1:1, 'YTick', 0:0.1:1, 'FontSize', 16);
        title(sprintf('actual vs measured cone Rc for %d cones within the ROI\n', numel(actualCharacteristicRadiiMicrons)));
        grid on
    end
    
    
    metaDataOut = struct(...
        'measuredModelConeOTFs', measuredModelConeOTFs, ...
        'theFittedModelConeOTFHR', theFittedModelConeOTFHR, ...
        'sfHR', sfHR, ...
        'theFittedSineWaveResponses', theFittedSineWaveResponses, ...
        'timeHR', timeHR);
end

