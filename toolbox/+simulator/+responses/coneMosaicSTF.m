function coneMosaicSTF(stimulusParams, theOI, theConeMosaic)
% Compute cone mosaic responses to stimuli of different SFs
%
% Syntax:
%   simulator.responses.coneMosaicSTF(stimulusParams, opticsParams, cMosaicParams)
%
% Description:
%   Compute cone mosaic responses to stimuli of different SFs
%
% Inputs:
%    stimulusParams     Struct with stimulus params
%    theOI              The @opticalImage object
%    theConeMosaic      The @cMosaic object
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    % Assert that we have a valid stimulusType
    assert(ismember(stimulusParams.type, enumeration('simulator.stimTypes')), ...
                sprintf('''%s'' is not a valid stimulus type.\nValid options are:\n %s', ...
                stimulusParams.type, sprintf('\t%s\n',(enumeration('simulator.stimTypes')))));
    
    fprintf('Computing cone mosaic responses  to %s stimuli (zero contrast).\n', ...
        stimulusParams.type);
    
    % Generate the background stimulus scene
    if (stimulusParams.type == simulator.stimTypes.monochromaticAO)
        [theBackgroundScene, ...
         sceneRadianceScalingFactor] = simulator.scene.compute(stimulusParams, 'AOSLOptics', theOI);
    else
        theBackgroundScene = simulator.scene.compute(stimulusParams);
    end
    
    meanLuminance = sceneGet(theBackgroundScene, 'mean luminance');
                
    fprintf('Scene Radiance Scaling Factor is %f\n', sceneRadianceScalingFactor);
    fprintf('Mean scene luminance is: %f\n', meanLuminance);
    
    % Generate the frames of the drifting gratingss
    
    
    fprintf('Computing responses cone mosaic responses to %s stimuli varying in SF.\n', ...
        stimulusParams.type);
    
    
    % Load spatial frequencies examined
    [~, spatialFrequenciesExamined] = simulator.load.fluorescenceSTFdata(monkeyID);
    
    for iSF = 1:numel(spatialFrequenciesExamined)
    end % iSF
    
    
    
    % Compute the optical image of the background stimulus
    theBackgroundOI = oiCompute(theBackgroundScene, theOI);
    
    
end

