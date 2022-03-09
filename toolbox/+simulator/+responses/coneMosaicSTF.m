function coneMosaicSTF(stimulusParams, theOI, theConeMosaic, coneMosaicResponsesFileName)
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
    
    fprintf('Generating the zero contrast (background) scene\n');
    % Generate the background stimulus scene
    if (stimulusParams.type == simulator.stimTypes.monochromaticAO)
        [theBackgroundScene, ...
         theSceneRadianceScalingFactor] = simulator.scene.compute(stimulusParams, ...
         'contrast', [], ...  % Setting the contrast to [] to get the scaling factor
         'AOSLOptics', theOI);
    else
        theBackgroundScene = simulator.scene.compute(stimulusParams);
    end
    
    % Report radiance scaling factor and mean luminance
    fprintf('Scene Radiance Scaling Factor is %f\n', theSceneRadianceScalingFactor);
    fprintf('Mean scene luminance is: %f\n', sceneGet(theBackgroundScene, 'mean luminance'));
   
    
    % Load spatial frequencies examined
    [~, spatialFrequenciesExamined] = simulator.load.fluorescenceSTFdata(monkeyID);
    
    % Compute spatial phase for each of the frames of the drifting grating
    spatialPhasesDegs = simulator.scene.spatialPhasesForDriftingGratingFrameScenes(stimulusParams.frameDurationSeconds);

    for iSF = 1:numel(spatialFrequenciesExamined)
        % Generate the list of optical images for each frame of the drifting grating
        fprintf('Generating OIsequence for the %2.1f c/deg drifting grating.\n', spatialFrequenciesExamined(iSF));

        theListOfOpticalImages = cell(1, numel(spatialPhases));
        theStimulusTemporalSupportSeconds = zeros(1, numel(spatialPhases));
       
        for iPhase = 1:numel(spatialPhasesDegs)
            stimulusParams.spatialFrequencyCPD = spatialFrequenciesExamined(iSF);
            stimulusParams.spatialPhaseDegs = spatialPhasesDegs(iPhase);

            if (stimulusParams.type == simulator.stimTypes.monochromaticAO)
                theStimFrameScene = simulator.scene.compute(stimulusParams, ...
                    'contrast', 1.0, ...
                    'sceneRadianceScalingFactor', theSceneRadianceScalingFactor);
            else
                theStimFrameScene = simulator.scene.compute(stimulusParams, ...
                    'contrast', 1.0);
            end

            fprintf('mean luminance (%2.2fc/deg, phase: %2.2f degs): %2.1f\ cd/m2n', ...
                spatialPhaseDegs(iPhase), sceneGet(theStimFrameScene, 'mean luminance'));
           
            % Compute the optical image of the test stimulus
            theListOfOpticalImages{iPhase} = oiCompute(theStimFrameScene, theOI);
            theStimulusTemporalSupportSeconds(iPhase) = (iPhase-1)*stimulusParams.frameDurationSeconds;
        end % iPhase

        % Generate OIsequence from the list of optical images
        theOIsequence = oiArbitrarySequence(theListOfOpticalImages, theStimulusTemporalSupportSeconds);
        theOIsequence.visualize('montage');
        
        % Compute the spatiotemporal cone-mosaic activation to this OIsequence
        [cmSpatiotemporalActivation, ~, ~, ~, temporalSupportSeconds] = ...
             theConeMosaic.compute(theOIsequence);

         % Single precision to save space
        coneMosaicSpatiotemporalActivation(iSF,:,:) = single(cmSpatiotemporalActivation);
    end % iSF
    
    
    % Compute the optical image of the background stimulus
    theBackgroundOI = oiCompute(theBackgroundScene, theOI);
    
    save(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined', '-v7.3');


end

