function runModelCrossValidation
% Cross-validate different models

    % Monkey to employ
    monkeyID = 'M838';

    % Choose what operation to run.
    % Fit the cross-validation models for each session
    %operation = simulator.operations.fitCrossValidationModelsToFluorescenceSTFresponses;

    % OR Test the cross-validation models
    operation = simulator.operations.testCrossValidationModelsToFluoresceneSTFresponses;

    % Always use the monochromatic AO stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % The 4-optics scenarios for the 4 models to be cross-validated.
    operationOptions.opticsScenario = [...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus];

    % The residual defocus values for the 4 models to be cross-validated.
    residualDefocusDiopter = [...
        0.0 ...
        0.0 ...
        0.067 ...
        0.067]; 

    % RF center pooling scenarios for the 4 models to be cross-validated.
    operationOptions.rfCenterConePoolingScenariosExamined = { ...
        'single-cone' ...
        'multi-cone' ...
        'single-cone' ...
        'multi-cone'};

    % Select the spatial sampling within the cone mosaic
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options
    operationOptions.fitParams = struct(...
        'multiStartsNum', 512, ...
        'accountForNegativeSTFdata', true, ...
        'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
        );
    
    % Get all recorded RGC infos
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    % Just the low pass RGCs
    centerConeTypes = {'L', 'L', 'M'};
    coneRGCindices = [2 9 3];


    % Do the cross-validated fit for each cell
    for iRGCindex = 1:numel(coneRGCindices) 

        % Select all sessions (not the mean over sessions) and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'allSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));

        % Set operationOptions.residualDefocusDiopters for all models
        for iResidualDefocusIndex = 1:numel(residualDefocusDiopter)
            if (residualDefocusDiopter(iResidualDefocusIndex) == -99)
                operationOptions.residualDefocusDiopters(iResidualDefocusIndex) = ...
                    simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                       sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));

            else
                operationOptions.residualDefocusDiopters(iResidualDefocusIndex) = ...
                    residualDefocusDiopter(iResidualDefocusIndex);
            end
        end

        % All set, go!
        d = simulator.performOperation(operation, operationOptions, monkeyID);

        bestPositionInSampleErrors = d.inSampleErrors;
        bestPositionOutOfSampleErrors  = d.outOfSampleErrors;
        cellString = sprintf('%s%d', centerConeTypes{iRGCindex}, coneRGCindices(iRGCindex));

        for iModelScenario = 1:4
            hypothesisLabels{iModelScenario} = sprintf('    %s\\newlinedefocus:%2.3fD', ...
                operationOptions.rfCenterConePoolingScenariosExamined{iModelScenario}, ...
                residualDefocusDiopter(iModelScenario));
        end
        

        hFig = figure(1000+iRGCindex); clf
        set(hFig, 'Position', [10 10 1300 750], 'Color', [1 1 1]);
        width = 0.4/2*0.9;
        height = 0.8/2*0.9;
        widthMargin = 0.02;
        heightMargin = 0.14;
        for iModelScenario = 1:4
            % Errors as a function of cone position
            % Need to do this
            row = 1-floor((iModelScenario-1)/2);
            col = mod((iModelScenario-1),2);
            ax{iModelScenario} = subplot('Position', [0.05 + col*(width+widthMargin), 0.07 + row*(height+heightMargin) width height]);
        end
        axSummary = subplot('Position', [0.11+2*(width+widthMargin) 0.095 0.48 0.9]);
    
    
        plotCrossValidationErrors(axSummary, ...
                    10*bestPositionInSampleErrors, 10*bestPositionOutOfSampleErrors, ...
                    hypothesisLabels, cellString);
    end
    
end


function plotCrossValidationErrors(ax, ...
                bestPositionInSampleErrors, bestPositionOutOfSampleErrors, ...
                hypothesisLabels, cellString)
        
    rmsErrorRange(1) = min([min(bestPositionInSampleErrors(:)) min(bestPositionOutOfSampleErrors(:))]);
    rmsErrorRange(2) = max([max(bestPositionInSampleErrors(:)) max(bestPositionOutOfSampleErrors(:))]);
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
            yTicks = 0:0.25:rmsErrorRange(2);
        else
            yTicks = 0:1:rmsErrorRange(2);
        end

        modelScenarios = 1:numel(hypothesisLabels);

        c1 = [1 0.7 0.1];
        c2 = [0.1 0.7 1.0];

        x1 = modelScenarios-0.2;
        x2 = modelScenarios+0.2;
        y1 = (mean(bestPositionInSampleErrors, 2))';
        y2 = (mean(bestPositionOutOfSampleErrors, 2))';

        min(y1(:))
        min(y2(:))
        max(y1(:))
        max(y2(:))

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

        set(ax, 'YTick', yTicks, 'XTick', 1:4, 'XLim', [0.5 4.5], 'XTickLabel', hypothesisLabels, 'FontSize', 20, ...
            'YLim', rmsErrorRange);
        
        
        
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