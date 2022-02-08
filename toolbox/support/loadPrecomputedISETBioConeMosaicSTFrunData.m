function modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, simulatedParams)
% Load the precomputed ISETBio cone mosaic model STF run data
%
% Syntax:
%   ISETBio = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, simulatedParams);
%
% Description:
%   Load precomputed ISETBio model responses to the spatial frequency runs
%
% Inputs:
%    monkeyID            - String, 'M838'
%    simulatedParams     - Struct defining various aspects of the simulation
%
% Outputs:
%    modelSTFrunData     - Struct with the STF run data
%
% Optional key/value pairs:
%    None
%          

    % Simulated cone aperture params
    simulatedParams.apertureParams.shape = 'Gaussian';
    simulatedParams.apertureParams.sigma = 0.204;

    % Synthesize responses filename
    ISETBioResponsesFilename = responsesFilename(monkeyID, ...
        simulatedParams.apertureParams, ...
        simulatedParams.modelVariant.coneCouplingLambda, ...
        simulatedParams.modelVariant.residualDefocusDiopters, ...
        simulatedParams.PolansSubject, ...
        simulatedParams.visualStimulus);
    
    % Load the computed ISETBio cone mosaic responses
    load(ISETBioResponsesFilename, ...
        'theConeMosaic', ...
        'temporalSupportSeconds', ...                  % 1  x 16 (time bins)
        'examinedSpatialFrequencies', ...              % 1  x 14 (spatial frequencies) 
        'coneMosaicBackgroundActivation', ...          % 1  x 1  x 13497 model cones              
        'coneMosaicSpatiotemporalActivation'  ...      % 14 x 16 x 13497 model cones
        );

    modelSTFrunData.theConeMosaic = theConeMosaic;
    modelSTFrunData.temporalSupportSeconds = temporalSupportSeconds;
    modelSTFrunData.examinedSpatialFrequencies = examinedSpatialFrequencies;
    modelSTFrunData.coneMosaicBackgroundActivation = coneMosaicBackgroundActivation;
    modelSTFrunData.coneMosaicSpatiotemporalActivation = coneMosaicSpatiotemporalActivation;
end