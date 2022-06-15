function visualizeDriftingAchromaticGrating()

    stimulusParams = simulator.params.AOSLOStimulus();
    stimulusParams.stimulationDurationCycles = 9/(1/6);

    % Compute spatial phase for each of the frames of the drifting grating
    spatialPhasesDegs = simulator.scene.spatialPhasesForDriftingGratingFrameScenes(...
        stimulusParams.stimulationDurationCycles, ...
        stimulusParams.frameDurationSeconds);

    
    spatialFrequencyExamined = 15;

    theListOfOpticalImages = cell(1, numel(spatialPhasesDegs));
    theStimulusTemporalSupportSeconds = zeros(1, numel(spatialPhasesDegs));

    hFig = figure(1); clf;
    set(hFig, 'Color', [0 0 0], 'Position', [10 10 305 305]);
    ax = subplot('Position', [0.0 0.0 1.0 1.0]);

    p = getpref('ISETMacaque');
    videoOBJ = VideoWriter(sprintf('%s/exports/stimAnimation',p.generatedDataDir), 'MPEG-4');
    videoOBJ.FrameRate = 30;
    videoOBJ.Quality = 100;
    videoOBJ.open();
    for iPhase = 1:numel(spatialPhasesDegs)
            stimulusParams.spatialFrequencyCPD = spatialFrequencyExamined;
            stimulusParams.spatialPhaseDegs = spatialPhasesDegs(iPhase);
            theStimulusTemporalSupportSeconds(iPhase) = (iPhase-1)*stimulusParams.frameDurationSeconds;
            if (theStimulusTemporalSupportSeconds(iPhase)<2.25)
                stimContrast = 0.0; 
            else
                stimContrast = 1.0;
            end

            if (stimulusParams.type == simulator.stimTypes.monochromaticAO)
                theFrameScene = simulator.scene.compute(stimulusParams, stimContrast, ...
                                    'sceneRadianceScalingFactor', 1.0);
            else
                theFrameScene = simulator.scene.compute(stimulusParams, stimContrast);
            end

            
            theFrame = sceneGet(theFrameScene, 'rgbimage');
            image(1:size(theFrame,2), 1:size(theFrame,2), theFrame);
            axis 'image'
            set(ax, 'XTick', [], 'YTick', [], 'Color', [0 0 0])
            x = size(theFrame,2)*0.4;
            y = size(theFrame,1)*0.05;
            text(ax, x,y, sprintf('t: %2.2fs', theStimulusTemporalSupportSeconds(iPhase)*6.67), 'FontSize', 18, 'Color', [0 1 0], 'BackgroundColor', [0 0 0]);

            drawnow
            videoOBJ.writeVideo(getframe(hFig));
     end % iPhase
    videoOBJ.close()
end
