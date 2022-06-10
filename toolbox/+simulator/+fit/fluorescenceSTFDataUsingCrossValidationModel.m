function [inSampleError, outOfSampleError] = fluorescenceSTFDataUsingCrossValidationModel(...
                     STFdataToFit, theTrainedCrossValidationModel, ...
                     theSTFdataUsedToTrainTheCrossValidationModel, ...
                     trainSession, validationSession)


    % Determine cone position resulting in min RMSE
    examinedConePositionsNum = numel(theTrainedCrossValidationModel);
    for iConePosIndex = 1:examinedConePositionsNum
        theCrossValidationModelAtThisConePosition = theTrainedCrossValidationModel{iConePosIndex};
        RMSE(iConePosIndex) = theCrossValidationModelAtThisConePosition.fittedRMSE;
    end

    [inSampleError,bestConePositionIndex] = min(RMSE);
    theCrossValidationModelAtBestConePosition = theTrainedCrossValidationModel{bestConePositionIndex};

    params.initialValues(1) = 1.0;
    params.lowerBounds(1) = -10;
    params.upperBounds(1) = 10;
    params.names{1} = 'scalingFactor';

    if (STFdataToFit.fitParams.accountForNegativeSTFdata)
        % Add extra parameter at the end, encoding dcoffset
        negativeIndices = find(STFdataToFit.responses<0);
        if (isempty(negativeIndices))
           dcOffsetInitialValue = 0;
        else
           dcOffsetInitialValue = mean(STFdataToFit.responses(negativeIndices));
        end
        params.initialValues(numel(params.initialValues)+1) = dcOffsetInitialValue;
        params.lowerBounds(numel(params.lowerBounds)+1) = min([0 min(STFdataToFit.responses(:))]);
        params.upperBounds(numel(params.upperBounds)+1) = 0;  % dc-offset can only be negative
        params.names{numel(params.names)+1} = 'dcOffset';
    else
        params.initialValues(numel(params.initialValues)+1) = 0;
        params.lowerBounds(numel(params.lowerBounds)+1) = 0;
        params.upperBounds(numel(params.upperBounds)+1) = 0;
        params.names{numel(params.names)+1} = 'dcOffset';
    end

    
    switch(STFdataToFit.fitParams.spatialFrequencyBias)
        case simulator.spatialFrequencyWeightings.standardErrorOfTheMeanBased
            sfWeightingFactors = 1./(STFdataToFit.responseSE);

        case simulator.spatialFrequencyWeightings.boostHighEnd
            sfWeightingFactors = 1./(STFdataToFit.responseSE) .* ...
                                 linspace(0.1,1,numel(STFdataToFit.responseSE));

        case simulator.spatialFrequencyWeightings.flat
            sfWeightingFactors = ones(1,numel(STFdataToFit.responseSE));
    end

    % Ensure that we have correct weights dimensionality
    assert(all(size(sfWeightingFactors) == size(STFdataToFit.responses)), ...
        sprintf('Size of weighting factors does not agree with response size'));


    % Objective
    testData = STFdataToFit.responses;
    trainingData = theCrossValidationModelAtBestConePosition.fittedSTF;
    objective = @(p) sum(sfWeightingFactors .* ((p(2) + p(1) * trainingData) - testData).^2);
        
    % Fmincon options
    options = optimset(...
            'Display', 'off', ...
            'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
            'GradObj', 'off', ...
            'DerivativeCheck', 'off', ...
            'MaxFunEvals', 10^5, ...
            'MaxIter', 10^3);

    % Find the optimal scaling factor
    bestParams = fmincon(objective, params.initialValues,[],[],[],[],...
        params.lowerBounds, params.upperBounds,[],options);
         
    fittedSTFusingCrossValidationModel = (bestParams(2) + bestParams(1) * trainingData);
    
    % Compute the RMSE of the fit
    outOfSampleError = sqrt(sum(sfWeightingFactors .* (fittedSTFusingCrossValidationModel - testData).^2)/sum(sfWeightingFactors(:)));



%     hFig = figure(1); clf;
% 
%     sfSupport = theSTFdataUsedToTrainTheCrossValidationModel.spatialFrequencySupport;
%     trainingSessionSTF = theSTFdataUsedToTrainTheCrossValidationModel.responses;
%     testingSessionSTF = singleSessionSTFdataToFit.responses;
%     for iConePosIndex = 1:examinedConePositionsNum
%         theCrossValidationModelAtThisConePosition = theTrainedCrossValidationModel{iConePosIndex};
%         
%         ax = subplot(3,3, iConePosIndex);
%         plot(ax, sfSupport, trainingSessionSTF, 'ko', 'MarkerSize', 16, 'MarkerFaceColor', [0.65 0.65 0.65], 'LineWidth', 2); 
%         hold(ax, 'on');
%         plot(ax, sfSupport, testingSessionSTF, 'ks-', 'MarkerSize', 12, 'MarkerFaceColor', [0.85 0.55 0.55], 'LineWidth', 1.0);
%         
%         plot(ax, sfSupport, theCrossValidationModelAtThisConePosition.fittedSTF, 'k-',  'LineWidth',2);
%         plot(ax, sfSupport, theCrossValidationModelAtThisConePosition.fittedSTFcenter, 'r-', 'LineWidth', 2);
%         plot(ax, sfSupport, theCrossValidationModelAtThisConePosition.fittedSTFsurround, 'b-', 'LineWidth', 2);
%         set(ax, 'XScale', 'log', 'XLim', [4 60], 'XTick', [3 10 20 40 60], 'FontSize', 14)
%         h = legend({...
%             sprintf('STF (train session %d)', trainSession) ...
%             sprintf('STF (validation session %d)', validationSession) ...
%             'train model (composite)' ...
%             'train model (center)' ...
%             'train model (surround)' ...
%             }, 'Location', 'NorthOutside', 'NumColumns', 2);
% 
%         title(sprintf('Cone position %d (RMSE:%2.3f)', iConePosIndex, theCrossValidationModelAtThisConePosition.fittedRMSE));
%     end
    

end


                      