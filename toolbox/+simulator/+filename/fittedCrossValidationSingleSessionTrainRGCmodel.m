function fittedCrossValidationModelFileName = fittedCrossValidationSingleSessionTrainRGCmodel(monkeyID, options, ...
    rfCenterConePoolingScenario, coneMosaicSamplingParams, fitParams, STFdataToFit, sessionIndex)

% Generate filename for the fitted cross-validation RGC model trained on a single session
%
% Syntax:
%   filename = fittedCrossValidationSingleSessionTrainRGCmodel(monkeyID, options, ...
%               rfCenterConePoolingScenario, coneMosaicSamplingParams, fitParams, STFdataToFit, sessionIndex)
%
% Description: Generate filename for the fitted 
%              (to the fluorescence STF data)RGC model
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    % Generic filename
    fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
          coneMosaicSamplingParams, fitParams, STFdataToFit);


    switch (options.stimulusParams.type)
        
        case simulator.stimTypes.monochromaticAO
            stimDescriptor = '_AOMonoChromatic';

        case simulator.stimTypes.achromaticLCD
            stimDescriptor = sprintf('_CRTLMS_%2.2f_%2.2f_%2.2f', ...
                options.stimulusParams.lmsConeContrasts(1), ...
                options.stimulusParams.lmsConeContrasts(2), ...
                options.stimulusParams.lmsConeContrasts(3));
        otherwise
            error('Unknown stimulus type: ''%s''.', options.stimulusParams.type);
    end

    % Add info about which cone pooling scenario was used
    postfixCenterConePoolingString = sprintf('%s_%sRFcenter', stimDescriptor, rfCenterConePoolingScenario);
    fittedCrossValidationModelFileName = strrep(fittedModelFileName, stimDescriptor, postfixCenterConePoolingString);

    % Add info about which session index was used to fit the model
    postfixSessionString = sprintf('fittedCrossValidationRGCmodelTrainedOnSession%d', sessionIndex);
    fittedCrossValidationModelFileName = strrep(fittedCrossValidationModelFileName, 'fittedRGCmodel', postfixSessionString);
    
end

