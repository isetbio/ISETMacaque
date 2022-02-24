function [dSession, measuredData, cellType] = loadModelAndAverageSessionMeasuredData(theTrainedModelFitsfilename, monkeyID)
    d = load(theTrainedModelFitsfilename);

    
    if (isfield(d, 'fittedParamsLcenterRGCs'))
        cellType = 'L';
        dSession.indicesOfModelCenterConePositionsExamined = d.indicesOfModelConesDrivingLcenterRGCs;
        targetRGCindex = d.targetLcenterRGCindices(1);
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerLConeCharacteristicRadiiDegs;
        tmp.fittedParams = d.fittedParamsLcenterRGCs;
        tmp.fittedSTFs = d.fittedSTFsLcenterRGCs;
        tmp.rmsErrors = d.rmsErrorsLcenterRGCs;
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumLcenterRGCs;
        dSession.centroidPosition = d.centroidPositionLcenterRGCs;
        dSession.centerConeIndices = d.centerConeIndicesLcenterRGCs;
        dSession.centerConeWeights = d.centerConeWeightsLcenterRGCs;
        dSession.surroundConeIndices = d.surroundConeIndicesLcenterRGCs;
        dSession.surroundConeWeights = d.surroundConeWeightsLcenterRGCs;
        
    else
        cellType = 'M';
        dSession.indicesOfModelCenterConePositionsExamined = d.indicesOfModelConesDrivingMcenterRGCs;
        targetRGCindex = d.targetMcenterRGCindices(1);
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerMConeCharacteristicRadiiDegs;
        tmp.fittedParams = d.fittedParamsMcenterRGCs;
        tmp.fittedSTFs = d.fittedSTFsMcenterRGCs;
        tmp.rmsErrors = d.rmsErrorsMcenterRGCs;
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumMcenterRGCs;
        dSession.centroidPosition = d.centroidPositionMcenterRGCs;
        dSession.centerConeIndices = d.centerConeIndicesMcenterRGCs;
        dSession.centerConeWeights = d.centerConeWeightsMcenterRGCs;
        dSession.surroundConeIndices = d.surroundConeIndicesMcenterRGCs;
        dSession.surroundConeWeights = d.surroundConeWeightsMcenterRGCs;
    end
    
    for sessionIndex = 1:3
        sessionData = loadRawFluorescenceData(monkeyID, sessionIndex, cellType, targetRGCindex);
        singleSessionDFresponses(sessionIndex,:) = sessionData.dFresponses;
        singleSessionDFresponsesStd(sessionIndex,:) = sessionData.dFresponsesStd;
    end

    measuredData.dFresponses = mean(singleSessionDFresponses,1);
    measuredData.dFresponsesStd = mean(singleSessionDFresponsesStd,1);
    
    dSession.fittedParamsPositionExamined = squeeze(tmp.fittedParams(1, targetRGCindex,:,:));
    dSession.fittedSTFs = squeeze(tmp.fittedSTFs(1,targetRGCindex,:,:));
    dSession.rmsErrors = squeeze(tmp.rmsErrors(1,targetRGCindex,:));
    cellType = sprintf('%s%d', cellType, targetRGCindex);
end


function  measuredData = loadRawFluorescenceData(monkeyID, sessionIndex, coneType, targetRGCindex)
    switch (sessionIndex)
        case 1
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session1only'); 
        case 2
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session2only');
        case 3
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session3only');
    end
    switch (coneType)
        case 'L'
            measuredData.dFresponses = d.dFresponsesLcenterRGCs(targetRGCindex,:);
            measuredData.dFresponsesStd = d.dFresponseStdLcenterRGCs(targetRGCindex,:);
        case 'M'
            measuredData.dFresponses = d.dFresponsesMcenterRGCs(targetRGCindex,:);
            measuredData.dFresponsesStd = d.dFresponseStdMcenterRGCs(targetRGCindex,:);
    end
        
end
