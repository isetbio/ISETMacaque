function displayModelFits()

    targetLcenterRGCindices = 8;
    targetMcenterRGCindices = [];
    residualDefocusDiopters = 0.000;
    modelVariant = struct(...
        'centerConesSchema',  'variable', ... % Cones feeding into the RF center. Select between {'variable', and 'single'}
        'residualDefocusDiopters', residualDefocusDiopters, ...
        'coneCouplingLambda', 0);


    monkeyID = 'M838';
    maxRecordedRGCeccArcMin = 6;
    startingPointsNum = 256;
    
    % Load the model trained on each session
    crossValidateModel = true;
    crossValidateModelAgainstAllSessions = false;
    trainModel = true;
            
    theTrainedModelFitsfilename = fitsFilename(modelVariant, startingPointsNum, ...
                crossValidateModel, crossValidateModelAgainstAllSessions, trainModel, ...
                targetLcenterRGCindices, targetMcenterRGCindices);
            

    % Load fitted model data for th3 3 training sessions
    [d1Model, d1Data, targetRGCID] = loadModelAndMeasuredData(theTrainedModelFitsfilename, monkeyID, 1);
    [d2Model, d2Data, targetRGCID] = loadModelAndMeasuredData(theTrainedModelFitsfilename, monkeyID, 2);
    [d3Model, d3Data, targetRGCID] = loadModelAndMeasuredData(theTrainedModelFitsfilename, monkeyID, 3);
    
    % Load cone mosaic data
    c = loadConeMosaicData(monkeyID, maxRecordedRGCeccArcMin);
     
    sParams = struct(...
        'PolansSubject', [], ...                % [] = diffraction-limited optics
        'modelVariant', modelVariant, ... 
        'visualStimulus', struct(...
                 'type', 'WilliamsLabStimulus', ...
                 'stimulationDurationCycles', 6));

    % Load the ISETBio computed time-series responses for the simulated STF run
    modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, sParams);
    

    % Form exportsDir
    rootDirName = ISETmacaqueRootPath();
    exportsDir = fullfile(strrep(rootDirName, 'toolbox', ''), 'simulations/generatedData/exports');
    
    % Plot session 1 data, RFs and fits
    hFig = plotRFdata(1, d1Model, d1Data, modelSTFrunData.examinedSpatialFrequencies, modelSTFrunData.theConeMosaic);
    pdfFileName = sprintf('%s_session_1_centerConesSchema_%s_residualDefocus_%2.3fD_coneCouplingLambda_%2.3f.pdf', targetRGCID, modelVariant.centerConesSchema, modelVariant.residualDefocusDiopters, modelVariant.coneCouplingLambda);
    NicePlot.exportFigToPDF(fullfile(exportsDir, pdfFileName), hFig, 300);
    
    % Plot session 2 data, RFs and fits
    hFig = plotRFdata(2, d2Model, d2Data, modelSTFrunData.examinedSpatialFrequencies, modelSTFrunData.theConeMosaic);
    pdfFileName = sprintf('%s_session_2_centerConesSchema_%s_residualDefocus_%2.3fD_coneCouplingLambda_%2.3f.pdf', targetRGCID, modelVariant.centerConesSchema, modelVariant.residualDefocusDiopters, modelVariant.coneCouplingLambda);
    NicePlot.exportFigToPDF(fullfile(exportsDir, pdfFileName), hFig, 300);
    
    % Plot session 3 data, RFs and fits
    hFig = plotRFdata(3, d3Model, d3Data, modelSTFrunData.examinedSpatialFrequencies, modelSTFrunData.theConeMosaic);
    pdfFileName = sprintf('%s_session_3_centerConesSchema_%s_residualDefocus_%2.3fD_coneCouplingLambbda_%2.3f.pdf', targetRGCID, modelVariant.centerConesSchema, modelVariant.residualDefocusDiopters, modelVariant.coneCouplingLambda);
    NicePlot.exportFigToPDF(fullfile(exportsDir, pdfFileName), hFig, 300);
    
    %hFig1 = plotSTFFits(1, d1Model, d1Data, modelSTFrunData.examinedSpatialFrequencies);
    %hFig2 = plotSTFFits(2, d2Model, d2Data, modelSTFrunData.examinedSpatialFrequencies);
    %hFig3 = plotSTFFits(3, d3Model, d3Data, modelSTFrunData.examinedSpatialFrequencies);
    
end

function hFig = plotRFdata(figNo, dModel, dData, examinedSpatialFrequencies, theConeMosaic)
        
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
     set(hFig, 'Position', [10 10 690 1130], 'Color', [1 1 1]);
     
     % Sort RMSE, largest to smallest
     [~,sortedPositionIndices] = sort(dModel.rmsErrors, 'descend');
     
     for iSortedPosition = 1:numel(sortedPositionIndices)
         
        examinedCenterConePositionIndex = sortedPositionIndices(iSortedPosition);
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
        if (iSortedPosition < numel(dModel.indicesOfModelCenterConePositionsExamined))
            noXLabel = true;
        else
            noXLabel = false;
        end
        
        if (iSortedPosition == numel(dModel.indicesOfModelCenterConePositionsExamined))
            mosaicTitle = 'center';
        else
            mosaicTitle = ' ';
        end
        

        
        
        % The center weights
        
        ax = subplot('Position', subplotPosVectors(iSortedPosition,1).v);
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
        
        
        
        if (iSortedPosition == numel(dModel.indicesOfModelCenterConePositionsExamined))
            mosaicTitle = 'surround';
        else
            mosaicTitle = ' ';
        end
        
        % The surround weights
        ax = subplot('Position', subplotPosVectors(iSortedPosition,2).v);
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
        
        ax = subplot('Position', subplotPosVectors(iSortedPosition,3).v);
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
        ax = subplot('Position', subplotPosVectors(iSortedPosition,4).v);
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
        text(ax, 10, -0.15, sprintf('RMSE:%2.2f', dModel.rmsErrors(examinedCenterConePositionIndex)), 'FontSize', 10, 'Color', titleColor);
    
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

