function modelPerformance = fittedRGCModelPerformance(fittedModelFileName, operationOptions)
% Extract the performance of a fitted RGC model 
%
% Syntax:
%   simulator.analyze.fittedModelPerformance(fittedModelFileName, operationOptions)
%
% Description:
%   Extract the performance of a fitted RGC model
%
% Inputs:
%    fittedModelFileName  
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    load(fittedModelFileName, 'STFdataToFit','fittedModels');
    
    % Extract performance at the best cone position
    modelPerformance = containers.Map();
    for iModel = 1:numel(operationOptions.rfCenterConePoolingScenariosExamined)
        theRFcenterConePoolingScenario = operationOptions.rfCenterConePoolingScenariosExamined{iModel};
        examinedModelConePositionFits = fittedModels(theRFcenterConePoolingScenario);
        
        [bestConePosIdx, RMSErrorsAllPositions] = simulator.analyze.bestConePositionAcrossMosaic(...
            examinedModelConePositionFits, STFdataToFit, operationOptions.rmsSelector);

        modelPerformance(theRFcenterConePoolingScenario) = RMSErrorsAllPositions(bestConePosIdx);
    end
end

    