function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 512;

    % Select cell to examine
    targetLcenterRGCindices = [8]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
    targetMcenterRGCindices = []; % [1 2 4];   % the non-low pass cells

    % Select the Ca fluorescence response model to employ
    % Only play with the response offset
    accountForResponseOffset = true;
    
    % Always set to false. For drifting gratings, there is no reason why
    % the Ca response should go negative when the surround dominates the
    % center.
    accountForResponseSignReversal = false;

    % Train or cross-validate
    % Train
    operationMode = 'fitModelOnSingleSessionData';       
    %%%%%%%%operationMode = 'fitModelOnSessionAveragedData';
    
    % Cross-validate
    %operationMode = 'crossValidateFittedModelOnAllSessionData';
    %%%%%operationMode = 'crossValidateFittedModelOnSingleSessionData';


    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        hFigCrossValidation = figure(1000); clf;
        set(hFigCrossValidation, 'Position', [100 800 2100 540], 'Color', [1 1 1]);
    end


    testHypothesis = [1 1 1 1];
    
    idx = 0;
    for iTestedHypothesis = 1:4
        if (testHypothesis(iTestedHypothesis))
            switch (iTestedHypothesis)
                case 1
                        centerConesSchema =  'single';     % single-cone RF center
                        residualDefocusDiopters = 0.000;   % zero residual defocus
                case 2
                        centerConesSchema =  'single';     % single-cone RF center
                        residualDefocusDiopters = 0.067;   % 0.067D residual defocus
                case 3
                        centerConesSchema =  'variable';   % multiple-cones in RF center
                        residualDefocusDiopters = 0.000;   % zero residual defocus
                case 4
                        centerConesSchema =  'variable';   % multiple-cones in RF center
                        residualDefocusDiopters = 0.067;   % 0.067D residual defocus
                otherwise
                        error('Unknown hypothesis: %d', iTestedHypothesis)
            end
            
            idx = idx + 1;
            [inSampleErrors(idx,:,:),outOfSampleErrors(idx,:,:,:)] = batchFitISETBioModelToAOSTFdata(...
                targetLcenterRGCindices, targetMcenterRGCindices, ...
                centerConesSchema, residualDefocusDiopters, ...
                accountForResponseOffset, accountForResponseSignReversal, ...
                startingPointsNum, operationMode);

            if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
                [inSampleErrorAcrossAllPositionsMedian(idx), outOfSampleErrorAcrossAllPositionsMedian(idx), ...
                 inSampleErrorAcrossAllPositionsMin(idx), outOfSampleErrorAcrossAllPositionsMin(idx), ...
                 inSampleErrorAcrossAllPositionsMax(idx), outOfSampleErrorAcrossAllPositionsMax(idx), ...
                 bestPositionInSampleErrorMean(idx), bestPositionOutOfSampleErrorMean(idx), ...
                 bestPositionInSampleErrorMin(idx),  bestPositionOutOfSampleErrorMin(idx), ...
                 bestPositionInSampleErrorMax(idx),  bestPositionOutOfSampleErrorMax(idx), ...
                 hypothesisLabels{idx}] = plotCrossValidationErrorsAtAllPositions(hFigCrossValidation, idx, ...
                        squeeze(inSampleErrors(idx,:,:)), squeeze(outOfSampleErrors(idx,:,:,:)), ...
                        centerConesSchema, residualDefocusDiopters);
            end
        end % if Test
    end % for iTestedHypothesis


    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        % Plot RMSerrors across each position examined
        NicePlot.exportFigToPDF('CrossValidationAllPositions.pdf', hFigCrossValidation, 300);
    end
    
    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        hFigSummary = plotCrossValidationErrors(1001, ...
            bestPositionInSampleErrorMean, bestPositionOutOfSampleErrorMean, ...
            bestPositionInSampleErrorMin,  bestPositionOutOfSampleErrorMin, ...
            bestPositionInSampleErrorMax,  bestPositionOutOfSampleErrorMax, ...
            hypothesisLabels, 'best position');
        NicePlot.exportFigToPDF('CrossValidationBestPositionErrorSummary.pdf', hFigSummary, 300);
        
        hFigSummary = plotCrossValidationErrors(1002, ...
            inSampleErrorAcrossAllPositionsMedian, outOfSampleErrorAcrossAllPositionsMedian, ...
            inSampleErrorAcrossAllPositionsMin,  outOfSampleErrorAcrossAllPositionsMin, ...
            inSampleErrorAcrossAllPositionsMax,  outOfSampleErrorAcrossAllPositionsMax, ...
            hypothesisLabels, 'median over positions');
        NicePlot.exportFigToPDF('CrossValidationMedianOverPositionsErrorSummary.pdf', hFigSummary, 300);
        
    end
end

function hFig = plotCrossValidationErrors(figNo, ...
                inSampleErrorMean, outOfSampleErrorMean, ...
                inSampleErrorMin,  outOfSampleErrorMin, ...
                inSampleErrorMax,  outOfSampleErrorMax, ...
                hypothesisLabels, rmseLabel)
            
        % Plot mean RMS erros across all positions examined
        hFig = figure(figNo); clf;
        set(hFig, 'Position', [10 10 1500 750], 'Color', [1 1 1]);
        subplot(1,2,1);
        bar(1:numel(hypothesisLabels), inSampleErrorMean, 1, 'EdgeColor', [1 0 0], 'FaceColor', [1 0.5 0.5]); hold on
        er = errorbar(1:numel(hypothesisLabels), inSampleErrorMean, ...
            abs(inSampleErrorMean-inSampleErrorMin), abs(inSampleErrorMean-inSampleErrorMax));  
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  
        er.LineWidth = 1.5;
        set(gca, 'XTick', 1:4, 'XTickLabel', hypothesisLabels, 'FontSize', 24, 'YLim', [0.03 0.12], 'YTick', 0.02:0.02:0.2);
       
        xtickangle(45);
        title(sprintf('training RMSE (%s)', rmseLabel));

        subplot(1,2,2);
        bar(1:numel(hypothesisLabels), outOfSampleErrorMean, 1, 'EdgeColor', [0 0 1], 'FaceColor', [0.5 0.5 1]); hold on
        er = errorbar(1:numel(hypothesisLabels), outOfSampleErrorMean, ...
            abs(outOfSampleErrorMean-outOfSampleErrorMin), abs(outOfSampleErrorMean-outOfSampleErrorMax));  
        er.Color = [0 0 0];                            
        er.LineStyle = 'none'; 
        er.LineWidth = 1.5;
        set(gca, 'XTick', 1:4, 'XLim', [0.5 4.5], 'XTickLabel', hypothesisLabels, 'FontSize', 24, 'YLim', [0.03 0.12], 'YTick', 0.02:0.02:0.2);
        
        xtickangle(45);
        title(sprintf('cross-validated RMSE (%s)', rmseLabel));
        
end


function [medianInSampleErrorAcrossAllPositions, medianOutOfSampleErrorAcrossAllPositions, ...
    minInSampleErrorAcrossAllPositions, minOutOfSampleErrorAcrossAllPositions, ...
    maxInSampleErrorAcrossAllPositions, maxOutOfSampleErrorAcrossAllPositions, ...
    bestPositionInSampleErrorMean, bestPositionOutOfSampleErrorMean, ...
    bestPositionInSampleErrorMin,  bestPositionOutOfSampleErrorMin, ...
    bestPositionInSampleErrorMax,  bestPositionOutOfSampleErrorMax, ...
    hypothesisLabel] = ...
    plotCrossValidationErrorsAtAllPositions(hFig, subplotNo, inSampleErrors,outOfSampleErrors, centerConesSchema, residualDefocusDiopters)

     positionsNum = size(inSampleErrors,2);
     medianInSampleErrorForEachPosition = zeros(1, positionsNum);
     medianOutOfSampleErrorForEachPosition = zeros(1, positionsNum);
     minInSampleErrorForEachPosition = zeros(1, positionsNum);
     minOutOfSampleErrorForEachPosition = zeros(1, positionsNum);
     maxInSampleErrorForEachPosition = zeros(1, positionsNum);
     maxOutOfSampleErrorForEachPosition = zeros(1, positionsNum);

     for examinedRFpositionIndex = 1:positionsNum
         % Retrieve the in-sample errors for this position for the 3 training sessions
         inSampleErrorsForThisPosition = squeeze(inSampleErrors(:, examinedRFpositionIndex));
         
         % Retrieve the out-of-sample error for this position, for the 3 training sessions
         outOfSampleErrorsForThisPosition = squeeze(outOfSampleErrors(:, examinedRFpositionIndex,:));
         
         % Median of in-sample and out-of-sample errors over all sessions separately for each examined position
         %fprintf('Computing median of in-sample errors (%d evaluations)', numel(inSampleErrorsForThisPosition));
         %fprintf('Computing median out-of-sample errors (%d evaluations)', numel(outOfSampleErrorsForThisPosition));
         medianInSampleErrorForEachPosition(examinedRFpositionIndex) = median(inSampleErrorsForThisPosition(:));
         medianOutOfSampleErrorForEachPosition(examinedRFpositionIndex) = median(outOfSampleErrorsForThisPosition(:));

         % Min and max in-sample errors over all  sessions
         minInSampleErrorForEachPosition(examinedRFpositionIndex) = min(inSampleErrorsForThisPosition(:));
         maxInSampleErrorForEachPosition(examinedRFpositionIndex) = max(inSampleErrorsForThisPosition(:));
         
         % Min and max out-of-sample errors over all sessions
         minOutOfSampleErrorForEachPosition(examinedRFpositionIndex) = min(outOfSampleErrorsForThisPosition(:));
         maxOutOfSampleErrorForEachPosition(examinedRFpositionIndex) = max(outOfSampleErrorsForThisPosition(:));
     end


     % Find position with lowest cross-validation error
     [~,bestPositionIndex] = min(medianOutOfSampleErrorForEachPosition);
     
     % Report errors for this position
     bestPositionInSampleErrorMean = medianInSampleErrorForEachPosition(bestPositionIndex);
     bestPositionOutOfSampleErrorMean = medianOutOfSampleErrorForEachPosition(bestPositionIndex);
     
     bestPositionInSampleErrorMin = minInSampleErrorForEachPosition(bestPositionIndex);
     bestPositionInSampleErrorMax = maxInSampleErrorForEachPosition(bestPositionIndex);
     bestPositionOutOfSampleErrorMin = minOutOfSampleErrorForEachPosition(bestPositionIndex);
     bestPositionOutOfSampleErrorMax = maxOutOfSampleErrorForEachPosition(bestPositionIndex);
     
     
     % Median error over all positions examined
     medianInSampleErrorAcrossAllPositions = median(medianInSampleErrorForEachPosition(:));
     medianOutOfSampleErrorAcrossAllPositions = median(medianOutOfSampleErrorForEachPosition(:));
     
     % Min and Max errors over all positions examined
     minInSampleErrorAcrossAllPositions = min(medianInSampleErrorForEachPosition(:));
     minOutOfSampleErrorAcrossAllPositions = min(medianOutOfSampleErrorForEachPosition(:));
     maxInSampleErrorAcrossAllPositions = max(medianInSampleErrorForEachPosition(:));
     maxOutOfSampleErrorAcrossAllPositions = max(medianOutOfSampleErrorForEachPosition(:));
     
     % Plot rms errors
     figure(hFig);
     ax = subplot(1,4,subplotNo);
     
     positionIndices = 1:positionsNum;
     
     %fillBetweenLines(ax, positionIndices, minInSampleErrorForEachPosition, maxInSampleErrorForEachPosition, [1 0.5 0.5]);
     hold(ax, 'on');
     %fillBetweenLines(ax, positionIndices, minOutOfSampleErrorForEachPosition, maxOutOfSampleErrorForEachPosition, [0.5 0.5 1]);
     
     p1 = plot(ax,positionIndices, medianInSampleErrorForEachPosition,  'ro-', ...
         'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.5); 
     
     p2 = plot(ax,positionIndices, medianOutOfSampleErrorForEachPosition,  'bo-', ...
         'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
     
     plot(ax,bestPositionIndex, bestPositionInSampleErrorMean,  'rs', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'LineWidth', 1.5); hold on;
     plot(ax,bestPositionIndex, bestPositionOutOfSampleErrorMean,  'bs', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'LineWidth', 1.5);
     hold(ax, 'off')
     
     xlabel(ax,'mosaic position index');
     ylabel(ax,'rms error');
     legend(ax,[p1 p2], {'training', 'cross-validated'})
     hypothesisLabel = sprintf('%s center cone, defocus: %2.3fD', centerConesSchema, residualDefocusDiopters);
     title(ax,hypothesisLabel)
     axis(ax,'square')
     set(ax, 'XLim', [0.5 numel(positionIndices)+0.5], 'XTick', 0:1:200, 'YLim', [0.03 0.12], 'YTick', 0.00:0.01:0.2);
     set(ax, 'FontSize', 18);
     grid(ax, 'on')

end

function fillBetweenLines(ax, x,y1,y2,fillColor)
    hold(ax, 'on');
    patch([x fliplr(x)], [y1 fliplr(y2)], [0 0 0],'FaceColor', fillColor, 'EdgeColor', fillColor, 'FaceAlpha', 0.5, 'LineWidth', 1.0, 'Parent', ax);
end
