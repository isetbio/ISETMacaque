function fittedRGCModel(fittedModelFileName, operationOptions, ...
    fittedModelFilenameAllPositionsPDF, fittedModelFilenameBestPositionPDF)
% Visualize a fitted RGC model 
%
% Syntax:
%   simulator.visualize.fittedRGCModel(fittedModelFileName, operationOptions,
%       fittedModelFilenameAllPositionsPDF, fittedModelFilenameBestPositionPDF)
%
% Description:
%   Visualize a fitted RGCSTF model 
%
% Inputs:
%    fittedModelFileName  
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    load(fittedModelFileName, 'STFdataToFit', 'theConeMosaic', 'fittedModels');
    
    % Visualize all models
    for iModel = 1:numel(operationOptions.rfCenterConePoolingScenariosExamined)
        theRFcenterConePoolingScenario = operationOptions.rfCenterConePoolingScenariosExamined{iModel};
        visualizedModel = fittedModels(theRFcenterConePoolingScenario);
        
        % Generate a model name for the generated figure title
        switch (operationOptions.opticsScenario)
            case simulator.opticsScenarios.diffrLimitedOptics_residualDefocus
                % Diffraction-limited optics with defocus-based residual blur
                modelName = sprintf('%s (%2.3fD)', ...
                    operationOptions.opticsScenario, ...
                    operationOptions.residualDefocusDiopters);

            case simulator.opticsScenarios.diffrLimitedOptics_GaussianBlur
                % Diffraction-limited optics with Gaussian-based residual blur 
                error('Optic scenario ''%s'' is not implemented yet', simulator.opticsScenarios.diffrLimitedOptics_GaussianBlur);

            case simulator.opticsScenarios.M838Optics
                % M838 optics
                error('Not fitting model to M838 based optics');

            otherwise
                error('Unknown optics scenario: ''%s''.', operationOptions.opticsScenario);
        end

        % Plot model fits for all positions
        hFig = plotFittedModelAtAllPositions(visualizedModel, STFdataToFit, theConeMosaic, modelName, operationOptions.rmsSelector);
        thePDFfilename = fittedModelFilenameAllPositionsPDF;
        thePDFfilename = strrep(thePDFfilename, 'WhichModel', theRFcenterConePoolingScenario); 
        NicePlot.exportFigToPDF(thePDFfilename, hFig, 300);

        % Plot model fits for the best position
        hFig = plotFittedModelAtBestPosition(visualizedModel, STFdataToFit, theConeMosaic, modelName, operationOptions.rmsSelector);
        thePDFfilename = fittedModelFilenameBestPositionPDF;
        thePDFfilename = strrep(thePDFfilename, 'WhichModel', theRFcenterConePoolingScenario); 
        NicePlot.exportFigToPDF(thePDFfilename, hFig, 300);
    end
end


function hFig = plotFittedModelAtBestPosition(visualizedModelFits, STFdataToFit, theConeMosaic, modelName, rmsSelector)
    % Find cone position resulting in the minimal RMSE
    [bestConePosIdx, RMSErrorsAllPositions] = ...
        simulator.analyze.bestConePositionAcrossMosaic(visualizedModelFits, STFdataToFit, rmsSelector);

    % Set-up figure
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 4, ...
       'rowsNum', 1, ...
       'heightMargin',  0.03, ...
       'widthMargin',    0.06, ...
       'leftMargin',     0.06, ...
       'rightMargin',    0.03, ...
       'bottomMargin',   0.2, ...
       'topMargin',      0.02);

    % Plot model fits at all examined positions
    hFig = figure();
    set(hFig, 'Position', [1 1 850 240], 'Color', [1 1 1], ...
              'Name', modelName);

    axCenter = subplot('Position', subplotPosVectors(1,1).v);
    axSurround = subplot('Position', subplotPosVectors(1,2).v);
    axProfile = subplot('Position', subplotPosVectors(1,3).v);

    axSTFpos = subplotPosVectors(1,4).v;
    axSTFpos(1) = axSTFpos(1)+0.02;
    axSTF = subplot('Position', axSTFpos);

    % Visualize the cone weights to the RF center and RF surround
    simulator.visualize.fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
                theConeMosaic, visualizedModelFits{bestConePosIdx}.fittedRGCRF, ...
                false, false);

    % Visualize the STF and the fit
    RGCID = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
    RGCID = '';
    simulator.visualize.fittedSTF(hFig, axSTF, ...
            STFdataToFit.spatialFrequencySupport, ...
            STFdataToFit.responses, ...
            STFdataToFit.responseSE, ...
            visualizedModelFits{bestConePosIdx}.fittedSTF, ...
            [], ... %RMSErrorsAllPositions(bestConePosIdx), ...
            true, RGCID, ...
            'noXLabel', false, ...
            'noYLabel', false);
end



function hFig = plotFittedModelAtAllPositions(visualizedModelFits, STFdataToFit, theConeMosaic, modelName, rmsSelector)
    
    % Find cone position resulting in the minimal RMSE
    examinedConePositionsNum = numel(visualizedModelFits);

    % Find cone position resulting in the minimal RMSE
    [bestConePosIdx, RMSErrorsAllPositions] = ...
        simulator.analyze.bestConePositionAcrossMosaic(visualizedModelFits, STFdataToFit, rmsSelector);

    % Set-up figure
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 4, ...
       'rowsNum', examinedConePositionsNum, ...
       'heightMargin',  0.03, ...
       'widthMargin',    0.00, ...
       'leftMargin',     0.03, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.01);

    % Plot model fits at all examined positions
    hFig = figure();
    set(hFig, 'Position', [1 1 840 1200], 'Color', [1 1 1], ...
              'Name', modelName);

    for iConePosIdx = 1:examinedConePositionsNum
        
        axCenter = subplot('Position', subplotPosVectors(iConePosIdx,1).v);
        axSurround = subplot('Position', subplotPosVectors(iConePosIdx,2).v);
        axProfile = subplot('Position', subplotPosVectors(iConePosIdx,3).v);
        axSTFpos = subplotPosVectors(iConePosIdx,4).v;
        axSTFpos(1) = axSTFpos(1)+0.02;
        axSTF = subplot('Position', axSTFpos);

        % Visualize the cone weights to the RF center and RF surround
        simulator.visualize.fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
                theConeMosaic, visualizedModelFits{iConePosIdx}.fittedRGCRF, ...
                (iConePosIdx < examinedConePositionsNum), true);
                
        % Visualize the STF and the fit
        RGCID = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
        RGCID = '';
        simulator.visualize.fittedSTF(hFig, axSTF, ...
            STFdataToFit.spatialFrequencySupport, ...
            STFdataToFit.responses, ...
            STFdataToFit.responseSE, ...
            visualizedModelFits{iConePosIdx}.fittedSTF, ...
            RMSErrorsAllPositions(iConePosIdx), ...
            (iConePosIdx == bestConePosIdx), RGCID, ...
            'noXLabel', (iConePosIdx < examinedConePositionsNum), ...
            'noYLabel', (iConePosIdx < examinedConePositionsNum));
    end

    % Video setup
    videoOBJ = VideoWriter('FitAnimation2', 'MPEG-4');
    videoOBJ.FrameRate = 10;
    videoOBJ.Quality = 100;
    videoOBJ.open();

    

    for iFrame = 1:examinedConePositionsNum

        hFig = figure(998);
    clf;
    set(hFig, 'Position', [10 10 570 160], 'Color', [1 1 1]);
    axCenter = subplot('Position', [0.01 0.05 0.25 0.9]);
    axSurround = subplot('Position', [0.36 0.05 0.25 0.9]);
    axProfile = subplot('Position', [0.72 0.05 0.25 0.9]);

        simulator.visualize.fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
                theConeMosaic, visualizedModelFits{iFrame}.fittedRGCRF, ...
                true, true);
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
     end

     hFig = figure(998);
    clf;
    set(hFig, 'Position', [10 10 570 160], 'Color', [1 1 1]);
    axCenter = subplot('Position', [0.01 0.05 0.25 0.9]);
    axSurround = subplot('Position', [0.36 0.05 0.25 0.9]);
    axProfile = subplot('Position', [0.72 0.05 0.25 0.9]);

     simulator.visualize.fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
                theConeMosaic, visualizedModelFits{bestConePosIdx}.fittedRGCRF, ...
                true, true);
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));

     videoOBJ.close();

     % Video setup
        videoOBJ = VideoWriter('FitAnimation', 'MPEG-4');
        videoOBJ.FrameRate = 10;
        videoOBJ.Quality = 100;
        videoOBJ.open(); 

    for iFrame = 1:examinedConePositionsNum
        hFig = figure(999);
        clf;
        set(hFig, 'Position', [10 10 220 220], 'Color', [1 1 1]);
        axSTF = subplot('Position', [0.1 0.1 0.89 0.89]);
    
    
        simulator.visualize.fittedSTF(hFig, axSTF, ...
            STFdataToFit.spatialFrequencySupport, ...
            STFdataToFit.responses, ...
            STFdataToFit.responseSE, ...
            visualizedModelFits{iFrame}.fittedSTF, ...
            RMSErrorsAllPositions(iFrame), ...
            false, RGCID, ...
            'noXLabel', true, ...
            'noYLabel', true);
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
        hold(axSTF, 'off');
    end

    hFig = figure(999);
        clf;
        set(hFig, 'Position', [10 10 220 220], 'Color', [1 1 1]);
        axSTF = subplot('Position', [0.1 0.1 0.89 0.89]);
    simulator.visualize.fittedSTF(hFig, axSTF, ...
            STFdataToFit.spatialFrequencySupport, ...
            STFdataToFit.responses, ...
            STFdataToFit.responseSE, ...
            visualizedModelFits{bestConePosIdx}.fittedSTF, ...
            RMSErrorsAllPositions(bestConePosIdx), ...
            false, RGCID, ...
            'noXLabel', true, ...
            'noYLabel', true);
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
    videoOBJ.close();

end


