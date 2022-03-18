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
    coneMosaicPositionModels = fittedModels(rfCenterConePoolingScenario);

    % This model contains fits to a number of cone positions.
    % Exctract the model at the position which results in the min RMS
    bestConePosIdx = simulator.analyze.bestConePositionAcrossMosaic(...
            coneMosaicPositionModels, STFdataToFit, rmsSelector);
    theBestConePositionModel = coneMosaicPositionModels{bestConePosIdx};

    theBestConePositionModel
    theBestConePositionModel.DoGparams
    theBestConePositionModel.fittedRGCRF

    centerConeIndices = theBestConePositionModel.fittedRGCRF.centerConeIndices;
    centerConeWeights = theBestConePositionModel.fittedRGCRF.centerConeWeights;
    surroundConeIndices = theBestConePositionModel.fittedRGCRF.surroundConeIndices;
    surroundConeWeights = theBestConePositionModel.fittedRGCRF.surroundConeWeights;

    centerConeIndices = centerConeIndices(:);
    centerConeWeights = centerConeWeights(:);
    surroundConeIndices = surroundConeIndices(:);
    surroundConeWeights = surroundConeWeights(:);

    %figure();
    for iSF = 1:numel(spatialFrequenciesExamined)
        for tBin = 1:numel(temporalSupportSeconds)
            cMosaicSpatialActivation = squeeze(coneMosaicSpatiotemporalActivation(iSF,tBin,:));
            centerConeSignals = cMosaicSpatialActivation(centerConeIndices);
            surroundConeSignals = cMosaicSpatialActivation(surroundConeIndices);
            centerActivation = sum(centerConeSignals(:) .* centerConeWeights(:));
            surroundActivation = sum(surroundConeSignals(:) .* surroundConeWeights(:));
            RGCresponse(iSF,tBin) = centerActivation - surroundActivation;
        end 
%         subplot(3,5, iSF)
%         plot(temporalSupportSeconds, RGCresponse(iSF,:), 'k-');
%         title(sprintf('%2.3f c/deg', spatialFrequenciesExamined(iSF)));

    end

    theSynthesizedSTF = max(RGCresponse,[],2);
    hFig = figure()
    subplot(1,3,1)
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])
    subplot(1,3,2)
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    hold on
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])

    theSynthesizedSTF = (theSynthesizedSTF-min(theSynthesizedSTF))/(max(theSynthesizedSTF)-min(theSynthesizedSTF));
    m1 = min(STFdataToFit.responses);
    m2 = max(STFdataToFit.responses);
    STFdataToFit.responses = (STFdataToFit.responses-m1)/(m2-m1);
    theBestConePositionModel.fittedSTF = (theBestConePositionModel.fittedSTF-m1)/(m2-m1);
    subplot(1,3,3);
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-');
    hold on;
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    set(gca, 'XScale', 'log', 'XLim', [4 60], 'YLim', [0 1])

    NicePlot.exportFigToPDF(syntheticSTFdataPDFFilename, hFig, 300);
end

