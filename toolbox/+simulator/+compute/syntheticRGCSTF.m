function dataOut = syntheticRGCSTF(syntheticRGCmodelFilename, coneMosaicResponsesFileName, ...
    syntheticSTFdataPDFFilename, STFdataToFit, rfCenterConePoolingScenario, residualDefocusDiopters, rmsSelector)
% Compute synthetic RGC responses to stimuli of different SFs
%
% Syntax:
%   simulator.compute.syntheticRGCSTF(synthesizedRGCCellIDs, coneMosaicResponsesFileName)
%
% Description:
%   Compute synthetic RGC responses to stimuli of different SFs
%
% Inputs:
%    synthesizedRGCCellIDs
%    coneMosaicResponsesFileName
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%

    % Load the computed cone mosaic responses for the STF stimulus
    load(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined');

    % Convert cone excitation responses to cone modulations
    b = coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, coneMosaicSpatiotemporalActivation, b), 1./b);


    % Load the RGC model to employ
    load(syntheticRGCmodelFilename, 'fittedModels');
    coneMosaicPositionModels = fittedModels(rfCenterConePoolingScenario);

  
    
    % This model contains fits to a number of cone positions.
    % Exctract the model at the position which results in the min RMS
    bestConePosIdx = simulator.analyze.bestConePositionAcrossMosaic(...
            coneMosaicPositionModels, STFdataToFit, rmsSelector);


    theBestConePositionModel = coneMosaicPositionModels{bestConePosIdx};
    
    % Obtain center cone Rc and eccentricity
    bestConeIdx = theBestConePositionModel.fittedRGCRF.centerConeIndices(1);
    centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(bestConeIdx);
    centerConeEccDegs = sqrt(sum((theConeMosaic.coneRFpositionsDegs(bestConeIdx,:)).^2));
    
    thePhysiologicalOpticsSTF = computeSTF(coneMosaicSpatiotemporalActivation, theBestConePositionModel,  ...
        temporalSupportSeconds, spatialFrequenciesExamined, ...
        centerConeCharacteristicRadiusDegs);
    
    dataOut.physiologicalOpticsDoGParams = thePhysiologicalOpticsSTF.DoGparams;
    dataOut.AOSLOOpticsDoGparams = theBestConePositionModel.DoGparams;
    dataOut.weightsSurroundToCenterRatio = thePhysiologicalOpticsSTF.weightsSurroundToCenterRatio;
    dataOut.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;
    dataOut.centerConeEccDegs = centerConeEccDegs;
    
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 10 660 1190]);
    ax = subplot('Position', [0.11 0.06 0.87 0.91]);
    
    % The AOSLO derived STF
    p1 = plot(ax,spatialFrequenciesExamined, STFdataToFit.responses, 'ko',  ...
        'MarkerSize', 20, 'MarkerEdgeColor',  [0 0. 0.], 'MarkerFaceColor', [0.8 0.8 0.8],'LineWidth', 1.5);
    set(ax, 'YColor', 'k');
    hold(ax, 'on');
    plot(ax,spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'k-', 'Color', [0.5 0.5 0.5], 'LineWidth', 4.0);
    p2 = plot(ax,spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'k-', 'LineWidth', 2.0);
    
    % The physiological optics derived STFs
    p3 = plot(ax,spatialFrequenciesExamined, thePhysiologicalOpticsSTF.computedResponses, 'ko', ...
        'MarkerSize', 20,  'MarkerEdgeColor',  [1.0 0. 0.], 'MarkerFaceColor',  [1.0 0.5 0.5],'LineWidth', 1.5);
    plot(ax,thePhysiologicalOpticsSTF.DogFitSpatialFrequencySupportHiRes, thePhysiologicalOpticsSTF.DoGFitHiRes, ...
        'r-', 'LineWidth', 4.0, 'Color', [1 0.5 0.5]);
    p4 = plot(ax,thePhysiologicalOpticsSTF.DogFitSpatialFrequencySupportHiRes, thePhysiologicalOpticsSTF.DoGFitHiRes, ...
        'r-', 'LineWidth', 2.0);
    legend(ax,[p1 p2 p3 p4], {...
        sprintf('AOSLO optics - measured'),...
        sprintf('AOSLO optics - retinal DoG model (single cone + %2.3fD defocus)', residualDefocusDiopters),...
        'physiological optics - computed from retinal DoG model + M838 optics', ...
        'physiological optics - DoG model fit'}, 'FontSize', 16);
    
    
    maxY = max([max(STFdataToFit.responses) max(theBestConePositionModel.fittedSTF)]);
    if (maxY < 0.4)
        maxY = 0.1+round(10*maxY)/10;
    else
        maxY = round(10*(1.2*maxY))/10;
    end
    
    set(ax, 'XScale', 'log', 'FontSize', 24);
    set(ax, 'XLim', [3 70], 'XTick', [2 5 10 20 40 60], 'YLim', [-0.05 maxY], 'YTick', -0.1:0.05:0.8, ...
        'YTickLabel', {'-0.1', '', '0', '', '0.1', '', '0.2', '', '0.3', '', '0.4', '', '0.5', '', '0.6', '', '0.7', '', 0.8});
    grid(ax, 'on');
    box(ax, 'off');
    xlabel(ax,'spatial frequency (c/deg)');
    title(ax,sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex));
    NicePlot.exportFigToPDF(syntheticSTFdataPDFFilename, hFig, 300);
end

function d = computeSTF(coneMosaicSpatiotemporalActivation, theRetinalRGCmodel, ...
    temporalSupportSeconds, spatialFrequencySupport, ...
    centerConeCharacteristicRadiusDegs)


    centerConeIndices = theRetinalRGCmodel.fittedRGCRF.centerConeIndices(:);
    centerConeWeights = theRetinalRGCmodel.fittedRGCRF.centerConeWeights(:);
    surroundConeIndices = theRetinalRGCmodel.fittedRGCRF.surroundConeIndices(:);
    surroundConeWeights = theRetinalRGCmodel.fittedRGCRF.surroundConeWeights(:);

    
    % Compute RGC responses
    [RGCresponses, centerResponses, surroundResponses] = ...
        simulator.modelRGC.poolConeMosaicResponses( ...
            coneMosaicSpatiotemporalActivation(:,:,centerConeIndices), ...
            coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices), ...
            centerConeWeights, ...
            surroundConeWeights);
        
        
    theRGCSTF = zeros(1, size(RGCresponses,1));
    theRGCcenterSTF = theRGCSTF;
    theRGCsurroundSTF = theRGCSTF;
    
    for iSF = 1:size(RGCresponses,1)
        
        % Fit a sinusoid to the temporal response of the RGC
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(RGCresponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []); 
        % The amplitude of the sinusoid is the STF
        theRGCSTF(iSF) = fittedParams(1);
        
        % Fit a sinusoid to the temporal response of the RGC center
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(centerResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);  
        % The amplitude of the sinusoid is the STF
        theRGCcenterSTF(iSF) = fittedParams(1);
        
        % Fit a sinusoid to the temporal response of the RGC surround
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                squeeze(surroundResponses(iSF,:)), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);  
        % The amplitude of the sinusoid is the STF
        theRGCsurroundSTF(iSF) = fittedParams(1);
    end
    
    % Save the computed RGCSTF
    d.computedResponses = theRGCSTF;
    d.weightsSurroundToCenterRatio = sum(surroundConeWeights)/sum(centerConeWeights);
     
    % Fit theRGCSTF with a DoG model
    [d.DoGparams, d.DoGFit, ...
     d.DogFitSpatialFrequencySupportHiRes, ...
     d.DoGFitHiRes] = simulator.fit.DoGmodelToSTF(...
        spatialFrequencySupport, theRGCSTF, ...
        centerConeCharacteristicRadiusDegs);
    
end


function tmp
    centerConeIndices = theBestConePositionModel.fittedRGCRF.centerConeIndices;
    centerConeWeights = theBestConePositionModel.fittedRGCRF.centerConeWeights;
    surroundConeIndices = theBestConePositionModel.fittedRGCRF.surroundConeIndices;
    surroundConeWeights = theBestConePositionModel.fittedRGCRF.surroundConeWeights;

    
    
    rmsSelector
    bestConePosIdx
    
    hFig = figure(1); clf;
    for conePosIndex = 1:numel(coneMosaicPositionModels)
    theBestConePositionModel = coneMosaicPositionModels{conePosIndex};

    theBestConePositionModel
    theBestConePositionModel.DoGparams
    theBestConePositionModel.fittedRGCRF

    centerConeIndices = theBestConePositionModel.fittedRGCRF.centerConeIndices;
    centerConeWeights = theBestConePositionModel.fittedRGCRF.centerConeWeights;
    surroundConeIndices = theBestConePositionModel.fittedRGCRF.surroundConeIndices;
    surroundConeWeights = theBestConePositionModel.fittedRGCRF.surroundConeWeights;

    integratedSensSurroundToCenter = theBestConePositionModel.DoGparams.bestFitValues(2) * (theBestConePositionModel.DoGparams.bestFitValues(3))^2
    weightsSurroundToCenter = sum(surroundConeWeights)/sum(centerConeWeights)
    
    
    centerConeIndices = centerConeIndices(:);
    centerConeWeights = centerConeWeights(:);
    surroundConeIndices = surroundConeIndices(:);
    surroundConeWeights = surroundConeWeights(:);

  %  figure();
    for iSF = 1:numel(spatialFrequenciesExamined)
        for tBin = 1:numel(temporalSupportSeconds)
            cMosaicSpatialActivation = squeeze(coneMosaicSpatiotemporalActivation(iSF,tBin,:));
            centerConeSignals = cMosaicSpatialActivation(centerConeIndices);
            surroundConeSignals = cMosaicSpatialActivation(surroundConeIndices);
            centerResponse(tBin) = sum(centerConeSignals(:) .* centerConeWeights(:));
            surroundResponse(tBin) = sum(surroundConeSignals(:) .* surroundConeWeights(:));
        end 
        RGCresponse = centerResponse - surroundResponse;
        
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                RGCresponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        theSynthesizedSTF(iSF) = fittedParams(1);

        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                centerResponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        
        theCenterSTF(iSF) = fittedParams(1);

        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                temporalSupportSeconds, ...
                surroundResponse, ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        theSurroundSTF(iSF) = fittedParams(1);
        
%          subplot(3,5, iSF)
%          plot(temporalSupportSeconds, RGCresponse, 'k-');
%          set(gca, 'YLim', [-0.2 0.2])
%          title(sprintf('%2.3f c/deg', spatialFrequenciesExamined(iSF)));

    end

    if (conePosIndex  == bestConePosIdx)
        lineWidth = 1.5;
    else
        lineWidth = 0.7;
    end
    
    subplot(7,3,(conePosIndex-1)*3+1)
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-', 'lineWidth' , lineWidth );
    hold on;
    plot(spatialFrequenciesExamined, theCenterSTF, 'r.-');
    plot(spatialFrequenciesExamined, theSurroundSTF, 'b.-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])

    subplot(7,3,(conePosIndex-1)*3+2)
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    hold on
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    set(gca, 'XScale', 'log', 'XLim', [4 60])

    
    subplot(7,3,(conePosIndex-1)*3+3);
    yyaxis('left')
    plot(spatialFrequenciesExamined, theSynthesizedSTF, 'ks-', 'lineWidth' , lineWidth );
    ylabel(sprintf('synthesized STF\n(physiological optics)'));
    set(gca, 'YColor', [0 0 0]);
    yyaxis('right')
    plot(spatialFrequenciesExamined, STFdataToFit.responses, 'ro');
    hold on
    plot(spatialFrequenciesExamined, theBestConePositionModel.fittedSTF, 'r-');
    ylabel('measured STF (AOSLO)');
    set(gca, 'YColor', 'r', 'XScale', 'log', 'XLim', [4 60])
    end

    NicePlot.exportFigToPDF(syntheticSTFdataPDFFilename, hFig, 300);
end

