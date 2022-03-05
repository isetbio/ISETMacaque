function cMosaicSTFResponses(monkeyID, stimulusType)
% Compute cone mosaic responses to stimuli of different SFs
%
% Syntax:
%   compute.cMosaicSTFResponses(monkeyID, stimulusType)
%
% Description:
%   Compute cone mosaic responses to stimuli of different SFs
%
% Inputs:
%    monkeyID       String, denoting which monkey data to use, e.g., 'M838'
%    stimulusType   String, denoting which stimulus model to use, e.g., 'monochromaticAO'
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    fprintf('Computing responses of %s cone mosaic to %s stimuli varying in SF.\n', ...
        monkeyID, stimulusType);
end