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
    operation = 'generateConeMosaic';
    options.recompute = ~true;

    % Choose stimulus type
    %operation = 'computeConeMosaicSTFresponses';
    %options.stimulusType = 'monochromaticAO';
   
    performOperation(operation, options, monkeyID);
end

function performOperation(operation, options, monkeyID)
    
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation name.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    

    switch (operation)
        case simulator.operations.generateConeMosaic
            simulator.compute.cMosaic(monkeyID, options.recompute);

        case simulator.operations.computeConeMosaicSTFresponses
            assert(ismember(options.stimulusType, enumeration('simulator.stimTypes')), ...
                sprintf('''%s'' is not a valid stimulus type.\nValid options are:\n %s', ...
                stimulusType, sprintf('\t%s\n',(enumeration('simulator.stimTypes')))));

            simulator.compute.cMosaicSTFResponses(monkeyID, options.stimulusType);
    end

end