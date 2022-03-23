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
    
    thePhysiologicalOpticsSTF = computeSTF(coneMosaicSpatiotemporalActivation, theBestConePositionModel,  ...
        temporalSupportSeconds, spatialFrequenciesExamined, ...
        centerConeCharacteristicRadiusDegs);
    
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
                sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex), ...
                syntheticSTFdataPDFFilename);
end


function d = computeSTF(coneMosaicSpatiotemporalActivation, theRetinalRGCmodel, ...
    temporalSupportSeconds, spatialFrequencySupport, ...
    centerConeCharacteristicRadiusDegs)


    centerConeIndices = theRetinalRGCmodel.fittedRGCRF.centerConeIndices(:);
    centerConeWeights = theRetinalRGCmodel.fittedRGCRF.centerConeWeights(:);
    surroundConeIndices = theRetinalRGCmodel.fittedRGCRF.surroundConeIndices(:);
    surroundConeWeights = theRetinalRGCmodel.fittedRGCRF.surroundConeWeights(:);

    
    % Compute RGC responses
    [RGCresponses, centerResponses, surroundResponses] = ...
        simulator.modelRGC.poolConeMosaicResponses( ...
            coneMosaicSpatiotemporalActivation(:,:,centerConeIndices), ...
            coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices), ...
            centerConeWeights, ...
            surroundConeWeights);
        
        
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
     d.DoGFitHiRes] = simulator.fit.DoGmodelToSTF(...
        spatialFrequencySupport, theRGCSTF, ...
        centerConeCharacteristicRadiusDegs);
    
end