function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 512;

    % Select cell to examine
    targetLcenterRGCindices = [11]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
    targetMcenterRGCindices = []; % [1 2 4];   % the non-low pass cells

    % Select the Ca fluorescence response model to employ
    % Only play with the response offset
    accountForResponseOffset = ~true;
    
    % Always set to false. For drifting gratings, there is no reason why
    % the Ca response should go negative when the surround dominates the
    % center.
    accountForResponseSignReversal = false;


    % Choose whether to bias toward the high SF points in the computation of the RMSError
    % Select between {'none', 'flat', 'boostHighSpatialFrequencies'}
    fitBias = 'none';                           % 1/stdErr
    fitBias = 'boostHighSpatialFrequencies';   % 1/stdErr .* linearlyIncreasingFactor
    %fitBias = 'flat';                          % all ones



    % Train  models
    operationMode = 'fitModelOnSingleSessionData'; 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%operationMode = 'fitModelOnSessionAveragedData';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Cross-validate models
    operationMode = 'crossValidateFittedModelOnAllSessionData';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%operationMode = 'crossValidateFittedModelOnSingleSessionData';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                startingPointsNum, operationMode, fitBias);

            if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
                [bestPositionInSampleErrors(idx,:), bestPositionOutOfSampleErrors(idx,:), hypothesisLabels{idx}] = ...
                    plotCrossValidationErrorsAtAllPositions(hFigCrossValidation, idx, ...
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
            bestPositionInSampleErrors, bestPositionOutOfSampleErrors, ...
            hypothesisLabels);
        NicePlot.exportFigToPDF('CrossValidationBestPositionErrorSummary.pdf', hFigSummary, 300);
        
    end
end

function hFig = plotCrossValidationErrors(figNo, ...
                bestPositionInSampleErrors, bestPositionOutOfSampleErrors, ...
                hypothesisLabels)
            
        % Plot mean RMS erros across all positions examined
        hFig = figure(figNo); clf;
        set(hFig, 'Position', [10 10 1500 750], 'Color', [1 1 1]);

        subplot(1,2,1);
        bar(1:numel(hypothesisLabels), median(bestPositionInSampleErrors, 2), 1, 'EdgeColor', [1 0 0], 'FaceColor', [1 0.5 0.5]); hold on
        for modelScenario = 1:size(bestPositionInSampleErrors,1)
            scatter(modelScenario + zeros(1,size(bestPositionInSampleErrors,2)), bestPositionInSampleErrors(modelScenario,:), 300, ...
                'ko', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [1 0.8 0.2], 'MarkerEdgeColor', [1 0.5 0], 'LineWidth', 1.0);
        end

        set(gca, 'XTick', 1:4, 'XTickLabel', hypothesisLabels, 'FontSize', 24, 'YLim', [0 2], 'YTick', 0:0.5:2);
       
        xtickangle(45);
        title(sprintf('training RMSE'));

        subplot(1,2,2);
        bar(1:numel(hypothesisLabels), median(bestPositionOutOfSampleErrors, 2), 1,  'EdgeColor', [0 0 1], 'FaceColor', [0.5 0.5 1]); hold on
        for modelScenario = 1:size(bestPositionOutOfSampleErrors,1)
            scatter(modelScenario + zeros(1,size(bestPositionOutOfSampleErrors,2)), bestPositionOutOfSampleErrors(modelScenario,:), 300, ...
                'ko', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.2 0.8 1.0], 'MarkerEdgeColor', [0 0.5 1], 'LineWidth', 1.0);
        end

        set(gca, 'XTick', 1:4, 'XLim', [0.5 4.5], 'XTickLabel', hypothesisLabels, 'FontSize', 24,  'YLim', [0 2], 'YTick', 0:0.5:2);
        
        xtickangle(45);
        title(sprintf('cross-validated RMSE'));
        
end


function [bestPositionInSampleErrors,  bestPositionOutOfSampleErrors, hypothesisLabel] = ...
    plotCrossValidationErrorsAtAllPositions(hFig, subplotNo, inSampleErrors,outOfSampleErrors, centerConesSchema, residualDefocusDiopters)

     positionsNum = size(inSampleErrors,2);
     medianInSampleErrorForEachPosition = zeros(1, positionsNum);
     medianOutOfSampleErrorForEachPosition = zeros(1, positionsNum);
     

    % Compute median out of sample errors for each position examined
     for iPos = 1:positionsNum
         inSampleErrorsForThisPosition = squeeze(inSampleErrors(:, iPos));
         medianInSampleErrorForEachPosition(iPos) = median(inSampleErrorsForThisPosition(:));
         outOfSampleErrorsForThisPosition = squeeze(outOfSampleErrors(:, iPos,:));
         medianOutOfSampleErrorForEachPosition(iPos) = median(outOfSampleErrorsForThisPosition(:));
     end


     % Find the position with the min median error
     [~, bestPosition] = min(medianOutOfSampleErrorForEachPosition);


     bestPositionInSampleErrors = squeeze(inSampleErrors(:, bestPosition));
     bestPositionOutOfSampleErrors = squeeze(outOfSampleErrors(:, bestPosition,:));
     bestPositionOutOfSampleErrors = bestPositionOutOfSampleErrors(:);

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
     
     plot(ax,bestPosition, medianInSampleErrorForEachPosition(bestPosition),  'rs', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'LineWidth', 1.5); hold on;
     plot(ax,bestPosition, medianOutOfSampleErrorForEachPosition(bestPosition),  'bs', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'LineWidth', 1.5);
     hold(ax, 'off')
     
     xlabel(ax,'mosaic position index');
     ylabel(ax,'rms error');
     legend(ax,[p1 p2], {'training', 'cross-validated'})
     hypothesisLabel = sprintf('%s center cone, defocus: %2.3fD', centerConesSchema, residualDefocusDiopters);
     title(ax,hypothesisLabel)
     axis(ax,'square')
     set(ax, 'XLim', [0.5 numel(positionIndices)+0.5], 'YLim', [0 2], 'XTick', 0:1:200);
     set(ax, 'FontSize', 18);
     grid(ax, 'on')

end

function fillBetweenLines(ax, x,y1,y2,fillColor)
    hold(ax, 'on');
    patch([x fliplr(x)], [y1 fliplr(y2)], [0 0 0],'FaceColor', fillColor, 'EdgeColor', fillColor, 'FaceAlpha', 0.5, 'LineWidth', 1.0, 'Parent', ax);
end
