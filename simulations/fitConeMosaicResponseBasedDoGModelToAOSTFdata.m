function fitConeMosaicResponseBasedDoGModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    maxRecordedRGCeccArcMin = 6;

    % Load the uncorrected DF data
    monkeyID = 'M838';
    sessionData = 'mean';
    d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, sessionData);

    % Load the monkey cone mosaic data
    c = loadConeMosaicData(monkeyID, maxRecordedRGCeccArcMin);
    
    % ISETBio simulation parameters.
    sParams = struct(...
        'coneCouplingLambda',  0, ...           % no cone coupling
        'PolansSubject', [], ...                % [] = diffraction-limited optics
        'residualDefocusDiopters', 0.067, ...
        'visualStimulus', struct(...
                 'type', 'WilliamsLabStimulus', ...
                 'stimulationDurationCycles', 6));

    % Load the ISETBio computed time-series responses for the simulated STF run
    modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, sParams);
    

    % Find the indices of model L-cones that could provide input to the L-center RGCs
    indicesOfModelConesDrivingLcenterRGCs = indicesOfModelConesWithinEccDegs(...
        modelSTFrunData.theConeMosaic, ...
        modelSTFrunData.theConeMosaic.LCONE_ID, ...
        maxRecordedRGCeccArcMin/60);

    % Find the indices of model M-cones that could provide input to the M-center RGCs
    indicesOfModelConesDrivingMcenterRGCs = indicesOfModelConesWithinEccDegs(...
        modelSTFrunData.theConeMosaic, ...
        modelSTFrunData.theConeMosaic.MCONE_ID, ...
        maxRecordedRGCeccArcMin/60);

    % Fit each of the L-center RGC STFs with a DoG cone pooling model in which
    % the center cone is one of the L-cones within the maxRecordedRGCeccArcMin
    for lConeCenterRGCindex = 1:size(d.dFresponsesLcenterRGCs,1)
        measuredSTF = d.dFresponsesLcenterRGCs(lConeCenterRGCindex,:);
        for iCone = 1:numel(indicesOfModelConesDrivingLcenterRGCs)
            centerModelConeIndex = indicesOfModelConesDrivingLcenterRGCs(iCone);
            computeSingleConeCenterDoGParams(modelSTFrunData, centerModelConeIndex, measuredSTF, lConeCenterRGCindex);
        end
    end

end

function computeSingleConeCenterDoGParams(modelSTFrunData, centerModelConeIndex, measuredSTF, RGCindex)

    % Transform excitations signal (e) to a contrast signal (c), using the
    % background excitations signal (b): c = (e-b)/b;
    b = modelSTFrunData.coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalModulations = ...
        bsxfun(@times, bsxfun(@minus, modelSTFrunData.coneMosaicSpatiotemporalActivation, b), 1./b);

    
    % Params to be fitted
    RsDegs = 1/60;   % surround Rs in degrees 
    Kc = 1;         % center peak gain
    Ks = 1/20;       % surround peak gain
    

    % Determine surround cone indices and weights
    allowableSurroundConeTypes = [ ...
        modelSTFrunData.theConeMosaic.LCONE_ID ...
        modelSTFrunData.theConeMosaic.MCONE_ID ];
    [surroundConeIndices, surroundConeWeights] = surroundConeIndicesAndWeights(...
        modelSTFrunData.theConeMosaic, centerModelConeIndex, RsDegs, allowableSurroundConeTypes);
    
    plotWeights = ~true;
    if (plotWeights)
        figNo = centerModelConeIndex;
        plotModelRGCWeights(figNo, modelSTFrunData.theConeMosaic, centerModelConeIndex, surroundConeIndices, Kc, Ks*surroundConeWeights);
    end

    % center model cone responses
    centerMechanismModulations = Kc * coneMosaicSpatiotemporalModulations(:,:,centerModelConeIndex);

    % surround model cone responses - spatial pooling
    surroundConeWeights = reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)]);
    weightedSurroundModulations = bsxfun(@times, coneMosaicSpatiotemporalModulations(:,:,surroundConeIndices), surroundConeWeights);
    surroundMechanismModulations = Ks * sum(weightedSurroundModulations,3);
    
    % Composite center-surround responses
    modelRGCmodulations = centerMechanismModulations - surroundMechanismModulations;
    
    % Normalize to 1 across all SFs
    m = max(abs(modelRGCmodulations(:)));
    modelRGCmodulations = modelRGCmodulations / m;

    % Fit sinusoids to each time series responses
    temporalSupportSecondsHR = linspace(...
                modelSTFrunData.temporalSupportSeconds(1), ...
                modelSTFrunData.temporalSupportSeconds(end), ...
                100);

    for iSF = 1:numel(modelSTFrunData.examinedSpatialFrequencies)
        [theFittedResponseModulations(iSF,:), fittedParams(iSF,:)] = ...
            fitSinusoidToResponseTimeSeries(...
                modelSTFrunData.temporalSupportSeconds, ...
                modelRGCmodulations(iSF,:), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                temporalSupportSecondsHR);
         modelSTF.amplitude(iSF) = fittedParams(iSF,1);
         modelSTF.phase(iSF) = fittedParams(iSF,2);
    end


    plotTimeSeriesResponses = true;
    if (plotTimeSeriesResponses)
        figName = sprintf('Fitting RGC %d using center cone %d', RGCindex, centerModelConeIndex);
        plotModelRGCSTFtimeSeriesResponses(figName, ...
            modelRGCmodulations, ...
            modelSTFrunData.temporalSupportSeconds, ...
            theFittedResponseModulations, ...
            temporalSupportSecondsHR, ...
            modelSTFrunData.examinedSpatialFrequencies);
        pause(1);
    end

    plotModelSTF = true;
    if (plotModelSTF)
        figure()
        ax = subplot('Position', [0.05 0.05 0.94 0.94]);
        plot(ax,modelSTFrunData.examinedSpatialFrequencies, modelSTF.amplitude, 'ks-', 'LineWidth', 1.5);
        hold(ax, 'on');
        plot(ax,modelSTFrunData.examinedSpatialFrequencies, measuredSTF/max(measuredSTF), 'ro-', ...
            'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5]);
        legend(ax, {'model', 'measured'});
        set(ax, 'XScale', 'log', 'FontSize', 14);
        set(ax, 'XLim', [4 60], 'XTick', [4 8 16 32 64], 'YTick', [0:0.2:1]);
        xlabel(ax,'spatial frequency (c/deg)');
        grid(ax, 'on');
    end
    pause

end

