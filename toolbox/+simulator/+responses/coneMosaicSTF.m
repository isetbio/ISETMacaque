function coneMosaicSTF(spatialFrequenciesExamined, stimulusParams, theOI, theConeMosaic, coneMosaicResponsesFileName)
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
        % Setting the contrast to [] to compute the radiance scaling factor
        stimContrast = [];
        [theBackgroundScene, theSceneRadianceScalingFactor] = ...
            simulator.scene.compute(stimulusParams, stimContrast, ... 
                                    'AOSLOptics', theOI);
         % Report radiance scaling factor
         fprintf('Scene Radiance Scaling Factor is %f\n', theSceneRadianceScalingFactor);
    else
        theBackgroundScene = simulator.scene.compute(stimulusParams, ...
            'contrast', 0);
    end
    
    % Report  mean luminance
    fprintf('Mean scene luminance is: %f\n', sceneGet(theBackgroundScene, 'mean luminance'));
   
    
    % Compute spatial phase for each of the frames of the drifting grating
    spatialPhasesDegs = simulator.scene.spatialPhasesForDriftingGratingFrameScenes(...
        stimulusParams.stimulationDurationCycles, ...
        stimulusParams.frameDurationSeconds);

    stimContrast = 1.0;
    
    for iSF = 1:numel(spatialFrequenciesExamined)
        % Generate the list of optical images for each frame of the drifting grating
        fprintf('Generating OIsequence for the %2.1f c/deg drifting grating.\n', spatialFrequenciesExamined(iSF));

        theListOfOpticalImages = cell(1, numel(spatialPhasesDegs));
        theStimulusTemporalSupportSeconds = zeros(1, numel(spatialPhasesDegs));
       
        for iPhase = 1:numel(spatialPhasesDegs)
            stimulusParams.spatialFrequencyCPD = spatialFrequenciesExamined(iSF);
            stimulusParams.spatialPhaseDegs = spatialPhasesDegs(iPhase);
            
            if (stimulusParams.type == simulator.stimTypes.monochromaticAO)
                theFrameScene = simulator.scene.compute(stimulusParams, stimContrast, ...
                                    'sceneRadianceScalingFactor', theSceneRadianceScalingFactor);
            else
                theFrameScene = simulator.scene.compute(stimulusParams, stimContrast);
            end

            fprintf('mean luminance (phase: %2.2f degs): %2.1f cd/m2\n', ...
                spatialPhasesDegs(iPhase), sceneGet(theFrameScene, 'mean luminance'));
           
            % Compute the optical image of the test stimulus
            theListOfOpticalImages{iPhase} = oiCompute(theFrameScene, theOI);
            theStimulusTemporalSupportSeconds(iPhase) = (iPhase-1)*stimulusParams.frameDurationSeconds;
        end % iPhase

        % Generate OIsequence from the list of optical images
        theOIsequence = oiArbitrarySequence(theListOfOpticalImages, theStimulusTemporalSupportSeconds);
        %theOIsequence.visualize('montage');
        
        % Compute the spatiotemporal cone-mosaic activation to this OIsequence
        [cmSpatiotemporalActivation, ~, ~, ~, temporalSupportSeconds] = ...
            theConeMosaic.compute(theOIsequence);

         % Single precision to save space
        coneMosaicSpatiotemporalActivation(iSF,:,:) = single(cmSpatiotemporalActivation);
    end % iSF
    
    
    % Compute the optical image of the background stimulus
    theBackgroundOI = oiCompute(theBackgroundScene, theOI);
    
    % Compute the cone mosaic activation to the background stimulus
    fprintf('Computing background activation\n');
    coneMosaicBackgroundActivation = single(theConeMosaic.compute(theBackgroundOI));
    
    % Save all responses
    save(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined', '-v7.3');
end

