function syntheticRGCSTF(syntheticRGCmodelFilename, coneMosaicResponsesFileName, ...
    syntheticSTFdataPDFFilename, STFdataToFit, rfCenterConePoolingScenario, rmsSelector)
% Compute synthetic RGC responses to stimuli of different SFs
%
% Syntax:
%   simulator.compute.syntheticRGCSTF(synthesizedRGCCellIDs, coneMosaicResponsesFileName)
%
% Description:
%   Compute synthetic RGC responses to stimuli of different SFs
%
% Inputs:
%    synthesizedRGCCellIDs
%    coneMosaicResponsesFileName
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         
    
    coneMosaicResponsesFileName
    syntheticRGCmodelFilename

    % Load the computed cone mosaic responses for the STF stimulus
    load(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined');

   
    % Convert cone excitation responses to cone modulations
    b = coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, coneMosaicSpatiotemporalActivation, b), 1./b);


    % Load the RGC model to employ
    load(syntheticRGCmodelFilename, 'fittedModels');
    rfCenterConePoolingScenario
    pause
    coneMosaicPositionModels = fittedModels(rfCenterConePoolingScenario);

    % This model contains fits to a number of cone positions.
    % Exctract the model at the position which results in the min RMS
    bestConePosIdx = simulator.analyze.bestConePositionAcrossMosaic(...
            coneMosaicPositionModels, STFdataToFit, rmsSelector);

    hFig = figure(1); clf;
    for bestConePosIdx = 1:numel(coneMosaicPositionModels)
    theBestConePositionModel = coneMosaicPositionModels{bestConePosIdx};

    theBestConePositionModel
    theBestConePositionModel.DoGparams
    theBestConePositionModel.fittedRGCRF

    centerConeIndices = theBestConePositionModel.fittedRGCRF.centerConeIndices;
    centerConeWeights = theBestConePositionModel.fittedRGCRF.centerConeWeights;
    surroundConeIndices = theBestConePositionModel.fittedRGCRF.surroundConeIndices;
    surroundConeWeights = theBestConePositionModel.fittedRGCRF.surroundConeWeights;

    integratedSensSurroundToCenter = theBestConePositionModel.DoGparams.bestFitValues(2) * (theBestConePositionModel.DoGparams.bestFitValues(3))^2
    weightsSurroundToCenter = sum(surroundConeWeights)/sum(centerConeWeights)
    
    
    centerConeIndices = centerConeIndices(:);
    centerConeWeights = centerConeWeights(:);
    surroundConeIndices = surroundConeIndices(:);
    surroundConeWeights = surroundConeWeights(:);

  %  figure();
    for iSF = 1:numel(spatialFrequenciesExamined)
        for tBin = 1:numel(temporalSupportSeconds)
            cMosaicSpatialActivation = squeeze(coneMosaicSpatiotemporalActivation(iSF,tBin,:));
            centerConeSignals = cMosaicSpatialActivation(centerConeIndices);
            surroundConeSignals = cMosaicSpatialActivation(surroundConeIndices);
            centerResponse(tBin) = sum(centerConeSignals(:) .* centerConeWeights(:));
            surroundResponse(tBin) = sum(surroundConeSignals(:) .* surroundConeWeights(:));
        end 
        RGCresponse = centerResponse - surroundResponse;
        
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                RGCresponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        theSynthesizedSTF(iSF) = fittedParams(1);

        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                centerResponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        
        theCenterSTF(iSF) = fittedParams(1);

        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                surroundResponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        theSurroundSTF(iSF) = fittedParams(1);
        
%          subplot(3,5, iSF)
%          plot(temporalSupportSeconds, RGCresponse, 'k-');
%          set(gca, 'YLim', [-0.2 0.2])
%          title(sprintf('%2.3f c/deg', spatialFrequenciesExamined(iSF)));

    end

    
    subplot(7,3,(bestConePosIdx-1)*3+1)
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-');
    hold on;
    plot(spatialFrequenciesExamined, theCenterSTF, 'r.-');
    plot(spatialFrequenciesExamined, theSurroundSTF, 'b.-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])

    subplot(7,3,(bestConePosIdx-1)*3+2)
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    hold on
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])

    
    subplot(7,3,(bestConePosIdx-1)*3+3);
    yyaxis('left')
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-');
    yyaxis('right')
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    hold on
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    set(gca, 'XScale', 'log', 'XLim', [4 60], 'YLim', [0 1])

    pause

    end

    NicePlot.exportFigToPDF(syntheticSTFdataPDFFilename, hFig, 300);
end

