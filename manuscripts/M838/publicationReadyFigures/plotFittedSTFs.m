function plotFittedSTFs()
    % Plot the single-cone RF center / 0.067D residual defocus model fit
    % for all the cells STFs
    % Monkey to employ
    monkeyID = 'M838';

    % Get all recorded RGC infos
    %[centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    % Group RGCs, so that low-pass ones appear in 5th column
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);

    % Single residual defocus for all cells
    residualDefocusDioptersExamined = 0.067;

    % Optimal residua defocus for each cell
    %residualDefocusDioptersExamined = -99;

    % Monochromatic stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
    options.stimulusParams = simulator.params.AOSLOStimulus();

    dStruct = simulator.load.fluorescenceSTFdata(monkeyID);
    options.stimulusParams.STFspatialFrequencySupport = dStruct.spatialFrequencySupport;



    % Set the cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);


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

    % Plot raw data for each cell
    for iRGCindex = 1:numel(coneRGCindices) 
            operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'meanOverSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            if (residualDefocusDioptersExamined == -99)
                % Optimal residual defocus for each cell
                operationOptions.residualDefocusDiopters = ...
                        simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                        sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));
            else
               % Examined residual defocus
               operationOptions.residualDefocusDiopters = residualDefocusDioptersExamined;
            end

            % Choose which optics scenario to run.
            operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
            options.opticsParams = struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', operationOptions.residualDefocusDiopters, ...
                'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
                'wavelengthSupport', options.stimulusParams.wavelengthSupport);


            operationOptions.rmsSelector = 'unweighted';
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

            row = floor((iRGCindex-1)/5)+1;
            col = mod(iRGCindex-1,5)+1;
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

            cellIDString = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType, operationOptions.STFdataToFit.whichRGCindex);
            cellIDString = sprintf('RGC %d', iRGCindex);


            fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
                operationOptions.coneMosaicSamplingParams, ...
                operationOptions.fitParams, ...
                operationOptions.STFdataToFit);

            load(fittedModelFileName, 'STFdataToFit', 'theConeMosaic', 'fittedModels');
            theRFcenterConePoolingScenario = 'single-cone';
            visualizedModelFits = fittedModels(theRFcenterConePoolingScenario);
            bestConePosIdx = simulator.analyze.bestConePositionAcrossMosaic(visualizedModelFits, operationOptions.STFdataToFit, operationOptions.rmsSelector);

            simulator.visualize.fittedSTF(hFig, axSTF, ...
                STFdataToFit.spatialFrequencySupport, ...
                STFdataToFit.responses, ...
                [], ...
                visualizedModelFits{bestConePosIdx}.fittedSTF, ...
                [], false, ...
                noXLabel, noYLabel, cellIDString);
            drawnow;
    end


    % Each cell in separate figure
    for iRGCindex = 4 % %1:numel(coneRGCindices) 
            STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'allSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            hFig = figure(100+iRGCindex); clf;
            set(hFig, 'Color', [1 1 1], 'Position', [10 10 300 300]);
            axSTF = subplot('Position', [0.23 0.20 0.78*0.7 0.83*0.7]);

            noXLabel = false;
            noYLabel = false;

            cellIDString = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
            cellIDString = sprintf('RGC %d', iRGCindex);
            cellIDString = '';
            simulator.visualize.fittedSTF(hFig, axSTF, ...
                STFdataToFit.spatialFrequencySupport, ...
                mean(STFdataToFit.responses,3), ...
                [], ...
                [], [], false, ...
                noXLabel, noYLabel, cellIDString);
            drawnow;
            
    end
    
end

