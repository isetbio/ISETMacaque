function fitConeMosaicResponses(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, ...
    eccCenterMicrons, eccRadiusMicrons, PolansSubject, visualStimulus, lowerBoundForRsToRcInFreeRcFits, ...
    sessionData, deconvolveMeasurementsWithResidualBlur)
    
    % Synthesize responses filename
    filename = responsesFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus);
    % Load the coneMosaic
    load(filename, 'theConeMosaic');
    
    options.showIndividualRGCFits = true;
    options.showSineWaveFits = true;
    options.showConeOTFFits = true;
 
    
    % Load measured RGC spatial frequency curves. Note: these responses have
    % already been de-convolved with the diffraction-limited OTF
    [dFresponsesLcenterRGCs, ...
     dFresponsesMcenterRGCs, ...
     dFresponsesScenterRGCs, ...
     dFresponseStdLcenterRGCs, ...
     dFresponseStdMcenterRGCs, ...
     dFresponseStdScenterRGCs, ...
     diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData);

    
    
    if (opticalDefocusDiopters ~= 0) && deconvolveMeasurementsWithResidualBlur
        load(customDefocusOTFFilename(opticalDefocusDiopters), ...
                'OTF_ResidualDefocus', 'sfsExamimed');

        fprintf(2, 'Deconvolving with the OTF with %2.3fD residual blur OTF\n', opticalDefocusDiopters);
        % These responses have been deconvolved with the diffraction-limited OTF
        % So put this back on;
        
        % Cell IDs to deconvolve with residual blur OTF
        LconeRGCIDsToDecolvolveWithResidualBlurOTF = 1:size(dFresponsesLcenterRGCs,1) % [3 4 6 10 11];
        MconeRGCIDsToDecolvolveWithResidualBlurOTF = 1:size(dFresponsesMcenterRGCs,1) % [1 2 4];

        % Correct L-cone RGC responses
        % Put diffraction-limited OTF back in
        tmp = bsxfun(@times, dFresponsesLcenterRGCs(LconeRGCIDsToDecolvolveWithResidualBlurOTF ,:), diffractionLimitedOTF.otf);
        % Deconvolve with residual defocus OTF
        tmp = bsxfun(@times, tmp, 1./OTF_ResidualDefocus);
        % Replace original measurements
        for k = 1:numel(LconeRGCIDsToDecolvolveWithResidualBlurOTF )
            kk = LconeRGCIDsToDecolvolveWithResidualBlurOTF (k);
            ampBefore = max(max(dFresponsesLcenterRGCs(kk,:)));
            ampAfter = max(max(tmp(k,:)));
            tmp(k,:) = tmp(k,:) * ampBefore/ampAfter;
        end
        dFresponsesLcenterRGCs(LconeRGCIDsToDecolvolveWithResidualBlurOTF ,:) = tmp;
        

        % Correct M-cone RGC responses
        % Put diffraction-limited OTF back in
        tmp = bsxfun(@times, dFresponsesMcenterRGCs(MconeRGCIDsToDecolvolveWithResidualBlurOTF,:), diffractionLimitedOTF.otf);
        % Deconvolve with residual defocus OTF
        tmp = bsxfun(@times, tmp, 1./OTF_ResidualDefocus);
        for k = 1:numel(MconeRGCIDsToDecolvolveWithResidualBlurOTF)
            kk = MconeRGCIDsToDecolvolveWithResidualBlurOTF(k);
            ampBefore = max(max(dFresponsesMcenterRGCs(kk,:)));
            ampAfter = max(max(tmp(k,:)));
            tmp(k,:) = tmp(k,:) * ampBefore/ampAfter;
        end
        
        % Replace original measurements
        dFresponsesMcenterRGCs(MconeRGCIDsToDecolvolveWithResidualBlurOTF,:) = tmp;
        
        fprintf(2,'L- and M-cone RGC responses have been deconvolved with residual blur OTF (%2.3f Diopters)\n', opticalDefocusDiopters);
    end % if (opticalDefocusDiopters ~= 0) && deconvolveMeasurementsWithResidualBlur
    
    
    % High-res spatial frequency support
    interpolatedSFsNum = 200;
    sfHR = linspace(diffractionLimitedOTF.sf(1), diffractionLimitedOTF.sf(end), interpolatedSFsNum);
    
    % Compute stimulus OTF
    stimulusOTF = computeStimulusOTF(diffractionLimitedOTF.sf);
    stimulusOTFHR = interp1(diffractionLimitedOTF.sf, stimulusOTF, sfHR);
    
    % Compute characteristic radii of model cones within the ROI
    [modelConeMeasuredCharacteristicRadiiMicrons, ...
     modelConeActualApertureCharacteristicRadiiMicrons, ...
     coneTypes, indicesOfConesWithinROI, modelConeFitMetaData] = computeModelConeCharacteristicRadii(...
        monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus, ...
        eccCenterMicrons, eccRadiusMicrons,  ...
        diffractionLimitedOTF, stimulusOTF, deconvolveMeasurementsWithResidualBlur, sfHR, options.showSineWaveFits);
    
    
    % Fit L-cone RGCs
    modelLconeIndices = find(coneTypes == cMosaic.LCONE_ID);
    coneString = 'L-cone';
    coneColor = theConeMosaic.lConeColor;
    theVideoFileName = videoFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, ...
            PolansSubject, visualStimulus, sprintf('%sRGCfits', coneString));
      

    plotModelledFits = true;
    [theFreeRcFittedLconeRGCRetinalDoGParams, theFixedRcFittedLconeRGCRetinalDoGParams] = fitRGCOTFs(...
        dFresponsesLcenterRGCs, dFresponseStdLcenterRGCs, modelLconeIndices, modelConeMeasuredCharacteristicRadiiMicrons, ...
        lowerBoundForRsToRcInFreeRcFits, ...
        diffractionLimitedOTF.sf, stimulusOTF, sfHR, stimulusOTFHR, modelConeFitMetaData, ...
        coneString, coneColor, plotModelledFits, theVideoFileName);
    

    % Fit M-cone RGCs
    modelMconeIndices = find(coneTypes == cMosaic.MCONE_ID);
    coneString = 'M-cone';
    coneColor = theConeMosaic.mConeColor;
    theVideoFileName = videoFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, ...
            PolansSubject, visualStimulus, sprintf('%sRGCfits', coneString));
    plotModelledFits = true;
    [theFreeRcFittedMconeRGCRetinalDoGParams, theFixedRcFittedMconeRGCRetinalDoGParams] = fitRGCOTFs(...
        dFresponsesMcenterRGCs, dFresponseStdMcenterRGCs, modelMconeIndices, modelConeMeasuredCharacteristicRadiiMicrons, ...
        lowerBoundForRsToRcInFreeRcFits, ...
        diffractionLimitedOTF.sf, stimulusOTF, sfHR, stimulusOTFHR, modelConeFitMetaData, ...
        coneString, coneColor, plotModelledFits, theVideoFileName);
    
    % Show correspondences
    plotRcsFixedVsFreeFits(theFreeRcFittedLconeRGCRetinalDoGParams, theFreeRcFittedMconeRGCRetinalDoGParams, ...
        modelConeMeasuredCharacteristicRadiiMicrons, modelLconeIndices, modelMconeIndices, indicesOfConesWithinROI, ...
        eccCenterMicrons, theConeMosaic);
end

function plotRcsFixedVsFreeFits(theFreeRcFittedLconeRGCRetinalDoGParams, theFreeRcFittedMconeRGCRetinalDoGParams, ...
    modelConeMeasuredCharacteristicRadiiMicrons, modelLconeIndices, modelMconeIndices, indicesOfConesWithinROI, ...
    eccCenterMicrons, theConeMosaic)

    hFig = figure(5000); 
    clf;
    set(hFig, 'Position', [10 10 1150 700], 'Color', [1 1 1]);
    
    rowsNum = 1;
    colsNum = 2;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.07, ...
           'leftMargin',     0.07, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.10, ...
           'topMargin',      0.01);
       
    ax = subplot('Position', sv(1,1).v);
    theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
         'domain', 'microns', ...
         'domainVisualizationLimits', 75*[-1 1 -1 1], ...
         'domainVisualizationTicks', struct('x', -120:20:120, 'y', -120:20:120), ...
         'visualizedConeAperture', 'geometricArea', ...
         'visualizedConeApertureThetaSamples', 30, ...
         'labelConesWithIndices', indicesOfConesWithinROI, ...
         'fontSize', 20, ...
         'backgroundColor', [0 0 0], 'plotTitle', ' ');
    
    ax = subplot('Position', sv(1,2).v);
    plot(ax, [0 5], [0 5], 'k-', 'LineWidth', 1.5); 
    hold(ax, 'on');
    
    RGCsNum = size(theFreeRcFittedLconeRGCRetinalDoGParams,1);
    coneColor = theConeMosaic.lConeColor;
    for iRGC = 1:RGCsNum
        theRcsFromISETBioModelCones = modelConeMeasuredCharacteristicRadiiMicrons(modelLconeIndices);
        theRcsFromFreeDoGfitsToDeltaFresponses = squeeze(theFreeRcFittedLconeRGCRetinalDoGParams(iRGC, :,2)) * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        scatter(ax, theRcsFromISETBioModelCones, theRcsFromFreeDoGfitsToDeltaFresponses, ...
            141, 'filled', 'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'MarkerFaceAlpha', 0.5);
    end
    
    RGCsNum = size(theFreeRcFittedMconeRGCRetinalDoGParams,1);
    coneColor = theConeMosaic.mConeColor;
    for iRGC = 1:RGCsNum
        theRcsFromISETBioModelCones = modelConeMeasuredCharacteristicRadiiMicrons(modelMconeIndices);
        theRcsFromFreeDoGfitsToDeltaFresponses = squeeze(theFreeRcFittedMconeRGCRetinalDoGParams(iRGC, :,2)) * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        scatter(ax, theRcsFromISETBioModelCones, theRcsFromFreeDoGfitsToDeltaFresponses, ...
            141, 'filled', 'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'MarkerFaceAlpha', 0.5);
    end
    
    hold(ax, 'off');
    axis(ax, 'square');
    set(ax, 'XLim', [0.5 3], 'YLim', [0.5 3], 'XTick', 0.5:0.5:5, 'YTick', 0.5:0.5:5, 'FontSize', 20);
    grid(ax, 'on');
    
    xlabel(ax,sprintf('Rc (microns) - %d ISETBio cones @ (%d, %d) um',numel(indicesOfConesWithinROI), eccCenterMicrons(1), eccCenterMicrons(2)));
    ylabel(ax,        'Rc (microns) - DoG fits to \DeltaF/Fo responses');
    NicePlot.exportFigToPDF('RcAnalysisWithinROI.pdf', hFig, 300);

end


function [theFreeRcFittedRGCRetinalDoGParams, theFixedRcFittedRGCRetinalDoGParams] = fitRGCOTFs(...
            dFresponses, dFresponsesStd, modelConeIndices, modelConeMeasuredCharacteristicRadiiMicrons, ...
            lowerBoundForRsToRcInFreeRcFits, ...
            examinedSpatialFrequencies, stimulusOTF, sfHR, stimulusOTFHR, modelConeFitMetaData, ...
            coneString, coneColor, plotModelledFits, theVideoFileName)

    % Preallocate memory
    RGCsNum = size(dFresponses,1);
    theFixedRcFittedModeledRGCOTFs = zeros(RGCsNum,numel(modelConeIndices),numel(sfHR));
    theFreeRcFittedModeledRGCOTFs = zeros(RGCsNum,numel(modelConeIndices),numel(sfHR));
    
    % Essentially, no lower bound for fixedRC fits
    lowerBoundForRsToRc = 0.1;
    
    % Fit each of measured  RGC response by fixing Rc to that of
    % all model cones within the examined ROI
    for iRGC = 1:RGCsNum
        fprintf('Fitting %s RGC #%d with data from %d %s within the selected ROI.\n', coneString, iRGC, numel(modelConeIndices), coneString);
        
        % Load the diffraction-limited deconvolved data
        theMeasuredRGCOTF = dFresponses(iRGC,:);
        if (~isempty(dFresponsesStd))
            theMeasuredRGCOTFStd = dFresponsesStd(iRGC,:);
            multiStartSolver = 'fmincon';
        else
            theMeasuredRGCOTFStd = [];
            multiStartSolver = 'lsqcurvefit';
        end
        
        % Deconvolve the stimulus OTF
        theMeasuredRGCOTF = theMeasuredRGCOTF ./ stimulusOTF;
         
        
        % Go through all cones of the same type as the RGC that lie within the ROI
        for iCone = 1:numel(modelConeIndices)
            
            theConeIndex = modelConeIndices(iCone);
            
            % set the fixedRc to that of the iCone aperture
            % theFixedRcMicrons(iCone) = modelConeActualApertureCharacteristicRadiiMicrons(theConeIndex);
            
            % set the fixedRc to that measured by fitting the model cone OTF 
            theFixedRcMicrons(iCone) = modelConeMeasuredCharacteristicRadiiMicrons(theConeIndex);
            
            % Compute Rc in microns
            theFixedRcDegs(iCone) = theFixedRcMicrons(iCone) / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
            
            % --- Fit with the DoG model (with fixed Rc) ---
            [theFittedRGCOTFHR, fixedRcFitDoGParams, theFixedRcRMSError(iRGC, iCone)] = ...
                fitDogModelToOTF(...
                    examinedSpatialFrequencies, theMeasuredRGCOTF, theMeasuredRGCOTFStd, ...
                    theFixedRcDegs(iCone), sfHR, ...
                    lowerBoundForRsToRc, ...
                    multiStartSolver);
            
            % Save the DoG params
            theFixedRcFittedRGCRetinalDoGParams(iRGC,iCone,:) = fixedRcFitDoGParams;
            
            % Add back the stimulusOTF
            theFixedRcFittedModeledRGCOTFs(iRGC, iCone,:) = theFittedRGCOTFHR .* stimulusOTFHR;
            
            
 
            % ---- Fit with the DoG model (with free Rc) --- 
            [theFittedRGCOTFHR, freeRcFitDoGParams, freeRcRMSError] = ...
                    fitDogModelToOTF(...
                        examinedSpatialFrequencies, theMeasuredRGCOTF, theMeasuredRGCOTFStd, ...
                        [], sfHR, ...
                        lowerBoundForRsToRcInFreeRcFits, ...
                        multiStartSolver);
 
                
            % Save the DoG params
            theFreeRcFittedRGCRetinalDoGParams(iRGC,iCone,:) = freeRcFitDoGParams;
            theFreeRcRMSError(iRGC, iCone) = freeRcRMSError;
            
            % The freeRc in microns
            theFreeRcMicrons(iRGC,iCone) = freeRcFitDoGParams(2) * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
            
            % Add back the stimulusOTF
            theFreeRcFittedModeledRGCOTFs(iRGC, iCone,:) = theFittedRGCOTFHR .* stimulusOTFHR;
        end
    end
      
    
    if (plotModelledFits)
        plotModelledRGCFits(theFixedRcFittedModeledRGCOTFs, theFreeRcFittedModeledRGCOTFs, dFresponses, dFresponsesStd, ...
            modelConeFitMetaData.theFittedModelConeOTFHR(modelConeIndices,:), ...
            modelConeFitMetaData.measuredModelConeOTFs(modelConeIndices,:), ...
            theFixedRcMicrons, ...
            theFixedRcFittedRGCRetinalDoGParams,...
            theFreeRcFittedRGCRetinalDoGParams, ...
            theFixedRcRMSError, theFreeRcRMSError, ...
            lowerBoundForRsToRcInFreeRcFits, ...
            lowerBoundForRsToRc, ...
            examinedSpatialFrequencies, sfHR, ...
            coneString, coneColor, theVideoFileName);
    end
    
    
    
end


