function fittedRGCModel(fittedModelFileName, operationOptions, ...
    fittedModelFilenameAllPositionsPDF, fittedModelFilenameBestPositionPDF)
% Visualize a fitted RGC model 
%
% Syntax:
%   simulator.visualize.fittedModel(fittedModelFileName, operationOptions,
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
            true, ...
            false, ...
            false, ...
            RGCID);
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
        simulator.visualize.fittedSTF(hFig, axSTF, ...
            STFdataToFit.spatialFrequencySupport, ...
            STFdataToFit.responses, ...
            STFdataToFit.responseSE, ...
            visualizedModelFits{iConePosIdx}.fittedSTF, ...
            RMSErrorsAllPositions(iConePosIdx), ...
            (iConePosIdx == bestConePosIdx), ...
            (iConePosIdx < examinedConePositionsNum), ...
            (iConePosIdx < examinedConePositionsNum), ...
            sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex));
    end

end


