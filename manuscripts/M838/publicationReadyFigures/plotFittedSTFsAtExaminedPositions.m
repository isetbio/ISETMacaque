function plotFittedSTFsAtExaminedPositions()

    % Monkey to employ
    monkeyID = 'M838';

    % Get all recorded RGC infos
    %[centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    % Group RGCs, so that low-pass ones appear in 5th column
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);

    % Single residual defocus for all cells
    residualDefocusDioptersExamined = 0.067;

    % Optimal residual defocus for each cell
    %residualDefocusDioptersExamined = 0;

    % Optimal residual defocus for each cell
    %residualDefocusDioptersExamined = -99;

    % RF center scenario : choose between 'single-cone' and 'multi-cone'
    theRFcenterConePoolingScenario = 'single-cone';

    % Monochromatic stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
    options.stimulusParams = simulator.params.AOSLOStimulus();

    % Load spatial frequencies examined
    dStruct = simulator.load.fluorescenceSTFdata(monkeyID);
    options.stimulusParams.STFspatialFrequencySupport = dStruct.spatialFrequencySupport;


    % The STF as measured
    visualizedComponent = 'STF';

    % The STF of the neuron (no optics)
    %visualizedComponent = 'NeuralSTF';

    % The neuron's RF profile
    %visualizedComponent = 'RFprofile';


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
    rowsNum = 2;
    colsNum = 4;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', colsNum, ...
       'rowsNum', rowsNum, ...
       'heightMargin',  0.05, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.07, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.1, ...
       'topMargin',      0.0);


    iRGCindex = 11;

  
    operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
        'whichSession', 'meanOverSessions', ...
        'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
        'whichCenterConeType', centerConeTypes{iRGCindex}, ...
        'whichRGCindex', coneRGCindices(iRGCindex));

    if (residualDefocusDioptersExamined == -99)
        % Optimal residual defocus for each cell
        operationOptions.residualDefocusDiopters = ...
            simulator.animalInfo.optimalResidualDefocus(monkeyID, ...
            sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex), ...
            theRFcenterConePoolingScenario);
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

    % Load fitted models
    fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
        operationOptions.coneMosaicSamplingParams, ...
        operationOptions.fitParams, ...
        operationOptions.STFdataToFit);

    load(fittedModelFileName, 'STFdataToFit', 'theConeMosaic', 'fittedModels');

    % Select the positions of the cones driving the center of the model RGCs
    rfCenterConeIndices = simulator.coneMosaic.indicesOfConesOfSpecificTypeWithinEccRange(...
        theConeMosaic, STFdataToFit.whichCenterConeType, operationOptions.coneMosaicSamplingParams);

    visualizedModelFits = fittedModels(theRFcenterConePoolingScenario);

    cellIDString = sprintf('RGC %d (%s%d)', iRGCindex, operationOptions.STFdataToFit.whichCenterConeType, operationOptions.STFdataToFit.whichRGCindex);

    bestConePosIdx = simulator.analyze.bestConePositionAcrossMosaic(...
        visualizedModelFits, operationOptions.STFdataToFit, ...
        operationOptions.rmsSelector);
     
    for iPosIndex = 1:numel(visualizedModelFits)
  
            row = floor((iPosIndex -1)/colsNum)+1;
            col = mod(iPosIndex-1,colsNum)+1;
            axSTF = subplot('Position', subplotPosVectors(row,col).v);

            if (row < rowsNum)
                noXLabel = true;
            else
                noXLabel = false;
            end

            if (col > 1)
                noYLabel = true;
            else
                noYLabel = false;
            end

            if (iPosIndex == bestConePosIdx)
                rmseString = sprintf('RMSE: %2.3f (*)',visualizedModelFits{iPosIndex}.fittedRMSE);
            else
                rmseString = sprintf('RMSE: %2.3f',visualizedModelFits{iPosIndex}.fittedRMSE);
            end

            switch (visualizedComponent)
                case 'STF'
                    simulator.visualize.fittedSTF(hFig, axSTF, ...
                        STFdataToFit.spatialFrequencySupport, ...
                        STFdataToFit.responses, ...
                        [], ...
                        visualizedModelFits{iPosIndex}.fittedSTF, ...
                        [], false, ...
                        rmseString, ...
                        'noXLabel', noXLabel, ...
                        'noYLabel', noYLabel);

                case 'NeuralSTF'
                    coneRcDegs = sqrt(2) * 0.204 * min(theConeMosaic.coneRFspacingsDegs);
                    spatialSupport = linspace(0, 40*coneRcDegs, 128);
                    spatialSupport = spatialSupport - mean(spatialSupport);
                    rfParams = visualizedModelFits{bestConePosIdx}.fittedRGCRF;
                    [centerProfile, surroundProfile, spatialSupportX, ...
                     centerSTF, surroundSTF, sfSupport] = generateRFprofiles(theConeMosaic, rfParams, spatialSupport);

                    fittedNeuralSTFcomponents.sfSupport = sfSupport;
                    fittedNeuralSTFcomponents.center =   centerSTF;
                    fittedNeuralSTFcomponents.surround = surroundSTF;
                    fittedNeuralSTFcomponents.responses = abs(fittedNeuralSTFcomponents.center - fittedNeuralSTFcomponents.surround);
                 
                    simulator.visualize.fittedSTF(hFig, axSTF, ...
                        STFdataToFit.spatialFrequencySupport, ...
                        STFdataToFit.responses, ...
                        [], ...
                        visualizedModelFits{bestConePosIdx}.fittedSTF, ...
                        [], false, ...
                        rmseString, ...
                        'fittedNeuralSTFcomponents', fittedNeuralSTFcomponents, ...
                        'noXLabel', noXLabel, ...
                        'noYLabel', noYLabel);


                case 'RFprofile'
                    noXLabel = true;
                    noYLabel = true;
                    if (row == 3)
                        noXLabel = false;
                    end
                    if (col == 1)
                        noYLabel = false;
                    end
                    
                    simulator.visualize.fittedRGCRF(hFig, [], [], axSTF, ...
                        theConeMosaic, visualizedModelFits{bestConePosIdx}.fittedRGCRF, ...
                        rmseString, ...
                        noXLabel, noYLabel, false);

            end% switch

            drawnow;
    end % iPosIndex
    
    ax = subplot('Position', subplotPosVectors(rowsNum,colsNum).v);
    theConeMosaic.visualize( ...
        'figureHandle', hFig,...
        'axesHandle', ax, ...
        'domain', 'microns', ...
        'domainVisualizationLimits', [-30 30 -30 30], ...
        'domainVisualizationTicks', struct('x', -30:15:30, 'y', -30:15:30), ...
        'labelConesWithIndices', rfCenterConeIndices, ...
        'fontSize', 14);

    % Export figure
    p = getpref('ISETMacaque');
    populationPDFsDir = sprintf('%s/exports/populationPDFs',p.generatedDataDir);
    if (residualDefocusDioptersExamined == -99)
        residualDefocusDescriptor = 'CellSpecificResidualDefocus';
    else
        residualDefocusDescriptor = sprintf('%2.3fDResidualDefocus', residualDefocusDioptersExamined);
    end

    pdfFileName = sprintf('%s/fittedSTFs/%s_%s_%s_%s.pdf', populationPDFsDir, visualizedComponent, cellIDString, theRFcenterConePoolingScenario, residualDefocusDescriptor);
    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);


    if (1==2)
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
                cellIDString, ...
                'noXLabel', noXLabel, ...
                'noYLabel', noYLabel);
            drawnow;
            
        end

    end

    
end

function [centerProfile, surroundProfile, spatialSupportX, ...
          centerSTF, surroundSTF, frequencySupport] = generateRFprofiles(theConeMosaic, rfParams, spatialSupport)

    spatialSupportX = spatialSupport + theConeMosaic.coneRFpositionsDegs(rfParams.centerConeIndices(1),1);
    spatialSupportY = spatialSupport + theConeMosaic.coneRFpositionsDegs(rfParams.centerConeIndices(1),2);
    [X,Y] = meshgrid(spatialSupportX,spatialSupportY);

    centerConesNum = numel(rfParams.centerConeIndices);
    surroundConesNum = numel(rfParams.surroundConeIndices);
    
    centerRF = []; 
    for iCenterCone = 1:centerConesNum
        theConeWeight = rfParams.centerConeWeights(iCenterCone);
        theConeIndex = rfParams.centerConeIndices(iCenterCone);
        coneRcDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(theConeIndex);
        xo = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
        yo = theConeMosaic.coneRFpositionsDegs(theConeIndex,2);
        g =  theConeWeight * exp(-((X-xo)/coneRcDegs).^2) .* exp(-((Y-yo)/coneRcDegs).^2);
        if (isempty(centerRF))
            centerRF = g;
        else
            centerRF = centerRF + g;
        end
    end

    surroundRF = [];
    for iSurroundCone = 1:surroundConesNum
        theConeWeight = rfParams.surroundConeWeights(iSurroundCone);
        theConeIndex = rfParams.surroundConeIndices(iSurroundCone);
        coneRcDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(theConeIndex);
        xo = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
        yo = theConeMosaic.coneRFpositionsDegs(theConeIndex,2);
        g =  theConeWeight * exp(-((X-xo)/coneRcDegs).^2) .* exp(-((Y-yo)/coneRcDegs).^2);
        if (isempty(surroundRF))
            surroundRF = g;
        else
            surroundRF = surroundRF + g;
        end
    end

    centerProfile = sum(centerRF, 1);
    surroundProfile = sum(surroundRF, 1);

    nFFT = 1024;
    fMax = 1/(2*(spatialSupportX(2)-spatialSupportX(1)));
    deltaF = fMax / (nFFT/2);
    frequencySupport = (-fMax+deltaF):deltaF:fMax;

    centerSTF = abs(fftshift(fft(centerProfile,nFFT))) / length(centerProfile);
    surroundSTF = abs(fftshift(fft(surroundProfile,nFFT))) / length(surroundProfile);

    % Only keep positive frequencies
    idx = find(frequencySupport>=0);
    centerSTF = centerSTF(idx);
    surroundSTF = surroundSTF(idx);
    frequencySupport = frequencySupport(idx);

end

