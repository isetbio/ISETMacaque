function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 512;

    targetLcenterRGCindices = [11]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
    targetMcenterRGCindices = []; % [1 2 4];   % the non-low pass cells


    % Run the signed response model variant
    accountForResponseOffset = ~true;
    accountForResponseSignReversal = ~true;


    %operationMode = 'fitModelOnSessionAveragedData';
    operationMode = 'fitModelOnSingleSessionData';
    %operationMode = 'crossValidateFittedModelOnSingleSessionData';
    %perationMode = 'crossValidateFittedModelOnAllSessionData';


    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        hFig = figure(1000); clf;
        set(hFig, 'Position', [100 800 1500 400], 'Color', [1 1 1]);
    end


    % Hypothesis 1
    centerConesSchema =  'single';      % single-cone RF center
    residualDefocusDiopters = 0.000;    % zero residual defocus

    [inSampleErrors(1,:,:),outOfSampleErrors(1,:,:,:)] = batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum, operationMode);

    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        [meanInSampleErrorAcrossAllPositions(1), meanOutOfSampleErrorAcrossAllPositions(1), ...
         stdInSampleErrorAcrossAllPositions(1), stdOutOfSampleErrorAcrossAllPositions(1), ...
         hypothesisLabels{1}] = ...
        plotCrossValidationErrors(hFig, 1, squeeze(inSampleErrors(1,:,:)), squeeze(outOfSampleErrors(1,:,:)), ...
        centerConesSchema, residualDefocusDiopters);
    end

    % Hypothesis 2
    centerConesSchema =  'single';      % single-cone RF center
    residualDefocusDiopters = 0.067;    % 0.067D residual defocus
    
    [inSampleErrors(2,:,:),outOfSampleErrors(2,:,:,:)] = batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum, operationMode);

    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        [meanInSampleErrorAcrossAllPositions(2), meanOutOfSampleErrorAcrossAllPositions(2), ...
         stdInSampleErrorAcrossAllPositions(2), stdOutOfSampleErrorAcrossAllPositions(2), ...
         hypothesisLabels{2}] = ...
            plotCrossValidationErrors(hFig, 2, squeeze(inSampleErrors(2,:,:)), squeeze(outOfSampleErrors(2,:,:)), ...
            centerConesSchema, residualDefocusDiopters);
    end


    % Hypothesis 3
    centerConesSchema =  'variable';   % multiple-cones in RF center
    residualDefocusDiopters = 0.000;   % zero residual defocus
    
    [inSampleErrors(3,:,:),outOfSampleErrors(3,:,:,:)] = batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum, operationMode);

    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        [meanInSampleErrorAcrossAllPositions(3), meanOutOfSampleErrorAcrossAllPositions(3), ...
         stdInSampleErrorAcrossAllPositions(3), stdOutOfSampleErrorAcrossAllPositions(3), ...
         hypothesisLabels{3}] = ...
            plotCrossValidationErrors(hFig, 3, squeeze(inSampleErrors(3,:,:)), squeeze(outOfSampleErrors(3,:,:)), ...
            centerConesSchema, residualDefocusDiopters);
    end


    % Hypothesis 4
    centerConesSchema =  'variable';   % multiple-cones in RF center
    residualDefocusDiopters = 0.067;   % 0.067D residual defocus
    
    [inSampleErrors(4,:,:),outOfSampleErrors(4,:,:,:)] = batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum, operationMode);

    if (strcmp(operationMode,  'crossValidateFittedModelOnAllSessionData'))
        [meanInSampleErrorAcrossAllPositions(4), meanOutOfSampleErrorAcrossAllPositions(4), ...
         stdInSampleErrorAcrossAllPositions(4), stdOutOfSampleErrorAcrossAllPositions(4), ...
         hypothesisLabels{4}] = ...
            plotCrossValidationErrors(hFig, 4, squeeze(inSampleErrors(4,:,:)), squeeze(outOfSampleErrors(4,:,:)), ...
            centerConesSchema, residualDefocusDiopters);
    
        
        figure(1001);
        subplot(1,2,1);
        bar(1:4, meanInSampleErrorAcrossAllPositions, 1); hold on
        er = errorbar(1:4, meanInSampleErrorAcrossAllPositions, stdInSampleErrorAcrossAllPositions, stdInSampleErrorAcrossAllPositions);  
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  

        set(gca, 'XTick', 1:4, 'XTickLabel', hypothesisLabels, 'FontSize', 14, 'YLim', [0.03 0.07]);
        xlabel('model');
        ylabel('rmsE (average across positions)')
        title('in sample');

        subplot(1,2,2);
        bar(1:4, meanOutOfSampleErrorAcrossAllPositions, 1); hold on
        er = errorbar(1:4, meanOutOfSampleErrorAcrossAllPositions,stdOutOfSampleErrorAcrossAllPositions, stdOutOfSampleErrorAcrossAllPositions);
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  
        set(gca, 'XTick', 1:4, 'XTickLabel', hypothesisLabels, 'FontSize', 14, 'YLim', [0.06 0.10]);
        xlabel('model');
        ylabel('rmsE (average across positions)')
        title('out of sample');
    end

end

function [meanInSampleErrorAcrossAllPositions, meanOutOfSampleErrorAcrossAllPositions, ...
    stdInSampleErrorAcrossAllPositions, stdOutOfSampleErrorAcrossAllPositions, hypothesisLabel] = ...
    plotCrossValidationErrors(hFig, subplotNo, inSampleErrors,outOfSampleErrors, centerConesSchema, residualDefocusDiopters)

     figure(hFig);
     subplot(1,4,subplotNo);
     % mean over test sessions
     outOfSampleErrorsMean = mean(outOfSampleErrors, 3);

     for examinedRFpositionIndex = 1:size(inSampleErrors,2)
         inSampleErrorsForThisPosition = inSampleErrors(:, examinedRFpositionIndex);
         outOfSampleErrorsForThisPosition = outOfSampleErrorsMean(:, examinedRFpositionIndex);
         % Mean over all training sessions
         meanInSampleErrorForThisPosition(examinedRFpositionIndex) = mean(inSampleErrorsForThisPosition);
         meanOutOfSampleErrorForThisPosition(examinedRFpositionIndex) = mean(outOfSampleErrorsForThisPosition);
     end

     meanInSampleErrorAcrossAllPositions = median(meanInSampleErrorForThisPosition(:));
     meanOutOfSampleErrorAcrossAllPositions = median(meanOutOfSampleErrorForThisPosition(:));
     stdInSampleErrorAcrossAllPositions = mad(meanInSampleErrorForThisPosition(:));
     stdOutOfSampleErrorAcrossAllPositions = mad(meanOutOfSampleErrorForThisPosition(:));


     rmsRange(1) = min([min(meanInSampleErrorForThisPosition(:)) min(meanOutOfSampleErrorForThisPosition(:))]);
     rmsRange(2) = max([max(meanInSampleErrorForThisPosition(:)) max(meanOutOfSampleErrorForThisPosition(:))]);

     positionIndices = 1:numel(meanInSampleErrorForThisPosition);
     plot(positionIndices, meanInSampleErrorForThisPosition,  'ro-', ...
         'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.5); hold on;
     plot(positionIndices, meanOutOfSampleErrorForThisPosition,  'bo-', ...
         'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
     xlabel('position index');
     ylabel('rms error');
     legend({'in-sample', 'out-of-sample'})
     hypothesisLabel = sprintf('%s center cone, defocus: %2.3fD', centerConesSchema, residualDefocusDiopters);
     title(hypothesisLabel)
     axis 'square'
     set(gca, 'XLim', [0 numel(positionIndices)+1], 'XTick', 0:1:200, 'YLim', [0.04 0.12], 'YTick', 0.00:0.01:0.1);
     set(gca, 'FontSize', 18);
     grid on

end
