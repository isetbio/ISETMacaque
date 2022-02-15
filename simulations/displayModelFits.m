function displayModelFits()

    targetLcenterRGCindices = 10;
    targetMcenterRGCindices = [];
   
    accountForResponseOffset = true;
    accountForResponseSignReversal = false;
    
    monkeyID = 'M838';
    maxRecordedRGCeccArcMin = 6;
    startingPointsNum = 512;
    
    % Load the trained models
    crossValidateModel = true;
    crossValidateModelAgainstAllSessions = false;
    trainModel = true;
    
    % Form exportsDir
    rootDirName = ISETmacaqueRootPath();
    exportsDir = fullfile(strrep(rootDirName, 'toolbox', ''), 'simulations/generatedData/exports');
   
    receptiveFieldAndOpticalVariations = {};
    
    receptiveFieldAndOpticalVariations{numel(receptiveFieldAndOpticalVariations)+1} = struct(...
        'centerConesSchema', 'single', ... % choose between {'variable', and 'single'}
        'residualDefocusDiopters', 0);

    receptiveFieldAndOpticalVariations{numel(receptiveFieldAndOpticalVariations)+1} = struct(...
        'centerConesSchema', 'single', ...
        'residualDefocusDiopters', 0.067);

    receptiveFieldAndOpticalVariations{numel(receptiveFieldAndOpticalVariations)+1} = struct(...
        'centerConesSchema', 'variable', ...
        'residualDefocusDiopters', 0);

    receptiveFieldAndOpticalVariations{numel(receptiveFieldAndOpticalVariations)+1} = struct(...
        'centerConesSchema', 'variable', ...
        'residualDefocusDiopters', 0.067);


   

    for sessionIndex = 1:3
        for iModel = 1:numel(receptiveFieldAndOpticalVariations)

            modelVariant = struct(...
                'centerConesSchema', receptiveFieldAndOpticalVariations{iModel}.centerConesSchema,...
                'residualDefocusDiopters', receptiveFieldAndOpticalVariations{iModel}.residualDefocusDiopters, ...
                'coneCouplingLambda', 0, ...
                'transducerFunctionAccountsForResponseOffset', accountForResponseOffset, ...
                'transducerFunctionAccountsForResponseSign', accountForResponseSignReversal);


            sParams = struct(...
                'PolansSubject', [], ...                % [] = diffraction-limited optics
                'modelVariant', modelVariant, ... 
                'visualStimulus', struct(...
                         'type', 'WilliamsLabStimulus', ...
                         'stimulationDurationCycles', 6));

            if (iModel == 1)
                % Load the ISETBio computed time-series responses for the simulated STF run
                modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, sParams);
            end

            theTrainedModelFitsfilename = fitsFilename(modelVariant, startingPointsNum, ...
                    crossValidateModel, crossValidateModelAgainstAllSessions, trainModel, ...
                    targetLcenterRGCindices, targetMcenterRGCindices);

            % Load fitted model data 
            [dModel, dData, targetRGCID] = loadModelAndMeasuredData(theTrainedModelFitsfilename, monkeyID, sessionIndex);
            
            % Recompute the errors
            nSFs = numel(dData.dFresponses);
            for iPos = 1:size(dModel.fittedSTFs,1)
                residuals = dData.dFresponses - squeeze(dModel.fittedSTFs(iPos,:));
                theErrors(sessionIndex, iModel, iPos) = sqrt(1/nSFs * sum(residuals.^2));
            end
            
            plogTrainingModels = true;
            if (plogTrainingModels)
                % Plot model fits and data
                hFig = plotRFdata(iModel, dModel, dData, modelSTFrunData.examinedSpatialFrequencies, modelSTFrunData.theConeMosaic, ...
                    sessionIndex, modelVariant.centerConesSchema, modelVariant.residualDefocusDiopters);
    
                % Export to PDF
                pdfFileName = fitsPDFFilename(...
                    modelVariant, targetRGCID, startingPointsNum, ...
                    sessionIndex, 'Training');
                NicePlot.exportFigToPDF(pdfFileName, hFig, 300);
            end
        end % iModel
    end
    
    % Plot model performance across examined positions
    hFigSummary = figure(1000); clf;
    set(hFigSummary, 'Position', [10 10 1750 600], 'Color', [1 1 1]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 3, ...
       'heightMargin',  0.07, ...
       'widthMargin',    0.06, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.05);

    referenceSession = 1;
    referenceModel = 1;
    referencePosition = 1;
    referencePerformance = theErrors(referenceSession,referenceModel,referencePosition);
    
    positionIndices = 1:size(theErrors,3);

    legends = {};
    for iModel = 1:numel(receptiveFieldAndOpticalVariations)
        rfOpt = receptiveFieldAndOpticalVariations{iModel};
        legends{numel(legends)+1} = sprintf('%s center cone(s), defocus: %2.3fD', ...
            rfOpt.centerConesSchema, rfOpt.residualDefocusDiopters);
    end



    for sessionIndex = 1:3      
        subplot('Position', subplotPosVectors(1, sessionIndex).v);
        performances = squeeze(theErrors(sessionIndex,:,:));
        bar(positionIndices, performances/referencePerformance);
        xlabel('examined RF center position index');
        ylabel('relative rms error');
        legend(legends);
        title(sprintf('%sRGC (session %d)',targetRGCID, sessionIndex));
        set(gca, 'FontSize', 18, 'XTick', 1:10, 'XLim', [0 numel(positionIndices)+1], 'YLim', [0.3 3], 'YTick', [0.3 0.5 0.67 1 1.5 2 3]);
        grid on
    end
    
    hFigSummary2 = figure(1001); clf;
    set(hFigSummary2, 'Position', [10 10 1750 1100], 'Color', [1 1 1]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 3, ...
       'heightMargin',  0.07, ...
       'widthMargin',    0.06, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.01);
    subplotPosVectors = subplotPosVectors(:);
    sessionIndices = 1:1:size(theErrors,1);
    for positionIndex = 1:numel(positionIndices)
        subplot('Position', subplotPosVectors(positionIndex,1).v);
        performances = squeeze(theErrors(:,:,positionIndex));
        bar(sessionIndices, performances/referencePerformance);
        xlabel('session index');
        ylabel('relative rms error');
        legend(legends);
        title(sprintf('%s RGC (position index %d)', targetRGCID, positionIndex));
        set(gca, 'FontSize', 18, 'XTick', 1:10, 'XLim', [0 4], 'YLim', [0.3 3], 'YTick', [0.3 0.5 0.67 1 1.5 2 3]);
        grid on
    end
    
end

function hFig = plotRFdata(figNo, dModel, dData, examinedSpatialFrequencies, theConeMosaic,...
    sessionIndex, centerConesSchema, residualDefocusDiopters)
        
     subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 4, ...
       'rowsNum', numel(dModel.indicesOfModelCenterConePositionsExamined), ...
       'heightMargin',  0.03, ...
       'widthMargin',    0.02, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.035, ...
       'topMargin',      0.005);
   
     % Plot RFs at all examined positions
     hFig = figure(figNo); clf;
     set(hFig, 'Position', [1+(figNo-1)*700 63 690 1130], 'Color', [1 1 1], ...
         'Name', sprintf('%s center cone(s), with RESIDUAL DEFOCUS of: %2.3fD, trained on SESSION %d',  upper(centerConesSchema), residualDefocusDiopters, sessionIndex));
     

     for examinedCenterConePositionIndex = 1:numel(dModel.rmsErrors)
         
        coneRcDegs = dModel.centerModelCenterConeCharacteristicRadiiDegs(examinedCenterConePositionIndex);
         
        centroidPosMicrons = dModel.centroidPosition{examinedCenterConePositionIndex} * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        xRangeMicrons = round(centroidPosMicrons(1)) + 8*[-1 1];
        yRangeMicrons = round(centroidPosMicrons(2)) + 8*[-1 1];
     
        % Extract center and surround peak sensitivities
        DoGparams = dModel.fittedParamsPositionExamined(examinedCenterConePositionIndex,:);
        Kc = DoGparams(1);
        KsToKc = DoGparams(2);
        Ks = Kc * KsToKc;
        
        % RsDegs = DoGparams(3)*coneRcDegs;
%         if (strcmp(modelVarian.centerConesSchema,  'variable'))
%            RcDegs = nan;
%         else
%            RcDegs = DoGparams(4)*coneRcDegs;
%         end

        
        centerConeIndices = dModel.centerConeIndices{examinedCenterConePositionIndex};
        centerConeWeights = dModel.centerConeWeights{examinedCenterConePositionIndex};
        surroundConeIndices = dModel.surroundConeIndices{examinedCenterConePositionIndex};
        surroundConeWeights = dModel.surroundConeWeights{examinedCenterConePositionIndex};
        
        conesNum = size(theConeMosaic.coneRFpositionsDegs,1);
        theCenterConeWeights = zeros(1, conesNum);
        theCenterConeWeights(centerConeIndices) = Kc * centerConeWeights;
        
        theSurroundConeWeights = zeros(1, conesNum);
        theSurroundConeWeights(surroundConeIndices) = -Ks * surroundConeWeights;
        maxWeights = max([max(abs(theCenterConeWeights(:))) max(abs(theSurroundConeWeights(:)))]);
        maxWeights = max([max(abs(theSurroundConeWeights(:)))]);
        
        
        xTicks = -40:4:40;
        if (examinedCenterConePositionIndex < numel(dModel.indicesOfModelCenterConePositionsExamined))
            noXLabel = true;
        else
            noXLabel = false;
        end
        
        if (examinedCenterConePositionIndex  == numel(dModel.indicesOfModelCenterConePositionsExamined))
            mosaicTitle = 'center';
        else
            mosaicTitle = ' ';
        end
        

        % The center weights
        ax = subplot('Position', subplotPosVectors(examinedCenterConePositionIndex,1).v);
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
            'domainVisualizationTicks', struct('x', xTicks, 'y', xTicks), ...
            'crossHairsAtPosition', centroidPosMicrons, ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theCenterConeWeights, ...
            'noXLabel', noXLabel, ...
            'noYLabel', true, ...
            'activationRange', maxWeights*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'fontSize', 12, ...
            'plotTitle', mosaicTitle);
        
        
        
        if (examinedCenterConePositionIndex  == numel(dModel.indicesOfModelCenterConePositionsExamined))
            mosaicTitle = 'surround';
        else
            mosaicTitle = ' ';
        end
        
        % The surround weights
        ax = subplot('Position', subplotPosVectors(examinedCenterConePositionIndex ,2).v);
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', ax, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)], ...
            'domainVisualizationTicks', struct('x', xTicks, 'y', []), ...
            'crossHairsAtPosition', centroidPosMicrons, ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theSurroundConeWeights, ...
            'noXLabel', noXLabel, ...
            'noYLabel', true, ...
            'activationRange', maxWeights*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'fontSize', 12, ...
            'plotTitle', mosaicTitle);
        if (noXLabel)
            set(ax, 'XTickLabel', {});
        end
        
        % The center/surround line profiles
        centroidDegs = dModel.centroidPosition{examinedCenterConePositionIndex};
        xDegs = centroidDegs(1) + (-0.1:0.0005:0.1);
        
        for iCone = 1:numel(centerConeIndices)
            theConeIndex = centerConeIndices(iCone);
            xConePosDegs = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
            if (iCone == 1)
                centerProfile = Kc * centerConeWeights(iCone)*exp(-((xDegs-xConePosDegs)/coneRcDegs).^2);
            else
                centerProfile = centerProfile + Kc * centerConeWeights(iCone)*exp(-((xDegs-xConePosDegs)/coneRcDegs).^2);
            end
        end
        for iCone = 1:numel(surroundConeIndices)
            theConeIndex = surroundConeIndices(iCone);
            xConePosDegs = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
            if (iCone == 1)
                surroundProfile = Ks * surroundConeWeights(iCone)*exp(-((xDegs-xConePosDegs)/coneRcDegs).^2);
            else
                surroundProfile = surroundProfile + Ks * surroundConeWeights(iCone)*exp(-((xDegs-xConePosDegs)/coneRcDegs).^2);
            end
        end
        
        xMicrons = xDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        maxProfile = max([max(centerProfile(:)) max(surroundProfile(:))]);
        centerProfile = centerProfile / maxProfile;
        surroundProfile = surroundProfile / maxProfile;
        
        ax = subplot('Position', subplotPosVectors(examinedCenterConePositionIndex ,3).v);
        faceColor = 1.7*[100 0 30]/255;
        edgeColor = [0.7 0.2 0.2];
        faceAlpha = 0.4;
        lineWidth = 1.0;
        baseline = 0;
        shadedAreaPlot(ax, xMicrons, centerProfile, ...
             baseline, faceColor, edgeColor, faceAlpha, lineWidth);
        hold(ax, 'on');
        faceColor = [75 150 200]/255;
        edgeColor = [0.3 0.3 0.7];
        shadedAreaPlot(ax, xMicrons, -surroundProfile, ...
            baseline, faceColor, edgeColor, faceAlpha, lineWidth);

        axis(ax, 'square');
        grid(ax, 'on');
        set(ax, 'XLim', [xRangeMicrons(1) xRangeMicrons(2)], 'XTick', xTicks, 'YLim', [-1.05 1.05], 'YTick', -1:0.5:1);
        set(ax, 'FontSize', 12);
        if (noXLabel)
            set(ax, 'XTickLabel', {});
        else
            xlabel(ax, 'retinal space (microns)');
        end
        
        
        % The STFfit
        ax = subplot('Position', subplotPosVectors(examinedCenterConePositionIndex ,4).v);
        hold(ax, 'on');
        axis(ax, 'square');
        for iSF = 1:numel(examinedSpatialFrequencies)
            plot(ax,examinedSpatialFrequencies(iSF)*[1 1],  dData.dFresponses(iSF) + dData.dFresponsesStd(iSF)*[-1 1], ...
                'r-', 'LineWidth', 1.0);
        end
        plot(ax,examinedSpatialFrequencies, dData.dFresponses, 'ro-', ...
            'MarkerFaceColor', [1 0.5 0.50], 'MarkerSize', 8, 'LineWidth', 1.0);
        plot(ax,examinedSpatialFrequencies, dModel.fittedSTFs(examinedCenterConePositionIndex,:), ...
            'k-', 'LineWidth', 1.5);
        
        set(ax, 'XScale', 'log', 'XLim', [4 60], ...
            'XTick', [1 3 5 10 20 30 50 100], 'YLim', [-0.2 1.1*max(dData.dFresponses(:))], ...
            'FontSize', 12);
        grid(ax, 'on');
        
        if (noXLabel)
            set(ax, 'XTickLabel', {});
        else
            xlabel(ax, 'spatial frequency (c/deg)');
        end
        
        if ( dModel.rmsErrors(examinedCenterConePositionIndex) == min(dModel.rmsErrors))
             titleColor = [1 0 0];
        else
             titleColor = [0 0 0];
        end
        text(ax, 10, -0.15, sprintf('RMSE:%.1fE+3', 1000*dModel.rmsErrors(examinedCenterConePositionIndex)), 'FontSize', 10, 'Color', titleColor);
    
     end
     
    
end


function hFig = plotSTFFits(figNo, dModel, dData, examinedSpatialFrequencies)

    % Plot fits at all examined positions
    hFig = figure(figNo); clf;
    for examinedCenterConePositionIndex = 1:numel(dModel.indicesOfModelCenterConePositionsExamined)
        centroidPosMicrons = dModel.centroidPosition{examinedCenterConePositionIndex}*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        
        subplot(2,4,examinedCenterConePositionIndex);
        hold on
        for iSF = 1:numel(examinedSpatialFrequencies)
            plot(examinedSpatialFrequencies(iSF)*[1 1],  dData.dFresponses(iSF) + dData.dFresponsesStd(iSF)*[-1 1], ...
                'r-', 'LineWidth', 1.0);
        end
        plot(examinedSpatialFrequencies, dData.dFresponses, 'ro-', ...
            'MarkerFaceColor', [1 0.5 0.50], 'MarkerSize', 8, 'LineWidth', 1.0);
        plot(examinedSpatialFrequencies, dModel.fittedSTFs(examinedCenterConePositionIndex,:), ...
            'k-', 'LineWidth', 1.5);
        
        set(gca, 'XScale', 'log', 'XLim', [4 60], 'XTick', [1 3 5 10 20 30 50 100], 'YLim', [-0.2 1.1*max(dData.dFresponses(:))], 'FontSize', 14);
        grid on
        
        if ( dModel.rmsErrors(examinedCenterConePositionIndex) == min(dModel.rmsErrors))
             titleColor = [1 0 0];
        else
             titleColor = [0 0 0];
        end
        
        title(sprintf('RMSE:%2.2f (pos: %2.1f,%2.1f)', ...
            dModel.rmsErrors(examinedCenterConePositionIndex), ...
            centroidPosMicrons(1), centroidPosMicrons(2)), 'Color', titleColor, 'FontSize', 12);
    end
    
end

function [dSession, measuredData, cellType] = loadModelAndMeasuredData(theTrainedModelFitsfilename, monkeyID, sessionIndex)
    d = load(theTrainedModelFitsfilename);
    dSession.indicesOfModelCenterConePositionsExamined = d.indicesOfModelConesDrivingLcenterRGCs;
    if (isfield(d, 'fittedParamsLcenterRGCs'))
        cellType = 'L';
        targetRGCindex = d.targetLcenterRGCindices(1);
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerLConeCharacteristicRadiiDegs{sessionIndex};
        tmp.fittedParams = d.fittedParamsLcenterRGCs{sessionIndex};
        tmp.fittedSTFs = d.fittedSTFsLcenterRGCs{sessionIndex};
        tmp.rmsErrors = d.rmsErrorsLcenterRGCs{sessionIndex};
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumLcenterRGCs{sessionIndex};
        dSession.centroidPosition = d.centroidPositionLcenterRGCs{sessionIndex};
        dSession.centerConeIndices = d.centerConeIndicesLcenterRGCs{sessionIndex};
        dSession.centerConeWeights = d.centerConeWeightsLcenterRGCs{sessionIndex};
        dSession.surroundConeIndices = d.surroundConeIndicesLcenterRGCs{sessionIndex};
        dSession.surroundConeWeights = d.surroundConeWeightsLcenterRGCs{sessionIndex};
        measuredData = loadRawData(monkeyID, sessionIndex, cellType, targetRGCindex);
    else
        cellType = 'M';
        targetRGCindex = d.targetMcenterRGCindices(1);
        dSession.centerModelCenterConeCharacteristicRadiiDegs = d.centerMConeCharacteristicRadiiDegs{sessionIndex};
        tmp.fittedParams = d.fittedParamsMcenterRGCs{sessionIndex};
        tmp.fittedSTFs = d.fittedSTFsMcenterRGCs{sessionIndex};
        tmp.rmsErrors = d.rmsErrorsMcenterRGCs{sessionIndex};
        dSession.centerConesFractionalNumLcenterRGCs = d.centerConesFractionalNumMcenterRGCs{sessionIndex};
        dSession.centroidPosition = d.centroidPositionMcenterRGCs{sessionIndex};
        dSession.centerConeIndices = d.centerConeIndicesMcenterRGCs{sessionIndex};
        dSession.centerConeWeights = d.centerConeWeightsMcenterRGCs{sessionIndex};
        dSession.surroundConeIndices = d.surroundConeIndicesMcenterRGCs{sessionIndex};
        dSession.surroundConeWeights = d.surroundConeWeightsMcenterRGCs{sessionIndex};
        measuredData = loadRawData(monkeyID, sessionIndex, 'M', targetRGCindex);
    end
    
    dSession.fittedParamsPositionExamined = squeeze(tmp.fittedParams(1, targetRGCindex,:,:));
    dSession.fittedSTFs = squeeze(tmp.fittedSTFs(1,targetRGCindex,:,:));
    dSession.rmsErrors = squeeze(tmp.rmsErrors(1,targetRGCindex,:));
    cellType = sprintf('%s%d', cellType, targetRGCindex);
end

function  measuredData = loadRawData(monkeyID, sessionIndex, coneType, targetRGCindex)
    switch (sessionIndex)
        case 1
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session1only'); 
        case 2
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session2only');
        case 3
            d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, 'session3only');
    end
    switch (coneType)
        case 'L'
            measuredData.dFresponses = d.dFresponsesLcenterRGCs(targetRGCindex,:);
            measuredData.dFresponsesStd = d.dFresponseStdLcenterRGCs(targetRGCindex,:);
        case 'M'
            measuredData.dFresponses = d.dFresponsesMcenterRGCs(targetRGCindex,:);
            measuredData.dFresponsesStd = d.dFresponseStdMcenterRGCs(targetRGCindex,:);
    end
        
end

