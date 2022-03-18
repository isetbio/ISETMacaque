function [bestConePosIdx, RMSErrorsAllPositions] = bestConePositionAcrossMosaic(...
    modelFitsAcrossMosaicPositions, STFdataToFit, rmsSelector)
% Visualize a fitted STF
%
% Syntax:
%   simulator.analyze.bestConePositionAcrossMosaic(...
%         modelFitsAcrossMosaicPositions, STFdataToFit, rmsSelector)
%
% Description:
%   Determine best cone position in terms of RMSE and return RMSEs across
%   all examined positions
%
% Inputs:
%    modelFitsAcrossMosaicPositions
%    STFdataToFit
%    rmsSelector
%
% Outputs:
%    bestConePosIdx
%    RMSErrorsAllPositions
%
% Optional key/value pairs:
%    none

    examinedConePositionsNum = numel(modelFitsAcrossMosaicPositions);
    RMSErrorsAllPositions = zeros(1, examinedConePositionsNum);

    switch (rmsSelector)
        case 'weighted'
            for iConePosIdx = 1:examinedConePositionsNum
                RMSErrorsAllPositions(iConePosIdx) = modelFitsAcrossMosaicPositions{iConePosIdx}.fittedRMSE;
            end
    
        case 'unweighted'
            for iConePosIdx = 1:examinedConePositionsNum
                n = numel(STFdataToFit.responses);
                RMSErrorsAllPositions(iConePosIdx) = sqrt(1/n*sum((STFdataToFit.responses - modelFitsAcrossMosaicPositions{iConePosIdx}.fittedSTF).^2));
            end

        otherwise
            error('Unknown rmsSelector:''%s''.', rmsSelector);
    end

    [~, bestConePosIdx] = min(RMSErrorsAllPositions);
end