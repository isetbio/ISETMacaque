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

     
    validOperationNames = {...
        'computeConeMosaicSTFresponses' ...
        };
    validStimulusTypes = { ...
        'monochromaticAO' ...
        'achromaticLCD' ...
        };

    % Choose operation.
    operation = 'computeConeMosaicSTFresponses';
    assert(ismember(operation, validOperationNames), ...
        sprintf('''%s'' is not a valid operation name', operation));
       

    % Choose stimulus type
    stimulusType = 'monochromaticAO';
    assert(ismember(stimulusType, validStimulusTypes), ...
        sprintf('''%s'' is not a valid stimulus type', stimulusType));

    switch (operation)
        case 'computeConeMosaicSTFresponses'
            compute.coneMosaicSTFResponses(monkeyID, stimulusType);
    end

end