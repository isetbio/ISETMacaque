function plotSynthesizedSTFs()

    % Monkey to employ
    monkeyID = 'M838';

    % Simulated condition to use - physiological optics, CRT achromatic stimuli
    simulatedCondition = 'CRT';

    % Simulated condition to use - AOSO optics with various residual defocus, monochromatic stimuli
    %simulatedCondition = 'AOSLO';
    simulatedCondition = 'AOSLOresidualDefocus0067'
    %simulatedCondition = 'AOSLOresidualDefocusOptimal'

    % Choose what operation to run.
    operation = simulator.operations.computeSynthesizedRGCSTFresponses;

    switch (simulatedCondition)
        case 'AOSLO'
            operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
            operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
            residualDefocusDioptersExamined = 0.0;
            
        case 'AOSLOresidualDefocus0067'
            operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
            operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
            residualDefocusDioptersExamined  = 0.067;

        case 'AOSLOresidualDefocusOptimal'
            operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
            operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
            residualDefocusDioptersExamined  = -99;

        case 'CRT'
            operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;
            % M838 physiological optics with 2.5 mm pupil
            operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
            operationOptions.pupilSizeMM = 2.5;

            % Residual defocus for the employed model
            residualDefocusDioptersExamined = 0.067;
    end


    % Select the spatial sampling within the cone mosaic
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea". This must match what was
    % specified in runBatchFit()
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...     % select cones within the central 6 arc min
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options - this will select which RGC model to employ
    operationOptions.fitParams = struct(...
         'multiStartsNum', 512, ...
         'accountForNegativeSTFdata', true, ...
         'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
         );

    % Get the grouped RGC infos
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);


    % All cells in same figure
    hFigAllCells = figure(100); clf;
    set(hFigAllCells, 'Color', [1 1 1], 'Position', [10 10 1100 660]);  

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

    % Plot raw data for each cell
    for iRGCindex = 1:numel(coneRGCindices) 
            operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'meanOverSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            
            if (residualDefocusDioptersExamined == -99)
                % Optimal residual defocus for each cell
                residualDefocusForModel = ...
                        simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                        sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));
            else
               % Examined residual defocus
               residualDefocusForModel = residualDefocusDioptersExamined;
            end

            operationOptions.residualDefocusDiopters = residualDefocusForModel;

            operationOptions.syntheticSTFtoFit = 'compositeCenterSurroundResponseBased';
            operationOptions.syntheticSTFtoFitComponentWeights = struct(...
                'center', 0, ...
                'surround', 0, ...
                'composite', 1);

            % Params used to derive the (single-cone center)RGC model. 
            % The important parameter here is the residualDefocus assumed
            operationOptions.syntheticRGCmodelParams = struct(...
                'opticsParams', struct(...
                    'type', simulator.opticsTypes.diffractionLimited, ...
                    'residualDefocusDiopters', residualDefocusForModel), ...
                'stimulusParams', struct(...
                    'type', simulator.stimTypes.monochromaticAO), ...
                'cMosaicParams', struct(...
                    'coneCouplingLambda', 0.0), ...
                'rfCenterConePoolingScenario', 'single-cone', ...
                'rmsSelector', 'unweighted'...
              );

            dataOut{iRGCindex} = simulator.performOperation(operation, operationOptions, monkeyID);

            % Extract the compute responses and the model fit to them
            d = dataOut{iRGCindex};
            synthesizedResponses = d.syntheticSTFdataStruct.val;
            modelResponses = zeros(1,numel(synthesizedResponses));
            for k = 1:numel(synthesizedResponses)
                theTestedSF = d.syntheticSTFdataStruct.sf(k);
                [~,idx] = min(abs(d.modelSyntheticSTFdataStruct.sf-theTestedSF));
                modelResponses(k) = d.modelSyntheticSTFdataStruct.val(idx);
            end
            

            row = floor((iRGCindex-1)/5)+1;
            col = mod(iRGCindex-1,5)+1;
            figure(hFigAllCells);
            axSTF = subplot('Position', subplotPosVectors(row,col).v);

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

            %cellIDString = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType, operationOptions.STFdataToFit.whichRGCindex);
            cellIDString = sprintf('RGC %d', iRGCindex);
            cellIDString = '';
            
            simulator.visualize.fittedSTF(hFigAllCells, axSTF, ...
                operationOptions.STFdataToFit.spatialFrequencySupport, synthesizedResponses, [],...
                modelResponses, [],  ...
                false, cellIDString, ...
                'noXLabel', noXLabel, ...
                'noYLabel', noYLabel, ...
                'yAxisScaling', 'log');

            if (strcmp(simulatedCondition, 'CRT'))
                % Change the y-scale
                set(axSTF, 'YLim', [0.02 0.2]);
                % And the y-label, no more fluorescence
                if (col == 1)
                    ylabel(axSTF, 'modulation');
                end
            end

            drawnow;

            % Now each cell in separate figure
            hFigSeparate = figure(100+iRGCindex); clf;
            set(hFigSeparate, 'Color', [1 1 1], 'Position', [10 10 300 300], ...
                'Name', sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType, operationOptions.STFdataToFit.whichRGCindex));
            axSTFseparate = subplot('Position', [0.23 0.20 0.78*0.7 0.83*0.7]);

            noXLabel = false;
            noYLabel = false;
            cellIDString = '';
            simulator.visualize.fittedSTF(hFigSeparate, axSTFseparate, ...
                operationOptions.STFdataToFit.spatialFrequencySupport, synthesizedResponses, [],...
                modelResponses, [],  ...
                false, cellIDString, ...
                'noXLabel', noXLabel, ...
                'noYLabel', noYLabel, ...
                'yAxisScaling', 'log');

            if (strcmp(simulatedCondition, 'CRT'))
                % Change the y-scale
                set(axSTFseparate, 'YLim', [0.02 0.2]);
                % And the y-label, no more fluorescence
                ylabel(axSTFseparate, 'modulation');
            end

            drawnow;

    end
    
end

