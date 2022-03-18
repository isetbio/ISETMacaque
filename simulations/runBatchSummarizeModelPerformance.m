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
    residualDefocusDiopterValuesExamined = [0.00 0.042 0.047 0.067];

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

    for iRGCindex = 1:numel(coneRGCindices)
        
        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                 'whichSession', 'meanOverSessions', ...
                 'whichCenterConeType', coneTypes{iRGCindex}, ...
                 'whichRGCindex', coneRGCindices(iRGCindex));
        
        for iResidualDefocus = 1:numel(residualDefocusDiopterValuesExamined)

            operationOptions.residualDefocusDiopters = residualDefocusDiopterValuesExamined(iResidualDefocus);
            fprintf('Extracting performance for cell %d (defocus:%2.3fD)\n', iRGCindex, operationOptions.residualDefocusDiopters);
            
            % Get model performance at best cone position
            modelPerformance = simulator.performOperation(operation, operationOptions, monkeyID);

            % Single-cone RF models with different residual defocus values
            singleConeModelPerformance(iRGCindex, iResidualDefocus) = modelPerformance('single-cone');

            % Multi-cone RF models with different residual defocus values
            multiConeModelPerformance(iRGCindex, iResidualDefocus) = modelPerformance('multi-cone');
        end
    end

    group1cells = [3 4 6 9 10 11 12 5];
    group2cells = [14 15 2 1 7 8 13 ];

    
    generateGroupedCellsFigure(group1cells, residualDefocusDiopterValuesExamined, ...
        singleConeModelPerformance, multiConeModelPerformance, ...
        coneTypes, coneRGCindices, ...
        'summaryModelPerformanceDependenceOnResidualDefocusGroup1.pdf');

    generateGroupedCellsFigure(group2cells, residualDefocusDiopterValuesExamined, ...
        singleConeModelPerformance, multiConeModelPerformance, ...
        coneTypes, coneRGCindices, ...
        'summaryModelPerformanceDependenceOnResidualDefocusGroup2.pdf');
end


function generateGroupedCellsFigure(groupedCellIndices, residualDefocusDiopterValuesExamined, ...
        singleConeModelPerformance, multiConeModelPerformance, ...
        coneTypes, coneRGCindices, pdfFileName)
    
    % Set-up figure layout
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 8, ...
       'rowsNum', 2, ...
       'heightMargin',  0.05, ...
       'widthMargin',    0.03, ...
       'leftMargin',     0.03, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    % Plot model performance as a function of residual defocus for group1 cells
    hFig = figure();
    set(hFig, 'Position', [1 200 1990 650], 'Color', [1 1 1]);

    for k = 1:numel(groupedCellIndices)
        iRGCindex = groupedCellIndices(k);
        
        rmsRange(1) = min([min(singleConeModelPerformance(iRGCindex,:),[],2) min(multiConeModelPerformance(iRGCindex,:),[],2)]);
        rmsRange(2) = max([max(singleConeModelPerformance(iRGCindex,:),[],2) max(multiConeModelPerformance(iRGCindex,:),[],2)]);
        
        ax = subplot('Position', subplotPosVectors(1, k).v);
        cellIDstring = sprintf('%s%d (1 cone RF center)', coneTypes{iRGCindex}, coneRGCindices(iRGCindex));
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, ...
            singleConeModelPerformance(iRGCindex,:), rmsRange, cellIDstring, k);
        
        ax = subplot('Position', subplotPosVectors(2, k).v);
        cellIDstring = sprintf('%s%d (1+ cone RF center)', coneTypes{iRGCindex}, coneRGCindices(iRGCindex));
        plotRMSErrors(ax, residualDefocusDiopterValuesExamined, ...
            multiConeModelPerformance(iRGCindex,:), rmsRange, cellIDstring, k);
        drawnow;
    end
    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);

end


function plotRMSErrors(ax, residualDefocusDiopterValuesExamined, modelPerformance, rmsRange, cellIDstring, iRGCindex)
        
    bar(ax,1:numel(residualDefocusDiopterValuesExamined), modelPerformance,1, ...
        'FaceColor',[1.0 .6 .1],'EdgeColor',[.3 .1 .0],'LineWidth',1.0);
    axis(ax, 'square');
    
    if (iRGCindex > 1)
    else
        ylabel(ax, 'RMSE');
    end
    set(ax, 'YLim', [rmsRange(1)-0.005 rmsRange(2)+0.005], 'YTick', 0.0:0.01:0.1, 'FontSize', 16);
    set(ax, 'XTick', 1:1:numel(residualDefocusDiopterValuesExamined), ...
            'XTickLabel', sprintf('%0.3f\n', residualDefocusDiopterValuesExamined), ...
            'XLim', [0 numel(residualDefocusDiopterValuesExamined)+1.0])
    xlabel(ax,'residual defocus (D)', 'FontSize', 20)
    xtickangle(ax, 90);
    title(ax,cellIDstring);
    box(ax, 'off');
    grid(ax, 'on')

end

