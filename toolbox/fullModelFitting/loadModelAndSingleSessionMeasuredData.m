function [dSession, measuredData, cellType] = loadModelAndSingleSessionMeasuredData(theTrainedModelFitsfilename, monkeyID, sessionIndex)
    d = load(theTrainedModelFitsfilename);

    
    if (isfield(d, 'fittedParamsLcenterRGCs'))
        cellType = 'L';
        targetRGCindex = d.targetLcenterRGCindices(1);
        dSession.indicesOfModelCenterConePositionsExamined = d.indicesOfModelConesDrivingLcenterRGCs;
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerLConeCharacteristicRadiiDegs{sessionIndex};
        tmp.fittedParams = d.fittedParamsLcenterRGCs{sessionIndex};
        tmp.fittedSTFs = d.fittedSTFsLcenterRGCs{sessionIndex};
        tmp.rmsErrors = d.rmsErrorsLcenterRGCs{sessionIndex};
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumLcenterRGCs{sessionIndex};
        dSession.centroidPosition = d.centroidPositionLcenterRGCs{sessionIndex};
        dSession.centerConeIndices = d.centerConeIndicesLcenterRGCs{sessionIndex};
        dSession.centerConeWeights = d.centerConeWeightsLcenterRGCs{sessionIndex};
        dSession.surroundConeIndices = d.surroundConeIndicesLcenterRGCs{sessionIndex};
        dSession.surroundConeWeights = d.surroundConeWeightsLcenterRGCs{sessionIndex};
        measuredData = loadRawFluorescenceData(monkeyID, sessionIndex, cellType, targetRGCindex);
    else
        cellType = 'M';
        targetRGCindex = d.targetMcenterRGCindices(1);
        dSession.indicesOfModelCenterConePositionsExamined = d.indicesOfModelConesDrivingMcenterRGCs;
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerMConeCharacteristicRadiiDegs{sessionIndex};
        tmp.fittedParams = d.fittedParamsMcenterRGCs{sessionIndex};
        tmp.fittedSTFs = d.fittedSTFsMcenterRGCs{sessionIndex};
        tmp.rmsErrors = d.rmsErrorsMcenterRGCs{sessionIndex};
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumMcenterRGCs{sessionIndex};
        dSession.centroidPosition = d.centroidPositionMcenterRGCs{sessionIndex};
        dSession.centerConeIndices = d.centerConeIndicesMcenterRGCs{sessionIndex};
        dSession.centerConeWeights = d.centerConeWeightsMcenterRGCs{sessionIndex};
        dSession.surroundConeIndices = d.surroundConeIndicesMcenterRGCs{sessionIndex};
        dSession.surroundConeWeights = d.surroundConeWeightsMcenterRGCs{sessionIndex};
        measuredData = loadRawFluorescenceData(monkeyID, sessionIndex, cellType, targetRGCindex);
    end
    
    dSession.fittedParamsPositionExamined = squeeze(tmp.fittedParams(1, targetRGCindex,:,:));
    dSession.fittedSTFs = squeeze(tmp.fittedSTFs(1,targetRGCindex,:,:));
    dSession.rmsErrors = squeeze(tmp.rmsErrors(1,targetRGCindex,:));
    cellType = sprintf('%s%d', cellType, targetRGCindex);
end