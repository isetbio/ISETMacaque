function runOperation
% Main gateway to all operations
%
% Syntax:
%   runOperation()
%
% Description:
%   Run some operation (e.g., generate cone mosaic responses, fit etc)
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

    % Choose operation
    % --------------------------------------
    % 1. Generate cone mosaic
    % --------------------------------------
    %operation = 'generateConeMosaic';
    %options.recompute = ~true;
    
    % --------------------------------------
    % 2. Compute cone mosaic responses
    % --------------------------------------
    operation = 'computeConeMosaicSTFresponses';

    % Stimulus params
    options.stimulusParams = struct(...
        'type', 'monochromaticAO', ...
        'orientation', 90);
    
    % Optics params
    options.opticsParams = struct(...
        'type', 'diffractionLimited', ...
        'residualDefocusDiopters', 0.067, ...
        'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM ...
        );

   % Cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204);


    % --------------------------------------
    % 3. Something else
    % --------------------------------------


    % Go !
    performOperation(operation, options, monkeyID);
end

function performOperation(operation, options, monkeyID)

    % Assert that we have a valid operation
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation name.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    % Switch
    switch (operation)
        case simulator.operations.generateConeMosaic
            simulator.compute.cMosaic(monkeyID, options.recompute);

        case simulator.operations.computeConeMosaicSTFresponses
            
            simulator.compute.cMosaicSTFResponses(monkeyID, ...
                options.stimulusParams, ...
                options.opticsParams, ...
                options.cMosaicParams);
    end

end