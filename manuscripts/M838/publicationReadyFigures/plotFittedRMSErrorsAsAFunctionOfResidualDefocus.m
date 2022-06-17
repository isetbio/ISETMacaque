function plotFittedRMSErrorsAsAFunctionOfResidualDefocus

    % Monkey to employ
    monkeyID = 'M838';

    % Group RGCs, so that low-pass ones appear in 5th column
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);


    % Choose which optics scenario to run.
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % Monochromatic stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = {'multi-cone'};
 

    % Examined residual defocus values
    residualDefocusDiopterValuesExamined = [0 0.042 0.057 0.062 0.067 0.072 0.077 0.082];

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

    % How to select the best cone position
    % choose between {'weighted', 'unweighted'} RMSE
    operationOptions.rmsSelector = 'unweighted';

    % Operation to run
    operation = simulator.operations.extractFittedModelPerformance;


    % All cells in same figure
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1100 660]);  

    % Set-up figure
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 5, ...
       'rowsNum', 3, ...
       'heightMargin',  0.05, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.07, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.1, ...
       'topMargin',      0.0);

    for iRGCindex = 1:numel(coneRGCindices)
        
        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                 'whichSession', 'meanOverSessions', ...
                 'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                 'whichRGCindex', coneRGCindices(iRGCindex));
        
        for iResidualDefocus = 1:numel(residualDefocusDiopterValuesExamined)
            if (residualDefocusDiopterValuesExamined(iResidualDefocus) == -99)
                % Optimal residual defocus for each cell
                operationOptions.residualDefocusDiopters = ...
                    simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                    sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));
            else
                % Examined residual defocus
                operationOptions.residualDefocusDiopters = residualDefocusDiopterValuesExamined(iResidualDefocus);
            end

            % Get model performance at best cone position
            fprintf('Extracting performance for cell %d (defocus:%2.3fD)\n', iRGCindex, operationOptions.residualDefocusDiopters);
            modelPerformance = simulator.performOperation(operation, operationOptions, monkeyID);

            modelPerformanceAsAFunctionOfResidualDefocus(iResidualDefocus) = modelPerformance(operationOptions.rfCenterConePoolingScenariosExamined{1});
        end

        

        row = floor((iRGCindex-1)/5)+1;
        col = mod(iRGCindex-1,5)+1;
        ax = subplot('Position', subplotPosVectors(row,col).v);

        if (row < 3)
            noXLabel = true;
        else
            noXLabel = false;
        end

        if (col > 1)
            noYLabel = true;
        else
            noYLabel = false;
        end

        cellIDString = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType, operationOptions.STFdataToFit.whichRGCindex);
        cellIDString = sprintf('RGC %d', iRGCindex);


        rmsRange(1) = 0.02;
        rmsRange(2) = 0.08; %max(modelPerformanceAsAFunctionOfResidualDefocus(:));
       
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, ...
            modelPerformanceAsAFunctionOfResidualDefocus, rmsRange, cellIDString, noXLabel, noYLabel);

    end % iRGCindex


    % Export figure
    p = getpref('ISETMacaque');
    populationPDFsDir = sprintf('%s/exports/populationPDFs',p.generatedDataDir);
    pdfFileName = sprintf('%s/modelSelection/RMSEs_%s.pdf', populationPDFsDir, operationOptions.rfCenterConePoolingScenariosExamined{1});
    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);

end


function plotRMSErrors(ax, residualDefocusDiopterValuesExamined, modelPerformance, rmsRange, cellIDstring, noXLabel, noYLabel)
        
    bar(ax,1:numel(residualDefocusDiopterValuesExamined), modelPerformance,1, ...
        'FaceColor',[1.0 .6 .1],'EdgeColor',[.3 .1 .0],'LineWidth',1.0);
    axis(ax, 'square');
    

    

    yTicks = 0.0:0.01:0.2;
    set(ax, 'YLim', [rmsRange(1)-0.005 rmsRange(2)+0.005], 'YTick', yTicks, 'FontSize', 16);
    set(ax, 'YTickLabel', strrep(sprintf('%.3f\n', yTicks), '0.', '.'))
    set(ax, 'XTick', 1:1:numel(residualDefocusDiopterValuesExamined), ...
            'XTickLabel', strrep(sprintf('%.3f\n', residualDefocusDiopterValuesExamined), '0.', '.'), ...
            'XLim', [0 numel(residualDefocusDiopterValuesExamined)+1.0])
    xtickangle(ax, 90);
    text(ax, 0.7, rmsRange(2)+0.003, cellIDstring, 'FontSize', 12);

    if (~noYLabel)
        ylabel(ax, 'RMSE');
    else
        set(ax, 'YTickLabel', {});
    end

    if (~noXLabel)
        xlabel(ax, 'residual defocus (D)');
    else
        set(ax, 'XTickLabel', {});
    end

    box(ax, 'off');
    grid(ax, 'on');
    drawnow;
end