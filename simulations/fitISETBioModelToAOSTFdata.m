function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 512;

    % Select cell to examine
    targetLcenterRGCindices = [1]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
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
    %fitBias = 'boostHighSpatialFrequencies';   % 1/stdErr .* linearlyIncreasingFactor
    %fitBias = 'flat';                          % all ones



    % Train  models
    operationMode = 'fitModelOnSingleSessionData'; 

    % Extract weights by fitting the average data - after we have picked
    % the best cross-validated model
    %operationMode = 'fitModelOnSessionAveragedData';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%operationMode = 'fitModelOnSessionAveragedData';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Cross-validate models
    operationMode = 'crossValidateFittedModelOnAllSessionData';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%operationMode = 'crossValidateFittedModelOnSingleSessionData';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    testHypothesis =  [1 1 1 1];
    
    iModelScenario = 0;
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
            
            iModelScenario = iModelScenario + 1;
            [inSampleErrors(iModelScenario,:,:),outOfSampleErrors(iModelScenario,:,:,:), modelVariant] = batchFitISETBioModelToAOSTFdata(...
                targetLcenterRGCindices, targetMcenterRGCindices, ...
                centerConesSchema, residualDefocusDiopters, ...
                accountForResponseOffset, accountForResponseSignReversal, ...
                startingPointsNum, operationMode, fitBias);
        end % if Test
    end % for iTestedHypothesis


    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        % Plot RMSerrors across each position examined

        hFig = figure(1000); clf
        set(hFig, 'Position', [10 10 1300 750], 'Color', [1 1 1]);
        width = 0.4/2*0.9;
        height = 0.8/2*0.9;
        widthMargin = 0.02;
        heightMargin = 0.14;
        for iModelScenario = 1:4
            row = 1-floor((iModelScenario-1)/2);
            col = mod((iModelScenario-1),2);
            ax{iModelScenario} = subplot('Position', [0.05 + col*(width+widthMargin), 0.07 + row*(height+heightMargin) width height]);
        end
        axSummary = subplot('Position', [0.11+2*(width+widthMargin) 0.095 0.48 0.9]);

        for iModelScenario = 1:size(inSampleErrors,1)
            
            noXLabel = true;
            noYLabel = true;
            if (iModelScenario == 1) || (iModelScenario == 3)
                noYLabel = false;
            end
            if (iModelScenario > 2)
                noXLabel = false;
            end

            
            if (~isempty(targetLcenterRGCindices))
                cellString = sprintf('L%d', targetLcenterRGCindices(1));
            else 
                cellString = sprintf('M%d', targetMcenterRGCindices(1));
            end


            switch (iModelScenario)
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

            [bestPositionInSampleErrors(iModelScenario,:), ...
             bestPositionOutOfSampleErrors(iModelScenario,:), ...
             modelScenarioLabels{iModelScenario}] = ...
                    plotCrossValidationErrorsAtAllPositions(ax{iModelScenario}, ...
                        squeeze(inSampleErrors(iModelScenario,:,:)), ...
                        squeeze(outOfSampleErrors(iModelScenario,:,:,:)), ...
                        centerConesSchema, residualDefocusDiopters, ...
                        noXLabel, noYLabel, [0 2]);
            
        end


        rmsErrorRange(1) = min([ ...
            min(bestPositionInSampleErrors(:)) ...
            min(bestPositionOutOfSampleErrors(:)) ...
            ]);

        rmsErrorRange(2) = max([ ...
            max(bestPositionInSampleErrors(:)) ...
            max(bestPositionOutOfSampleErrors(:)) ...
            ]);

        dRange = rmsErrorRange(2)-rmsErrorRange(1);
        
        rmsErrorRange(1) = max([0 rmsErrorRange(1)-dRange*0.1]);
        rmsErrorRange(2) = rmsErrorRange(2) + dRange*0.3;

        if (dRange < 0.1)
            yTicks = 0:0.01:rmsErrorRange(2);
        elseif (dRange < 0.2)
            yTicks = 0:0.02:rmsErrorRange(2);
        elseif (dRange < 0.5)
            yTicks = 0:0.05:rmsErrorRange(2);
        elseif (dRange < 1.2)
            yTicks = 0:0.2:rmsErrorRange(2);
        elseif (dRange < 1.5)
            yTicks = 0:0.25:rmsErrorRange(2);
        elseif (dRange < 5)
            yTicks = 0:0.5:rmsErrorRange(2);
        else
            yTicks = 0:1:rmsErrorRange(2);
        end

        for iModelScenario = 1:size(inSampleErrors,1)
            set(ax{iModelScenario}, 'YLim', rmsErrorRange, 'YTick', yTicks);
        end

        plotCrossValidationErrors(axSummary, ...
            bestPositionInSampleErrors, bestPositionOutOfSampleErrors, ...
            modelScenarioLabels, cellString, rmsErrorRange);

        set(axSummary, 'YLim', rmsErrorRange, 'YTick', yTicks);
       

        pdfFilename = crossValidationSummaryFilename(modelVariant, cellString, startingPointsNum);
        NicePlot.exportFigToPDF(pdfFilename, hFig, 300);
        
    end
end

function plotCrossValidationErrors(ax, ...
                bestPositionInSampleErrors, bestPositionOutOfSampleErrors, ...
                hypothesisLabels, cellString, rmsErrorRange)
            
        % Plot mean RMS erros across all positions examined
        maxRMSE = max([max(bestPositionInSampleErrors(:)) max(bestPositionOutOfSampleErrors(:))]);
        minRMSE = min([min(bestPositionInSampleErrors(:)) min(bestPositionOutOfSampleErrors(:))]);

        modelScenarios = 1:numel(hypothesisLabels);

        c1 = [1 0.7 0.1];
        c2 = [0.1 0.7 1.0];

        x1 = modelScenarios-0.2;
        x2 = modelScenarios+0.2;
        y1 = (mean(bestPositionInSampleErrors, 2))';
        y2 = (mean(bestPositionOutOfSampleErrors, 2))';

        barHandle1 = bar(ax,x1,y1, 0.4);
        hold(ax, 'on')
        barHandle2 = bar(ax, x2,y2, 0.4);


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
            plot(ax, xx,yy, 'Color', c1, 'LineWidth', 1.5);

            xx = [x2(iModel) x2(iModel)];
            yy = [min(squeeze(bestPositionOutOfSampleErrors(iModel,:))) max(squeeze(bestPositionOutOfSampleErrors(iModel,:)))];
            plot(ax, xx, yy, 'Color', c2, 'LineWidth', 1.5);
        end



        for iModel = 1:size(bestPositionInSampleErrors,1)
            scatter(ax,x1(iModel)+zeros(1,size(bestPositionInSampleErrors,2)), bestPositionInSampleErrors(iModel,:), 200, ...
                'ko', 'MarkerFaceAlpha', 0.8, 'MarkerFaceColor', c1, ...
                'MarkerEdgeColor', [0 0 0], 'MarkerEdgeAlpha', 1, 'LineWidth', 1.);
            scatter(ax, x2(iModel)+zeros(1,size(bestPositionOutOfSampleErrors,2)), bestPositionOutOfSampleErrors(iModel,:), 200, ...
                'ko', 'MarkerFaceAlpha', 0.8, 'MarkerFaceColor', c2, ...
                'MarkerEdgeColor', [0 0 0], 'MarkerEdgeAlpha', 1, 'LineWidth', 1.);
        end

        set(ax, 'XTick', 1:4, 'XLim', [0.5 4.5], 'XTickLabel', hypothesisLabels, 'FontSize', 20, ...
            'YLim', rmsErrorRange, 'YTick', 0:0.2:4);
        
        
        
        % Significance testing
        fprintf(2,'Checking significance levels\n');
        
        nullHypothesisData = bestPositionOutOfSampleErrors(1,:);

        for iAlternativeModel = 2:4
            testHypothesisData = bestPositionOutOfSampleErrors(iAlternativeModel,:);

            % Test against the null hypothesis that the
            % population mean of error fits of the null model (single cone/ 0.000D residual defocus)
            % is GREATER then the 
            % population mean of error fits of the alternative model

            [testPassed, pVal] = ttest2(nullHypothesisData, testHypothesisData, ...
                'Tail', 'right', ...
                'Alpha', 0.10, ...
                'Vartype', 'unequal');
    
            if (testPassed == 1)
                fprintf(2,'the MEANS of Model 1 and model %d are significantly different with a p-level of %f\n', ...
                    iAlternativeModel, pVal);
            end

            separation = diff(rmsErrorRange)/1.394*0.07;
            separationOffset = diff(rmsErrorRange)/1.394*0.02;
            textDrop = diff(rmsErrorRange)/1.394*0.03;
            cellStringDrop = diff(rmsErrorRange)/1.394*0.06;

            maxAcross = separation*iAlternativeModel + max(bestPositionOutOfSampleErrors(:)) - separationOffset ;
            maxDrop = maxAcross - separationOffset ;

            if (testPassed == 1)
                plot([x2(1) x2(iAlternativeModel)], maxAcross*[1 1], 'k-', 'LineWidth', 1.5);
                plot(x2(1)*[1 1], [maxAcross maxDrop], 'k-', 'LineWidth', 1.5);
                plot(x2((iAlternativeModel))*[1 1], [maxAcross maxDrop], 'k-', 'LineWidth', 1.5);
                text(x2(1)+0.3, maxAcross-textDrop, sprintf('p = %2.3f', pVal), 'FontSize', 14);
            end

        end

        grid(ax, 'on');
        xtickangle(0);
        legend(ax,[barHandle1 barHandle2], {'training', 'cross-validated'}, 'Location', 'NorthOutside', 'Orientation', 'Horizontal');
        legend(ax, 'boxoff');
        ylabel(ax, 'rms error');
        
        text(ax, 0.65, rmsErrorRange(2)-cellStringDrop, cellString, 'FontSize', 24, 'FontWeight', 'Bold')
        
end


function [bestPositionInSampleErrors,  bestPositionOutOfSampleErrors, hypothesisLabel] = ...
    plotCrossValidationErrorsAtAllPositions(ax, inSampleErrors,outOfSampleErrors, ...
    centerConesSchema, residualDefocusDiopters, noXLabel, noYLabel, rmsErrorRange)

     positionsNum = size(inSampleErrors,2);
     medianInSampleErrorForEachPosition = zeros(1, positionsNum);
     medianOutOfSampleErrorForEachPosition = zeros(1, positionsNum);
     

    % Compute median out of sample errors for each position examined
     for iPos = 1:positionsNum
         inSampleErrorsForThisPosition = squeeze(inSampleErrors(:, iPos));
         medianInSampleErrorForEachPosition(iPos) = mean(inSampleErrorsForThisPosition(:));
         outOfSampleErrorsForThisPosition = squeeze(outOfSampleErrors(:, iPos,:));
         medianOutOfSampleErrorForEachPosition(iPos) = mean(outOfSampleErrorsForThisPosition(:));
     end


     % Find the position with the min median error
     [~, bestPosition] = min(medianOutOfSampleErrorForEachPosition);


     bestPositionInSampleErrors = squeeze(inSampleErrors(:, bestPosition));
     bestPositionOutOfSampleErrors = squeeze(outOfSampleErrors(:, bestPosition,:));
     bestPositionOutOfSampleErrors = bestPositionOutOfSampleErrors(:);

     % Plot rms errors
     positionIndices = 1:positionsNum;
     
     c1 = [1 0.7 0.1];
     c2 = [0.1 0.7 1.0];

     p1 = plot(ax,positionIndices, medianInSampleErrorForEachPosition,  'o-', ...
         'MarkerSize', 14, 'MarkerFaceColor', c1, 'MarkerEdgeColor', c1*0.5, 'LineWidth', 1.5); 
     hold(ax, 'on');
     p2 = plot(ax,positionIndices, medianOutOfSampleErrorForEachPosition,  'bo-', ...
         'MarkerSize', 14, 'MarkerFaceColor', c2, 'MarkerEdgeColor', c2*0.5, 'LineWidth', 1.5);
     
     plot(ax,bestPosition, medianInSampleErrorForEachPosition(bestPosition),  's', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', c1*0.5, 'LineWidth', 1.5);
     plot(ax,bestPosition, medianOutOfSampleErrorForEachPosition(bestPosition),  's', ...
         'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', c2*0.5, 'LineWidth', 1.5);
     hold(ax, 'off')
     
     if (~noXLabel)
        xlabel(ax,'mosaic position index');
     end

     if (~noYLabel)
         ylabel(ax,'rms error');
     else
         set(ax, 'YTickLabel', {})
     end

     
     legend(ax,[p1 p2], {'training', 'cross-validated'})
     if (strcmp(centerConesSchema, 'variable'))
         hypothesisLabel = sprintf('1+ cone center\\newlinedefocus:%0.3fD', residualDefocusDiopters);
     else
        hypothesisLabel = sprintf('1 cone center\\newlinedefocus:%0.3fD', residualDefocusDiopters);
     end

     title(ax,hypothesisLabel)
     axis(ax,'square')
     set(ax, 'XLim', [0.5 numel(positionIndices)+0.5], 'YLim', rmsErrorRange, 'YTick', 0:0.2:4, 'XTick', 0:1:200);
     set(ax, 'FontSize', 18);
     grid(ax, 'on')
     box(ax, 'off')
     
end

function fillBetweenLines(ax, x,y1,y2,fillColor)
    hold(ax, 'on');
    patch([x fliplr(x)], [y1 fliplr(y2)], [0 0 0],'FaceColor', fillColor, 'EdgeColor', fillColor, 'FaceAlpha', 0.5, 'LineWidth', 1.0, 'Parent', ax);
end
