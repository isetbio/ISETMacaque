function runBatchGenerateConeMosaicResponsesAOSLOOpticsResidualDefocus()
% Generate cone mosaic responses to the STF stimuli using AOSLO optics
% with different residual defocus values
%
% Syntax:
%   runBatchGenerateConeMosaicResponsesAOSLOOpticsResidualDefocus()
%
% Description:
%   Generate cone mosaic responses to the STF stimuli using AOSLO optics
%     with different residual defocus values
%   The computed cone mosaic responses for all stimulu are saved in a file
%    located in the $p.generatedDataDir/responses/ directory, where 
%    p = getpref('ISETMacaque'). The name of the file encodes information re:
%       - the monkey ID
%       - the stimulus
%       - the optics
%       - the cone mosaic parameters
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

    % Monkey to analyze
    monkeyID = 'M838';

    % Residual defocus values to examine
    examinedResidualDefocusDiopters = [0.00 0.025 0.042 0.057 0.062 0.067 0.072 0.077 0.082 0.1];
    
    % Choose the optics scenario. This overrides the default
    % values set in simulator.performOperation().
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % Choose which stimulus type to use. This overrides default
    % values set in simulator.performOperation().
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % Choose what operation to run.
    operation = simulator.operations.computeConeMosaicSTFresponses;

    for iResidualDefocus = 1:numel(examinedResidualDefocusDiopters)
        
        % Choose with residual defocus to employ in the AOSLO optics.
        % This overrides the default values set in simulator.performOperation().
        operationOptions.residualDefocusDiopters = examinedResidualDefocusDiopters(iResidualDefocus);
        
        % Go !
        simulator.performOperation(operation, operationOptions, monkeyID);
    end
    
end

