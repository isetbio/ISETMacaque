function runBatchGenerateConeMosaicResponsesAOSLOOpticsResidualDefocus()
% Compute model cone mosaic responses to the STF stimuli using AOSLO optics
% for different amounts of residual defocus values
%
% Syntax:
%   runBatchGenerateConeMosaicResponsesAOSLOOpticsResidualDefocus()
%
% Description:
%   Compute model cone mosaic responses to the STF stimuli using AOSLO optics
%     with different residual defocus values
%   The computed cone mosaic responses for all stimuli are saved in a file
%    located in the $p.generatedDataDir/responses/ directory, where 
%    p = getpref('ISETMacaque'). The name of the file encodes information re:
%       - the monkey ID
%       - the stimulus
%       - the optics
%       - the cone mosaic parameters
%
%   The computed cone mosaic responses are used by runBatchFit() to derive
%   cone pooling models via fitting a center/surround antagonistic model to
%   the measured DF/F STF data.
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         
%         
% History:
%    March 2022   NPC    Wrote it
%

    % Monkey to employ
    monkeyID = 'M838';

    % Choose what operation to run.
    operation = simulator.operations.computeConeMosaicSTFresponses;

    % Always use the monochromatic AO stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % Choose the optics scenario to run.
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % Residual defocus values for which to compute model cone mosaic responses
    examinedResidualDefocusDiopters = [0.00 0.025 0.042 0.057 0.062 0.067 0.072 0.077 0.082 0.1];
    examinedResidualDefocusDiopters = 0.067;
    
    % Repeat computation for all examined residual defocus values
    for iResidualDefocus = 1:numel(examinedResidualDefocusDiopters)
        operationOptions.residualDefocusDiopters = examinedResidualDefocusDiopters(iResidualDefocus);
        
        % Go !
        simulator.performOperation(operation, operationOptions, monkeyID);
    end
end