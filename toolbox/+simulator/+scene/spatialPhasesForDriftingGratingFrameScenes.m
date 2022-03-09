function spatialPhases = spatialPhasesForDriftingGratingFrameScenes(desiredStimulationCycles, displayFrameDurationSeconds)
    
    temporalStimulationPeriodDurationSeconds = 1/WilliamsLabData.constants.temporalStimulationFrequencyHz;
    desiredStimulusDurationSeconds = desiredStimulationCycles * temporalStimulationPeriodDurationSeconds;
    
    nFramesForAround1Cycle = floor(temporalStimulationPeriodDurationSeconds/displayFrameDurationSeconds);
    durationForAround1Cycle = nFramesForAround1Cycle * displayFrameDurationSeconds;
    totalFramesNum = round(desiredStimulusDurationSeconds/durationForAround1Cycle)*nFramesForAround1Cycle;
    totalDurationSeconds = totalFramesNum * displayFrameDurationSeconds;
    actualStimulationCycles = totalDurationSeconds * WilliamsLabData.constants.temporalStimulationFrequencyHz;

    spatialPhaseAdvanceDegs = 360 * displayFrameDurationSeconds * WilliamsLabData.constants.temporalStimulationFrequencyHz;
    spatialPhases = mod((0:1:(totalFramesNum-1))*spatialPhaseAdvanceDegs,360);
end