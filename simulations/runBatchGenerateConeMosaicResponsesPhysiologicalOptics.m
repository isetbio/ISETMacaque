function runBatchGenerateConeMosaicResponsesPhysiologicalOptics()
% Generate cone mosaic responses to the STF stimuli using physiological optics
%
% Syntax:
%   runBatchGenerateConeMosaicResponsesPhysiologicalOptics()
%
% Description:
%    Generate cone mosaic responses to the STF stimuli using physiological optics
%    The computed cone mosaic responses for all stimulu are saved in a file
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

    % Choose the optics scenario and pupil size. These override default
    % values set in simulator.performOperation().
    operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
    operationOptions.pupilSizeMM = 2.5;

    % Choose which stimulus type to use. This overrides default
    % values set in simulator.performOperation().
    operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;

    % Choose what operation to run.
    operation = simulator.operations.computeConeMosaicSTFresponses;

    % Go !
    simulator.performOperation(operation, operationOptions, monkeyID);
end

