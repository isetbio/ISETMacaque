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
        set(hFig, 'Position', [10 10 1000 1250], 'Color', [1 1 1]);

        maxRMSE = max([max(bestPositionInSampleErrors(:)) max(bestPositionOutOfSampleErrors(:))]);
        minRMSE = min([min(bestPositionInSampleErrors(:)) min(bestPositionOutOfSampleErrors(:))]);

        modelScenarios = 1:numel(hypothesisLabels);

        c1 = [1 0.7 0.1];
        c2 = [0.1 0.7 1.0];

        x1 = modelScenarios-0.2;
        x2 = modelScenarios+0.2;
        y1 = (median(bestPositionInSampleErrors, 2))';
        y2 = (median(bestPositionOutOfSampleErrors, 2))';

        hold on
        showBars = true;
        if (showBars)
        
            
            barHandle1 = bar(x1,y1, 0.4);
            barHandle2 = bar(x2,y2, 0.4);
            
            
            barHandle1.FaceColor = c1;
            barHandle1.EdgeColor = barHandle1.FaceColor*0.5;
            barHandle1.FaceAlpha = 0.2;
            barHandle1.EdgeAlpha = 0.2;
            barHandle2.FaceColor = c2;
            barHandle2.EdgeColor = barHandle2.FaceColor*0.5;
            barHandle2.FaceAlpha = 0.2;
            barHandle2.EdgeAlpha = 0.2;

            for iModel = 1:size(bestPositionInSampleErrors,1)
                xx = [x1(iModel) x1(iModel)];
                yy = [min(squeeze(bestPositionInSampleErrors(iModel,:))) max(squeeze(bestPositionInSampleErrors(iModel,:)))];
                plot(xx, ...
                     yy, ...
                     'Color', c1, 'LineWidth', 1.5);
    
                xx = [x2(iModel) x2(iModel)];
                yy = [min(squeeze(bestPositionOutOfSampleErrors(iModel,:))) max(squeeze(bestPositionOutOfSampleErrors(iModel,:)))];
                plot(xx, ...
                    yy, ...
                    'Color', c2, 'LineWidth', 1.5);
            end


        else
            plot(x1, y1, '-', 'Color', [0 0 0], 'LineWidth', 4.0);
            plot(x2, y2, '-', 'Color', [0 0 0], 'LineWidth', 4.0);
            plot(x1, y1, '-', 'Color', c1, 'LineWidth', 2.0);
            plot(x2, y2, '-', 'Color', c2, 'LineWidth', 2.0);
        end


        for iModel = 1:size(bestPositionInSampleErrors,1)
            scatter(x1(iModel), bestPositionInSampleErrors(iModel,:), 400, ...
                'ko', 'MarkerFaceAlpha', 1, 'MarkerFaceColor', c1, ...
                'MarkerEdgeColor', c1*0.6, 'MarkerEdgeAlpha', 0.9, 'LineWidth', 1.5);
            scatter(x2(iModel), bestPositionOutOfSampleErrors(iModel,:), 400, ...
                'ko', 'MarkerFaceAlpha', 1, 'MarkerFaceColor', c2, ...
                'MarkerEdgeColor', c2*0.6, 'MarkerEdgeAlpha', 0.9, 'LineWidth', 1.5);
        end

        set(gca, 'XTick', 1:4, 'XLim', [0.5 4.5], 'XTickLabel', hypothesisLabels, 'FontSize', 24, ...
            'YLim', [minRMSE-0.1 maxRMSE+0.1], 'YTick', 0:0.1:4);
        grid on
        xtickangle(0);
        legend({'train', 'cross-validation'});
        ylabel('RMSE');
        
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
     if (strcmp(centerConesSchema, 'variable'))
         hypothesisLabel = sprintf(' multiple cones\\newlinedefocus: %2.3fD', residualDefocusDiopters);
     else
        hypothesisLabel = sprintf('    single cone\\newlinedefocus: %2.3fD', residualDefocusDiopters);
     end

     title(ax,hypothesisLabel)
     axis(ax,'square')
     set(ax, 'XLim', [0.5 numel(positionIndices)+0.5], 'YLim', [0 2], 'XTick', 0:1:200);
     set(ax, 'FontSize', 18);
     grid(ax, 'on')
     box(ax, 'off')
end

function fillBetweenLines(ax, x,y1,y2,fillColor)
    hold(ax, 'on');
    patch([x fliplr(x)], [y1 fliplr(y2)], [0 0 0],'FaceColor', fillColor, 'EdgeColor', fillColor, 'FaceAlpha', 0.5, 'LineWidth', 1.0, 'Parent', ax);
end
