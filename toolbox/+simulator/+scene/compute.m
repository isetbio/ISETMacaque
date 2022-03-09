function [theScene, theSceneRadianceScalingFactor] = compute(visualStimulus, contrast, varargin)
% Generate an ISETBIo scene encoding a stimulus frame
%
% Syntax:
%   [theScene, theSceneRadianceScalingFactor] = simulator.scene.compute(visualStimulus, varargin)
%
% Description: Generate optics
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021
    p = inputParser;
    p.addRequired('contrast', @(x)(isempty(x)||(isscalar(x))));
    p.addParameter('AOSLOptics', [], @(x)(isempty(x)||((isstruct(x))&&(strcmp(x.type, 'opticalimage')))));
    p.addParameter('sceneRadianceScalingFactor', [], @(x)(isempty(x)||(isscalar(x))));
    
    p.parse(contrast, varargin{:});
    theContrast = contrast;
    theSceneRadianceScalingFactor = p.Results.sceneRadianceScalingFactor;
    theOI = p.Results.AOSLOptics;
    
    switch (visualStimulus.type)
        
        case simulator.stimTypes.monochromaticAO
            if (isempty(theContrast))

                if (isempty(theOI))
                    error('When contrast is set to [], we need a valid OI to compute the scene radiance scaling factor');
                end
                % Background Scene
                % Compute the scaling factor using a 3 deg, uniform field stimulus to compute the energy over a
                % retinal region of 2.54x1.92 (which we know from measurements that it has a power of 2.5 microWatts)
                visualStimulus.fovDegs = 3;
                visualStimulus.contrast = 0;
                theUncalibratedBackgroundScene = simulator.scene.monochromaticGratingScene(visualStimulus);

                % Compute the OI of the background scene
                theOI = oiCompute(theUncalibratedBackgroundScene, theOI);

                % Compute scaling factor using the OI for the uniform field and the calibrationROI
                visualStimulus.sceneRadianceScalingFactor = simulator.scene.radianceScalingFactor(...
                    theOI, WilliamsLabData.constants.calibrationROI);

                % Make sure we got the right ROIenergy after applying the computed scaling factor
                theBackgroundScene = simulator.scene.monochromaticGratingScene(visualStimulus);
                
                theOI = oiCompute(theBackgroundScene, theOI);
                [~, computedROIenergyMicroWatts] = simulator.scene.radianceScalingFactor(...
                    theOI, WilliamsLabData.constants.calibrationROI);
                fprintf('Desired energy within ROI: %f microWatts, achieved: %f microWatts\n', ...
                    WilliamsLabData.constants.calibrationROI.energyMicroWatts, computedROIenergyMicroWatts); 

                % The background stimulus frame, now with the size used in the recordings
                visualStimulus.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
            else
                % Size used in the recordings
                visualStimulus.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
                % Same radiance scaling factor
                visualStimulus.sceneRadianceScalingFactor = theSceneRadianceScalingFactor;
                % Contrast
                visualStimulus.contrast = theContrast;
            end
            
            % Generate the scene
            theScene = simulator.scene.monochromaticGratingScene(visualStimulus);
            theSceneRadianceScalingFactor = visualStimulus.sceneRadianceScalingFactor;
            
              
        case simulator.stimTypes.achromaticLCD
            % Generate presentation display
            theDisplay = simulator.scene.presentationDisplay(visualStimulus);
            
            % Generate the scene
            visualStimulus.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
            visualStimulus.contrast = theContrast;
            theScene = simulator.scene.achromaticGratingSceneOnLCDdisplay(visualStimulus, theDisplay);
            theSceneRadianceScalingFactor = [];
            
        otherwise
            error('Unknown stimulus type: ''%s''.', visualStimulus.type);
    end

