function dataOut = syntheticRGCSTF(syntheticRGCmodelFilename, coneMosaicResponsesFileName, ...
    syntheticSTFdataPDFFilename, STFdataToFit, rfCenterConePoolingScenario, residualDefocusDiopters, rmsSelector)
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
    
    % Obtain center cone Rc and eccentricity
    bestConeIdx = theBestConePositionModel.fittedRGCRF.centerConeIndices(1);
    centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(bestConeIdx);
    centerConeEccDegs = sqrt(sum((theConeMosaic.coneRFpositionsDegs(bestConeIdx,:)).^2));
    
    % Generate RGC id string
    RGCIDString = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
    
    thePhysiologicalOpticsSTF = computeSTF(coneMosaicSpatiotemporalActivation, theBestConePositionModel,  ...
        temporalSupportSeconds, spatialFrequenciesExamined, ...
        centerConeCharacteristicRadiusDegs, RGCIDString);
    
    dataOut.physiologicalOpticsDoGParams = thePhysiologicalOpticsSTF.DoGparams;
    dataOut.AOSLOOpticsDoGparams = theBestConePositionModel.DoGparams;
    dataOut.weightsSurroundToCenterRatio = thePhysiologicalOpticsSTF.weightsSurroundToCenterRatio;
    dataOut.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;
    dataOut.centerConeEccDegs = centerConeEccDegs;
    
    % Visualize the combo (AOSLO  optics) measured and (Visual optics) syntheticRGC STFs
    measuredSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', STFdataToFit.responses, ...
                    'legend', 'AOSLO optics - measured');
                
    modelMeasuredSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', theBestConePositionModel.fittedSTF, ...
                    'legend', sprintf('AOSLO optics - retinal DoG model (single cone + %2.3fD defocus)', residualDefocusDiopters));
                
    syntheticSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', thePhysiologicalOpticsSTF.computedResponses, ...
                    'legend', 'physiological optics - computed from retinal DoG model + M838 optics');
                
    modelSyntheticSTFdataStruct = struct(...
                    'sf', thePhysiologicalOpticsSTF.DogFitSpatialFrequencySupportHiRes, ...
                    'val', thePhysiologicalOpticsSTF.DoGFitHiRes, ...
                    'legend', 'physiological optics - computed from retinal DoG model + M838 optics');
    
    simulator.visualize.measuredAndSyntheticSTFcombo(...
                measuredSTFdataStruct, modelMeasuredSTFdataStruct, ...
                syntheticSTFdataStruct, modelSyntheticSTFdataStruct, ...
                RGCIDString, ...
                syntheticSTFdataPDFFilename);
end


function d = computeSTF(coneMosaicSpatiotemporalActivation, theRetinalRGCmodel, ...
    temporalSupportSeconds, spatialFrequencySupport, centerConeCharacteristicRadiusDegs, RGCIDString)

    centerConeIndices = theRetinalRGCmodel.fittedRGCRF.centerConeIndices(:);
    centerConeWeights = theRetinalRGCmodel.fittedRGCRF.centerConeWeights(:);
    surroundConeIndices = theRetinalRGCmodel.fittedRGCRF.surroundConeIndices(:);
    surroundConeWeights = theRetinalRGCmodel.fittedRGCRF.surroundConeWeights(:);
    
    % Compute RGC responses
    [RGCresponses, centerResponses, surroundResponses] = ...
        simulator.modelRGC.poolConeMosaicResponses( ...
            coneMosaicSpatiotemporalActivation(:,:,centerConeIndices), ...
            coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices), ...
            centerConeWeights, surroundConeWeights);  
        
    theRGCSTF = zeros(1, size(RGCresponses,1));
    theRGCcenterSTF = theRGCSTF;
    theRGCsurroundSTF = theRGCSTF;
    
    for iSF = 1:size(RGCresponses,1)
        
        % Fit a sinusoid to the temporal response of the RGC
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(RGCresponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []); 
        % The amplitude of the sinusoid is the STF
        theRGCSTF(iSF) = fittedParams(1);
        
        % Fit a sinusoid to the temporal response of the RGC center
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(centerResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);  
        % The amplitude of the sinusoid is the STF
        theRGCcenterSTF(iSF) = fittedParams(1);
        
        % Fit a sinusoid to the temporal response of the RGC surround
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(surroundResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);  
        % The amplitude of the sinusoid is the STF
        theRGCsurroundSTF(iSF) = fittedParams(1);
    end
    
    % Save the computed RGCSTF
    d.computedResponses = theRGCSTF;
    d.weightsSurroundToCenterRatio = sum(surroundConeWeights)/sum(centerConeWeights);
     
    % Fit theRGCSTF with a DoG model
    [d.DoGparams, d.DoGFit, ...
     d.DogFitSpatialFrequencySupportHiRes, ...
     d.DoGFitHiRes, ...
     d.DoGFitCenter, d.DoGFitSurround] = simulator.fit.DoGmodelToSTF(...
        spatialFrequencySupport, theRGCSTF, ...
        centerConeCharacteristicRadiusDegs);
    
    hFig = figure();
    set(hFig, 'Name', RGCIDString, 'Position', [10 10 1200 900]);
    subplot(2, numel(d.DoGparams.names), [1 2]);
    plot(spatialFrequencySupport, theRGCSTF, 'ko-', 'MarkerSize', 12); hold on
    plot(spatialFrequencySupport, theRGCcenterSTF, 'r-', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, theRGCsurroundSTF, 'b-', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFit, 'k--', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFitSurround, 'b--', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFitCenter, 'r--', 'LineWidth', 1.5);
    set(gca, 'XScale', 'linear', 'XLim', [4 60]);
    xlabel('spatial frequency (c/deg)')
    
    subplot(2, numel(d.DoGparams.names), [3 4]);
    plot(spatialFrequencySupport, theRGCSTF, 'ko-', 'MarkerSize', 12); hold on
    plot(spatialFrequencySupport, theRGCcenterSTF, 'r-', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, theRGCsurroundSTF, 'b-', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFit, 'k--', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFitSurround, 'b--', 'LineWidth', 1.5);
    plot(spatialFrequencySupport, d.DoGFitCenter, 'r--', 'LineWidth', 1.5);
    set(gca, 'XScale', 'log', 'XLim', [4 60]);
    xlabel('spatial frequency (c/deg)')
    
    for iParam = 1:numel(d.DoGparams.names)
        subplot(2, numel(d.DoGparams.names), numel(d.DoGparams.names)+iParam);
        hold 'on'
        plot([0 0], [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)], 'k-', 'LineWidth', 1.0);
        plot(0, d.DoGparams.lowerBounds(iParam), 'b^', 'MarkerSize', 16, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.0);
        plot(0, d.DoGparams.upperBounds(iParam), 'rv', 'MarkerSize', 16, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0);
        scatter(0, d.DoGparams.bestFitValues(iParam), 16*16, 'filled', ...
            'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 1 0.5], 'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 2);
        set(gca, 'YScale', d.DoGparams.scale{iParam});
        set(gca, 'XLim', [-1 1], 'YLim', [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)]);
        title(d.DoGparams.names{iParam});
        box on
        set(gca, 'FontSize', 16);
    end
    pause
    
end