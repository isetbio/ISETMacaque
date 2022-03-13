function fittedModel(fittedModelFileName, operationOptions)
% Visualize a fitted RGCSTF model 
%
% Syntax:
%   simulator.visualize.fittedModel(fittedModelFileName, operationOptions)
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
    theSTF = STFdataToFit.responses;
    theSTFstdErr = STFdataToFit.responseSE;
    theSFsupport = STFdataToFit.spatialFrequencySupport;
    
    singleConeCenterModelFits = fittedModels('single-cone');
    multiConeCenterModelFits = fittedModels('multi-cone');

    switch (operationOptions.opticsScenario)
        case simulator.opticsScenarios.diffrLimitedOptics_residualDefocus
            opticsLabel = sprintf('%s(%1.3fD)', ...
                operationOptions.opticsScenario, operationOptions.residualDefocusDiopters);
    
        case simulator.opticsScenarios.diffrLimitedOptics_GaussianBlur
            error('no Gaussian blur label');

        otherwise
            opticsLabel = sprintf('%s %2.2f mm pupil', ...
                operationOptions.opticsScenario, operationOptions.pupilSizeMM);
    end

    conePositionsNum = numel(singleConeCenterModelFits);
    rmsErrorsSingleCone = zeros(conePositionsNum,1);
    rmsErrorsMultiCone = zeros(conePositionsNum,1);
    for iCenterConeIdx = 1:conePositionsNum
        rmsErrorsSingleCone(iCenterConeIdx) = singleConeCenterModelFits{iCenterConeIdx}.fittedRMSE;
        rmsErrorsMultiCone(iCenterConeIdx) = multiConeCenterModelFits{iCenterConeIdx}.fittedRMSE;
    end

    [~, bestSingleConePos] = min(rmsErrorsSingleCone);
    [~, bestMultiConePos] = min(rmsErrorsMultiCone);


    hFig = figure(1); clf;
    set(hFig, 'Name', opticsLabel);

    % Plot STF fits for all positions
    for iCenterConeIdx = 1:conePositionsNum
        singleConeModelFitAtPosition = singleConeCenterModelFits{iCenterConeIdx};
        %singleConeModelFitAtPosition.fittedRGCRF
        %singleConeModelFitAtPosition.DoGparams
        theSingleConeFittedSTF = singleConeModelFitAtPosition.fittedSTF;
        multiConeModelFitAtPosition = multiConeCenterModelFits{iCenterConeIdx};
        theMultiConeFittedSTF = multiConeModelFitAtPosition.fittedSTF;

        ax = subplot(2,7,iCenterConeIdx);
        plotSTFs(ax, theSFsupport, theSTF, theSTFstdErr, ...
            theSingleConeFittedSTF, ...
            rmsErrorsSingleCone(iCenterConeIdx), ...
            (iCenterConeIdx == bestSingleConePos), ...
            'single-cone');

        ax = subplot(2,7,iCenterConeIdx+7);
        plotSTFs(ax, theSFsupport, theSTF, theSTFstdErr, ...
            theMultiConeFittedSTF, ...
            rmsErrorsMultiCone(iCenterConeIdx), ...
            (iCenterConeIdx == bestMultiConePos), ...
            'multi-cone');
    end


    hFig = figure(2); clf;
    set(hFig, 'Name', opticsLabel);

    % Plot fitted RGC RF for all positions
    for iCenterConeIdx = 1:conePositionsNum
        singleConeModelFitAtPosition = singleConeCenterModelFits{iCenterConeIdx};
        
        conesNum = size(theConeMosaic.coneRFpositionsDegs,1);
        theCenterConeWeights = zeros(1, conesNum);
        theCenterConeWeights(singleConeModelFitAtPosition.fittedRGCRF.centerConeIndices) = ...
            singleConeModelFitAtPosition.fittedRGCRF.centerConeWeights;
    
        theSurroundConeWeights = zeros(1, conesNum);
        theSurroundConeWeights(singleConeModelFitAtPosition.fittedRGCRF.surroundConeIndices) = ...
            -singleConeModelFitAtPosition.fittedRGCRF.surroundConeWeights;
    
        maxActivationRange = max([max(abs(theCenterConeWeights(:))) max(abs(theSurroundConeWeights(:)))]);
        
        centerConePositionMicrons = mean(...
            theConeMosaic.coneRFpositionsMicrons(singleConeModelFitAtPosition.fittedRGCRF.centerConeIndices,:), 1);
        xRangeMicrons = centerConePositionMicrons(1) + 10*[-1 1];
        yRangeMicrons = centerConePositionMicrons(2) + 10*[-1 1];


        ax = subplot(4,7,iCenterConeIdx);
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
            'domainVisualizationTicks', struct('x', -40:2:40, 'y', -40:2:40), ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theCenterConeWeights, ...
            'activationRange', 1.2*maxActivationRange*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'noYLabel', true, ...
            'fontSize', 18, ...
            'plotTitle', ' '); 

        ax = subplot(4,7,iCenterConeIdx+7);
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
            'domainVisualizationTicks', struct('x', -40:2:40, 'y', -40:2:40), ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theSurroundConeWeights, ...
            'activationRange', 1.2*maxActivationRange*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'noYLabel', true, ...
            'fontSize', 18, ...
            'plotTitle', ' '); 


    end


end

function plotSTFs(ax, theSFsupport, theSTF, theSTFstdErr, ...
        theFittedSTF, rmsError, isBestPosition, modelName)
    plot(ax, theSFsupport, theSTF, 'ks');
    hold(ax, 'on');
    if (isBestPosition)
        color = [1 0 0];
    else
        color = [0 0 0];
    end
    plot(ax, theSFsupport, theFittedSTF, 'k-', 'Color', color, 'LineWidth', 1.5);
    set(ax, 'XScale', 'log', 'XLim', [4 60], 'XTick', [5 10 20 40 60]);
    set(ax, 'YLim', [-0.2 0.8], 'YTick', -0.2:0.1:1.0);
    grid(ax, 'on')
    title(ax, sprintf('%s (rmse: %2.4f)', modelName, rmsError));
end

