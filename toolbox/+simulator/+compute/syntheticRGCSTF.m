function dataOut = syntheticRGCSTF(syntheticRGCmodelFilename, coneMosaicResponsesFileName, ...
    syntheticSTFdataPDFFilename, ...
    syntheticSTFtoFit, syntheticSTFtoFitComponentWeights, ...
    STFdataToFit, ...
    rfCenterConePoolingScenario, residualDefocusDiopters, rmsSelector)
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
        centerConeCharacteristicRadiusDegs, RGCIDString, ...
        syntheticSTFtoFit, syntheticSTFtoFitComponentWeights);
    
    % Visualize the combo (AOSLO  optics) measured and (Visual optics) syntheticRGC STFs
    measuredSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', STFdataToFit.responses, ...
                    'legend', 'AOSLO optics - measured');
                
    modelMeasuredSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', theBestConePositionModel.fittedSTF, ...
                    'valCenterSTF', [], ...%theBestConePositionModel.fittedSTFcenter, ...
                    'valSurroundSTF', [], ...%theBestConePositionModel.fittedSTFsurround, ...
                    'legend', sprintf('AOSLO optics - retinal DoG model (single cone + %2.3fD defocus)', residualDefocusDiopters));
                
    syntheticSTFdataStruct = struct(...
                    'sf', spatialFrequenciesExamined, ...
                    'val', thePhysiologicalOpticsSTF.computedResponses, ...
                    'valCenterSTF', thePhysiologicalOpticsSTF.computedCenterResponses, ...
                    'valSurroundSTF', thePhysiologicalOpticsSTF.computedSurroundResponses, ...
                    'legend', 'physiological optics - computed from retinal DoG model + M838 optics');
                
    modelSyntheticSTFdataStruct = struct(...
                    'sf', thePhysiologicalOpticsSTF.DogFitSpatialFrequencySupportHiRes, ...
                    'val', thePhysiologicalOpticsSTF.DoGFitHiRes, ...
                    'valCenterSTF', thePhysiologicalOpticsSTF.DoGFitCenterHiRes, ...
                    'valSurroundSTF', thePhysiologicalOpticsSTF.DoGFitSurroundHiRes, ...
                    'legend', 'physiological optics - computed from retinal DoG model + M838 optics');
    
    dataOut.syntheticSTFdataStruct = syntheticSTFdataStruct;
    dataOut.modelSyntheticSTFdataStruct = modelSyntheticSTFdataStruct;
    dataOut.physiologicalOpticsDoGParams = thePhysiologicalOpticsSTF.DoGparams;
    dataOut.AOSLOOpticsDoGparams = theBestConePositionModel.DoGparams;
    dataOut.weightsSurroundToCenterRatio = thePhysiologicalOpticsSTF.weightsSurroundToCenterRatio;
    dataOut.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;
    dataOut.centerConeEccDegs = centerConeEccDegs;

    simulator.visualize.measuredAndSyntheticSTFcombo(...
                measuredSTFdataStruct, modelMeasuredSTFdataStruct, ...
                syntheticSTFdataStruct, modelSyntheticSTFdataStruct, ...
                RGCIDString, ...
                syntheticSTFdataPDFFilename);
end


function d = computeSTF(coneMosaicSpatiotemporalActivation, theRetinalRGCmodel, ...
    temporalSupportSeconds, spatialFrequencySupport, centerConeCharacteristicRadiusDegs, ...
    RGCIDString, syntheticSTFtoFit, syntheticSTFtoFitComponentWeights)

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
        
    temporalSupportSecondsHR = linspace(temporalSupportSeconds(1), temporalSupportSeconds(end),100);
    
    theRGCSTF = zeros(1, size(RGCresponses,1));
    theRGCcenterSTF = theRGCSTF;
    theRGCsurroundSTF = theRGCSTF;
    
    for iSF = 1:size(RGCresponses,1)
        
        % Fit a sinusoid to the temporal response of the RGC
        [theFittedResponse, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(RGCresponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                temporalSupportSecondsHR); 
        % The amplitude of the sinusoid is the STF
        theRGCSTF(iSF) = fittedParams(1);
        
        % Fit a sinusoid to the temporal response of the RGC center
        [theFittedResponse, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(centerResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                temporalSupportSecondsHR);  
        % The amplitude of the sinusoid is the STF
        theRGCcenterSTF(iSF) = fittedParams(1);     
        
        % Fit a sinusoid to the temporal response of the RGC surround
        [theFittedResponse, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(surroundResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                temporalSupportSecondsHR);  
        % The amplitude of the sinusoid is the STF
        theRGCsurroundSTF(iSF) = fittedParams(1);
    end
    
    % Save the computed RGCSTF
    d.computedResponses = theRGCSTF;
    d.computedCenterResponses = theRGCcenterSTF;
    d.computedSurroundResponses = theRGCsurroundSTF;

    d.weightsSurroundToCenterRatio = sum(surroundConeWeights)/sum(centerConeWeights);
    
    validSyntheticSTFsToFit = {...
        'compositeCenterSurroundResponseBased', ...
        'weightedComponentCenterSurroundResponseBased'};
    assert(ismember(syntheticSTFtoFit, validSyntheticSTFsToFit), ...
        sprintf('Invalid ''syntheticSTFtoFit'' option. Must be either ''%s'' or ''%s''.', ...
                validSyntheticSTFsToFit{1}, validSyntheticSTFsToFit{2}));
    

    maxSFToFit = 50;
    idx = find(spatialFrequencySupport<=maxSFToFit);
    
    if (strcmp(syntheticSTFtoFit,'compositeCenterSurroundResponseBased'))
        % Fit the composite center/surround STF (theRGCSTF) with a DoG model
        [d.DoGparams, d.DoGFit, ...
         d.DogFitSpatialFrequencySupportHiRes, ...
         d.DoGFitHiRes, ...
         d.DoGFitCenter, d.DoGFitSurround, ...
         d.DoGFitCenterHiRes, d.DoGFitSurroundHiRes] = simulator.fit.DoGmodelToCompositeSTF(...
            spatialFrequencySupport(idx), theRGCSTF(idx), ...
            centerConeCharacteristicRadiusDegs);
    else
     
        % Fit separately the center and surround STFS
        [d.DoGparams, d.DoGFit, ...
         d.DogFitSpatialFrequencySupportHiRes, ...
         d.DoGFitHiRes, ...
         d.DoGFitCenter, d.DoGFitSurround, ...
         theFittedCompositeSTFHiResFullField, ...
         theFittedSTFcenterFullField, theFittedSTFsurroundFullField] = simulator.fit.DoGmodelToComponentsSTF(...
            spatialFrequencySupport(idx), ...
            theRGCcenterSTF(idx), theRGCsurroundSTF(idx), theRGCSTF(idx), ...
            centerConeCharacteristicRadiusDegs, ...
            syntheticSTFtoFitComponentWeights.center, ...
            syntheticSTFtoFitComponentWeights.surround, ...
            syntheticSTFtoFitComponentWeights.composite);
    end
    
    retinalDoGmodelSurroundCenterSensitivyRatio = d.DoGparams.bestFitValues (2) * d.DoGparams.bestFitValues (3)^2
    conePoolingWeightsSurroundCenterRatio = sum(surroundConeWeights)/sum(centerConeWeights)

     
    if (strcmp(syntheticSTFtoFit,'weightedComponentCenterSurroundResponseBased'))
        % Visualize center/surround and compositeSTF and fits to them
        hFig = figure(222); clf;
        set(hFig, 'Color', [1 1 1], 'Name', RGCIDString, 'Position', [10 10 1700 650]);
        subplot('Position', [0.04 0.08 0.3 0.85]);
        yyaxis 'left';
        plot(spatialFrequencySupport, theRGCSTF, 'ko', 'MarkerSize', 18,  'MarkerFaceColor', [0.8 0.8 0.8], 'LineWidth', 1.0); 
        hold on
        plot(spatialFrequencySupport(idx), d.DoGFit(idx), 'k-', 'LineWidth', 2);
        yyaxis 'right'
        plot(spatialFrequencySupport, theRGCcenterSTF, 'ro', 'MarkerSize', 14,  'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0, 'LineWidth', 1.0);
        hold on
        plot(spatialFrequencySupport, theRGCsurroundSTF, 'bo', 'MarkerSize', 14,  'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.0, 'LineWidth', 1.0);
        plot(spatialFrequencySupport(idx), d.DoGFitCenter(idx), 'r-', 'LineWidth', 2);
        plot(spatialFrequencySupport(idx), d.DoGFitSurround(idx), 'b-', 'LineWidth', 2);
        set(gca, 'XScale', 'linear', 'XLim', [4 50], 'FontSize', 16);
        grid on; box off
        xlabel('spatial frequency (c/deg)')
        title(sprintf('weights: STFcenter=%2.3f, STFsurround=%2.3f, STF:%2.3f', syntheticSTFtoFitComponentWeights.center, syntheticSTFtoFitComponentWeights.surround, syntheticSTFtoFitComponentWeights.composite));

        subplot('Position', [0.37 0.08 0.3 0.85]);
        yyaxis 'left'
        plot(spatialFrequencySupport, theRGCSTF, 'ko', 'MarkerSize', 18, 'MarkerFaceColor', [0.8 0.8 0.8], 'LineWidth', 1.0); hold on
        plot(spatialFrequencySupport(idx), d.DoGFit(idx), 'k-', 'LineWidth', 2);
        yyaxis 'right'
        plot(spatialFrequencySupport, theRGCcenterSTF, 'ro', 'MarkerSize', 14,  'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0, 'LineWidth', 1.0);
        hold on
        plot(spatialFrequencySupport, theRGCsurroundSTF, 'bo', 'MarkerSize', 14,  'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.0, 'LineWidth', 1.0);
        plot(spatialFrequencySupport(idx), d.DoGFitCenter(idx), 'r-', 'LineWidth', 2);
        plot(spatialFrequencySupport(idx), d.DoGFitSurround(idx), 'b-', 'LineWidth', 2);
        set(gca, 'XScale', 'log', 'XLim', [4 50], 'YTick', [], 'XTick', [2 5 10 20 40 60], 'FontSize', 16);
        xlabel('spatial frequency (c/deg)');
        title(sprintf('integrated S/C sensitivity: %2.3f', retinalDoGmodelSurroundCenterSensitivyRatio));
        grid on; box off


        for iParam = 1:2
            subplot('Position', [0.72+(iParam-1)*0.15 0.56 0.12 0.4]);
            hold 'on'
            plot([0 0], [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)], 'k-', 'LineWidth', 1.0);
            plot(0, d.DoGparams.lowerBounds(iParam), 'b.', 'MarkerSize', 16, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.0);
            plot(0, d.DoGparams.upperBounds(iParam), 'r.', 'MarkerSize', 16, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0);
            scatter(0, d.DoGparams.bestFitValues(iParam), 16*16, 'filled', ...
                'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 1 0.5], 'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 2);
            if (iParam == 2)
                set(gca, 'YTick', [0.1 0.3 1]);
            end

            set(gca, 'YScale', d.DoGparams.scale{iParam});
            set(gca, 'XLim', [-1 1], 'XTick', [],'YLim', [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)]);
            title(d.DoGparams.names{iParam});
            box on
            set(gca, 'FontSize', 16);
        end

        for iParam = 3:numel(d.DoGparams.names)
            subplot('Position',  [0.72+(1-(iParam-3))*0.15 0.08 0.12 0.4]);
            hold 'on'
            plot([0 0], [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)], 'k-', 'LineWidth', 1.0);
            plot(0, d.DoGparams.lowerBounds(iParam), 'b.', 'MarkerSize', 16, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.0);
            plot(0, d.DoGparams.upperBounds(iParam), 'r.', 'MarkerSize', 16, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0);
            scatter(0, d.DoGparams.bestFitValues(iParam), 16*16, 'filled', ...
                'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 1 0.5], 'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 2);
            if (iParam == 4)
                plot([-1 1], centerConeCharacteristicRadiusDegs*[1 1], 'k--');
            else
                plot([-1 1], [1 1], 'k--');
            end
            set(gca, 'YScale', d.DoGparams.scale{iParam});
            set(gca, 'XLim', [-1 1], 'XTick', [], 'YLim', [d.DoGparams.lowerBounds(iParam) d.DoGparams.upperBounds(iParam)]);
            title(d.DoGparams.names{iParam});
            box on
            set(gca, 'FontSize', 16);
        end
        pause
    end
    
end