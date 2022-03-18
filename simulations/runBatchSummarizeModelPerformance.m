function runBatchSummarizeModelPerformance
% Batch visualize the performance of all models
%
% Syntax:
%   runBatchVisualizeModelPerformance()
%
% Description:
%   Batch visualize the performance of all models
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    % Monkey to analyze
    monkeyID = 'M838';

    % Choose which optics scenario to run.
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % Monochromatic stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = ...
        {'single-cone', 'multi-cone'};

    % Examined residual defocus values
    residualDefocusDiopterValuesExamined = [0.00 0.042 0.067];

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


    % How to select the best cone position
    % choose between {'weighted', 'unweighted'} RMSE
    operationOptions.rmsSelector = 'unweighted';

    % Operation to run
    operation = simulator.operations.extractFittedModelPerformance;

    % Examined RGCs (all 11 L-center and 4 M-center)
    LconeRGCsNum  = 11;
    MconeRGCsNum = 4;
    coneTypes(1:LconeRGCsNum) = {'L'};
    coneTypes(LconeRGCsNum+(1:MconeRGCsNum)) = {'M'};
    coneRGCindices(1:LconeRGCsNum) = 1:LconeRGCsNum;
    coneRGCindices(LconeRGCsNum+(1:MconeRGCsNum)) = 1:MconeRGCsNum;

    % Set-up figure
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 8, ...
       'rowsNum', 2, ...
       'heightMargin',  0.03, ...
       'widthMargin',    0.02, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.02, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.02);

    
    for iRGCindex = 1:numel(coneRGCindices)

        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                 'whichSession', 'meanOverSessions', ...
                 'whichCenterConeType', coneTypes{iRGCindex}, ...
                 'whichRGCindex', coneRGCindices(iRGCindex));
        
        for iResidualDefocus = 1:numel(residualDefocusDiopterValuesExamined)
            % Get model performance at best cone position
            operationOptions.residualDefocusDiopters = residualDefocusDiopterValuesExamined(iResidualDefocus);
            modelPerformance = simulator.performOperation(operation, operationOptions, monkeyID);

            % Single-cone RF models with different residual defocus values
            singleConeModelPerformance(iRGCindex, iResidualDefocus) = modelPerformance('single-cone');

            % Multi-cone RF models with different residual defocus values
            multiConeModelPerformance(iRGCindex, iResidualDefocus) = modelPerformance('multi-cone');
        end
    end

    % Plot model performance as a function of residual defocus: cells 1-8
    hFig = figure();
    set(hFig, 'Position', [1 1 1600 600], 'Color', [1 1 1]);

    for iRGCindex = 1:8
        cellIDstring = sprintf('%s%d (single-cone)', coneTypes{iRGCindex}, coneRGCindices(iRGCindex));
        ax = subplot('Position', subplotPosVectors(1, iRGCindex).v);
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, singleConeModelPerformance(iRGCindex,:), cellIDstring, iRGCindex);
        
        ax = subplot('Position', subplotPosVectors(2, iRGCindex).v);
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, multiConeModelPerformance(iRGCindex,:), cellIDstring, iRGCindex);
        drawnow;
    end

    % Plot model performance as a function of residual defocus: cells 9-15
    hFig = figure();
    set(hFig, 'Position', [1 200 1600 600], 'Color', [1 1 1]);

    for iRGCindex = 9:15

        cellIDstring = sprintf('%s%d (single-cone)', coneTypes{iRGCindex}, coneRGCindices(iRGCindex));
        ax = subplot('Position', subplotPosVectors(1, iRGCindex).v);
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, singleConeModelPerformance(iRGCindex,:), cellIDstring, iRGCindex-8);
        
        ax = subplot('Position', subplotPosVectors(2, iRGCindex).v);
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, multiConeModelPerformance(iRGCindex,:), cellIDstring, iRGCindex-8);
        drawnow;
    end

end


function plotRMSErrors(ax, residualDefocusDiopterValuesExamined, modelPerformance, cellIDstring, iRGCindex)
        
    bar(ax,1:numel(residualDefocusDiopterValuesExamined), modelPerformance,1);
    axis(ax, 'square');
    set(ax, 'XTick', 1:numel(residualDefocusDiopterValuesExamined), ...
             'XTickLabel', sprintf('%0.3fD\n', residualDefocusDiopterValuesExamined));
    if (iRGCindex > 1)
        set(ax, 'YTickLabel', {});
    else
        ylabel(ax, 'RMSE');
    end
    set(ax, 'YLim', [0.01 0.05], 'YTick', 0.01:0.01:0.1, 'FontSize', 12);
    xlabel(ax,'residual defocus (D)')
    title(ax,cellIDstring);
    box(ax, 'off');
    grid(ax, 'on')

end

