function fitConeMosaicResponseBasedDoGModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 1024;
    
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    maxRecordedRGCeccArcMin = 1;

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
        'residualDefocusDiopters', 0.072, ...
        'visualStimulus', struct(...
                 'type', 'WilliamsLabStimulus', ...
                 'stimulationDurationCycles', 6));

    % Load the ISETBio computed time-series responses for the simulated STF run
    modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, sParams);

    % Transform excitations signal (e) to a contrast signal (c), using the
    % background excitations signal (b): c = (e-b)/b;
    b = modelSTFrunData.coneMosaicBackgroundActivation;
    modelSTFrunData.coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, modelSTFrunData.coneMosaicSpatiotemporalActivation, b), 1./b);

    % Find the indices of model L-cones that could provide input to the L-center RGCs
    indicesOfModelConesDrivingLcenterRGCs = indicesOfModelConesWithinEccDegs(...
        modelSTFrunData.theConeMosaic, ...
        modelSTFrunData.theConeMosaic.LCONE_ID, ...
        maxRecordedRGCeccArcMin/60);

    % Fit the L-center RGCs using the model L-cones that could provide
    % input to the RF centers
    [fittedParamsLcenterRGCs, centerLConeCharacteristicRadiiDegs, ...
        fittedSTFsLcenterRGCs, rmsErrorsLcenterRGCs] = ...
        fitAllData(modelSTFrunData, ...
                   indicesOfModelConesDrivingLcenterRGCs, ...
                   d.dFresponsesLcenterRGCs, ...
                   d.dFresponseStdLcenterRGCs, ...
                   startingPointsNum, 'L');
                   
    % Find the indices of model M-cones that could provide input to the M-center RGCs
    indicesOfModelConesDrivingMcenterRGCs = indicesOfModelConesWithinEccDegs(...
        modelSTFrunData.theConeMosaic, ...
        modelSTFrunData.theConeMosaic.MCONE_ID, ...
        maxRecordedRGCeccArcMin/60);
    
    % Fit the M-center RGCs using the model M-cones that could provide
    % input to the RF centers
    [fittedParamsMcenterRGCs, centerMConeCharacteristicRadiiDegs, ...
        fittedSTFsMcenterRGCs, rmsErrorsMcenterRGCs] = ...
        fitAllData(modelSTFrunData, ...
                   indicesOfModelConesDrivingMcenterRGCs, ...
                   d.dFresponsesMcenterRGCs, ...
                   d.dFresponseStdMcenterRGCs, ...
                   startingPointsNum, 'M');


    save('ISETBioFits.mat', ...
        'fittedParamsLcenterRGCs', 'centerLConeCharacteristicRadiiDegs', ...
        'fittedSTFsLcenterRGCs', 'rmsErrorsLcenterRGCs', ...
        'indicesOfModelConesDrivingLcenterRGCs', ...
        'fittedParamsMcenterRGCs', 'centerMConeCharacteristicRadiiDegs', ...
        'fittedSTFsMcenterRGCs', 'rmsErrorsMcenterRGCs', ...
        'indicesOfModelConesDrivingMcenterRGCs', ...
        'startingPointsNum');

end

function [fittedParams, centerConeCharacteristicRadiusDegs, fittedSTFs, rmsErrors] = ...
    fitAllData(modelSTFrunData, indicesOfModelConesDrivingTheRGCcenters, ...
    dFresponses, dFresponseStdErr, ...
    startingPointsNum, centerConeType)

    % Fit each of RGC STF with a DoG cone pooling model in which
    % the center cone is one of the cones within the maxRecordedRGCeccArcMin

    % Initialize
    rgcCellsNum = size(dFresponses,1);
    centerConesNum = numel(indicesOfModelConesDrivingTheRGCcenters);
    rmsErrors = nan(rgcCellsNum, centerConesNum);


    for iRGCindex = 1:rgcCellsNum
        fprintf('Fitting RGC data (%d/%d).\n', iRGCindex, rgcCellsNum);
        theMeasuredSTF = dFresponses(iRGCindex,:);
        theMeasuredSTFStdErr = dFresponseStdErr(iRGCindex,:);

        hFig = figure(iRGCindex); clf;
        set(hFig, 'Position', [10 10 1300 450], 'Color', [1 1 1]);
        axRF     = subplot('Position', [0.69 0.12 0.30 0.8]);
        ax     = subplot('Position', [0.35 0.12 0.30 0.8]);
        axMap  = subplot('Position', [0.02 0.12 0.30 0.8]);

        for iCone = 1:numel(indicesOfModelConesDrivingTheRGCcenters)
            
            fitResults = fitConePoolingDoGModelToSTF(...
                theMeasuredSTF, theMeasuredSTFStdErr, ...
                modelSTFrunData, indicesOfModelConesDrivingTheRGCcenters(iCone), ...
                startingPointsNum);

            fittedParams(iRGCindex, iCone,:) = fitResults.fittedParams;
            centerConeCharacteristicRadiusDegs(iCone) = fitResults.centerConeCharacteristicRadiusDegs;
            
            % Plot cone pooling schematic
            surroundConeIndices = fitResults.surroundConeIndices;
            surroundConeWeights = fitResults.surroundConeWeights;
    
            rmsErrors(iRGCindex, iCone) = fitResults.rmsErrors;

            fittedSTFs(iRGCindex, iCone,:) =  fitResults.theFittedSTFs;
            fittedCenterSTFs(iRGCindex, iCone,:) =  fitResults.theFittedCenterSTFs;
            fittedSurroundSTFs(iRGCindex, iCone,:) = fitResults.theFittedSurroundSTFs;
            
            fprintf('fit with cone %d of %d (rmsE: %2.3f) which has a Rc = %2.4f arc min\n', ...
                iCone, numel(indicesOfModelConesDrivingTheRGCcenters), ...
                rmsErrors(iRGCindex, iCone), ...
                centerConeCharacteristicRadiusDegs(iCone)*60);

            for iParam = 1:numel(fitResults.paramNames)
                fprintf('\t ''%20s'': %2.4f [%2.4f - %2.2f]\n', ...
                    fitResults.paramNames{iParam}, ...
                    fittedParams(iRGCindex, iCone,iParam), ...
                    fitResults.paramsLowerBound(iParam), ...
                    fitResults.paramsUpperBound(iParam));
            end

            % PLot error map
            if (iCone > 1)
                maxRMSerror = max(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');
                [minRMSerror, bestiCone] = min(squeeze(rmsErrors(iRGCindex,1:iCone)), [], 2, 'omitnan');
                cla(axMap);
                hold(axMap, 'on');
                for allConeIndices = 1:iCone
                    err = (rmsErrors(iRGCindex, allConeIndices)-minRMSerror)/(maxRMSerror-minRMSerror);
                    markerSize = 6 + round(14 * err);
                    centerModelConeIndex = indicesOfModelConesDrivingTheRGCcenters(allConeIndices);
                    centerConePosMicrons = modelSTFrunData.theConeMosaic.coneRFpositionsMicrons(centerModelConeIndex,:);
                    if (allConeIndices == bestiCone)
                        lineWidth = 1.5;
                        color = [0.1 1.0 0.4];
                    else
                        lineWidth = 0.5;
                        color = [0.7 0.7 0.7];
                    end

                    plot(axMap, centerConePosMicrons(1), centerConePosMicrons(2), 'ko', ...
                        'MarkerSize', markerSize, 'MarkerFaceColor', color, 'LineWidth', lineWidth);
                    
                    set(axMap, 'XLim', [-20 20], 'YLim', [-20 20], 'FontSize', 18);
                    axis(axMap, 'square');
                    xlabel(axMap, 'microns');
                    title(axMap, sprintf('RMSerr map (%2.2f - %2.2f)', minRMSerror, maxRMSerror));
                end
            end

            cla(ax);
            hold(ax, 'on')
            % All center cone STFs in gray
            for iiCone = 1:iCone
                linePlotHandle = plot(ax, modelSTFrunData.examinedSpatialFrequencies, squeeze(fittedSTFs(iRGCindex, iiCone,:)), ...
                    'k-', 'LineWidth', 1.5, 'Color', [0.35 0.35 0.35]);
                % Opacity of lines : 0.5
                linePlotHandle.Color = [linePlotHandle.Color 0.5];
            end

            % The best fitting center cone STF in red
            for iiCone = 1:iCone
                if (rmsErrors(iRGCindex, iiCone) == min(min(rmsErrors(iRGCindex,:))))
                    plot(ax, modelSTFrunData.examinedSpatialFrequencies, squeeze(fittedSTFs(iRGCindex, iiCone,:)), ...
                        '-', 'LineWidth', 4.0, 'Color', [0.0 0.0 0.0]);
                    plot(ax, modelSTFrunData.examinedSpatialFrequencies, squeeze(fittedSTFs(iRGCindex, iiCone,:)), ...
                        '-', 'LineWidth', 2, 'Color', [0.1 1.0 0.4]);
                end
            end


            % The error bars
            for iSF = 1:numel(modelSTFrunData.examinedSpatialFrequencies)
                plot(ax, modelSTFrunData.examinedSpatialFrequencies(iSF) *[1 1], ...
                         theMeasuredSTF(iSF) + theMeasuredSTFStdErr(iSF)*[-1 1], ...
                         '-', 'Color', [0 0 0], 'LineWidth', 4);
                plot(ax, modelSTFrunData.examinedSpatialFrequencies(iSF) *[1 1], ...
                         theMeasuredSTF(iSF) + theMeasuredSTFStdErr(iSF)*[-1 1], ...
                         '-', 'Color', [0.1 1.0 0.4], 'LineWidth', 1.5);
            end

            % The mean data points
            plot(ax,modelSTFrunData.examinedSpatialFrequencies, theMeasuredSTF, ...
                  'ko', 'MarkerFaceColor', [0.3 1.0 0.4], 'MarkerSize', 14, 'LineWidth', 1.5);

            set(ax, 'XScale', 'log', 'FontSize', 18);
            set(ax, 'XLim', [4 55], 'XTick', [5 10 20 40 60], 'YTick', [0:0.1:1]);
            grid(ax, 'on');
            axis(ax, 'square');
            xlabel(ax, 'spatial frequency (c/deg)');


            % The best fitting center cone RF
            for iiCone = 1:iCone
                if (rmsErrors(iRGCindex, iiCone) == min(min(rmsErrors(iRGCindex,:))))
                    xArcMin = -2:0.01:2;
                    xDegs = xArcMin/60;
                    Kc = fittedParams(iRGCindex, iiCone,1);
                    KsToKc = fittedParams(iRGCindex, iiCone,2);
                    Ks = Kc * KsToKc;
                    RcDegs = centerConeCharacteristicRadiusDegs(iiCone);
                    RsDegs = fittedParams(iRGCindex, iiCone,3)*RcDegs;
                    centerProfile = Kc * exp(-(xDegs/RcDegs).^2);
                    surroundProfile = Ks * exp(-(xDegs/RsDegs).^2);

                    baseline = 0;
                    % Plot the center
                    cla(axRF);
                    faceColor = [1 0.8 0.8];
                    edgeColor = [0.7 0.2 0.2];
                    faceAlpha = 0.4;
                    lineWidth = 1.0;
                    shadedAreaPlot(axRF,xArcMin, centerProfile, ...
                         baseline, faceColor, edgeColor, faceAlpha, lineWidth);
                    hold(axRF, 'on');
                    
                    % Plot the surround
                    faceColor = [0.8 0.8 1]*0.8;
                    edgeColor = [0.3 0.3 0.7];
                    shadedAreaPlot(axRF,xArcMin, -surroundProfile, ...
                         baseline, faceColor, edgeColor, faceAlpha, lineWidth);

                    plot(axRF, xArcMin, centerProfile-surroundProfile, 'k-', 'LineWidth', 3);
                    plot(axRF, xArcMin, centerProfile-surroundProfile, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);

                    % Plot the cones
                    coneDiameterArcMin = RcDegs/0.204*60;
                    for k = -2:2
                        xOutline = coneDiameterArcMin*(k+[-0.48 0.48 0.3 0.3 -0.3 -0.3 -0.48]);
                        yOutline = max(centerProfile)*([-0.2 -0.2 -0.3 -0.5 -0.5 -0.3 -0.2]-0.1);
                        patch(axRF, xOutline, yOutline, -10*eps*ones(size(xOutline)), ...
                            'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0.2 0.2 0.2], ...
                            'LineWidth', 0.5, 'FaceAlpha', 0.5);
                    end

                    hold(axRF, 'off');
                    set(axRF, 'YColor', 'none', 'YLim', max(centerProfile)*[-0.5 1.05], 'YTick', [0], 'XLim', [-2.2 2.2], 'XTick', -2:1:2, 'FontSize', 18);
                    xlabel(axRF,'arc min.');
                    title(axRF, sprintf('Rs/Rc: %2.2f, Kc/Ks: %2.2f', RsDegs/RcDegs, 1./KsToKc));
                end
            end

            drawnow;

        end
        NicePlot.exportFigToPDF(sprintf('Fits_%s%d.pdf', centerConeType, iRGCindex), hFig, 300);
    end

end

function fitResults = fitConePoolingDoGModelToSTF(theSTF, theSTFstdErr, ...
                     modelSTFrunData, centerModelConeIndex, startingPointsNum)

    allowableSurroundConeTypes = [ ...
        modelSTFrunData.theConeMosaic.LCONE_ID ...
        modelSTFrunData.theConeMosaic.MCONE_ID ];

    constants.allowableSurroundConeTypes = allowableSurroundConeTypes;
    constants.centerConeIndex = centerModelConeIndex;
    constants.allConePositions = modelSTFrunData.theConeMosaic.coneRFpositionsDegs;
    constants.allConeTypes = modelSTFrunData.theConeMosaic.coneTypes;
    constants.coneMosaicSpatiotemporalActivation = modelSTFrunData.coneMosaicSpatiotemporalActivation;
    constants.temporalSupportSeconds = modelSTFrunData.temporalSupportSeconds;
    
    centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * modelSTFrunData.theConeMosaic.coneRFspacingsDegs(centerModelConeIndex);
    constants.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;

    % Subtract minSTF value if that is < 0
    minSTF = min([0 min(theSTF)]);
    theSTF = theSTF - minSTF;

    weights = 1./theSTFstdErr;
    objective = @(p) sum(weights .* (ISETBioComputedSTF(p, constants) - theSTF).^2);
   
    options = optimset(...
        'Display', 'off', ...
        'Algorithm', 'interior-point',...
        'GradObj', 'off', ...
        'DerivativeCheck', 'off', ...
        'MaxFunEvals', 10^5, ...
        'MaxIter', 10^3, ...
        'TolX', 10^(-32), ...
        'TolFun', 10^(-32));

    kc = struct(...
        'low', 1e-4, ...
        'high', 1e5, ...
        'initial', 1);

    KsToKc = struct(...
        'low', 1e-3, ...
        'high', 1, ...
        'initial', 0.1);

    RsToCenterConeRc = struct(...
        'low', 1.2, ...
        'high', 40, ...
        'initial', 5);

    %                Kc            kS/kC              RsToCenterConeRc
    paramsInitial = [kc.initial    KsToKc.initial     RsToCenterConeRc.initial];
    lowerBound    = [kc.low        KsToKc.low         RsToCenterConeRc.low];
    upperBound    = [kc.high       KsToKc.high        RsToCenterConeRc.high];
    paramNames    = {'Kc', 'kS/kC',  'RsToCenterConeRc'};
    
    
    if (startingPointsNum <= 1)
        % Just one attempt
        fittedParams = fmincon(objective,paramsInitial,[],[],[],[],lowerBound,upperBound,[],options);
    else
        % Multi-start
        problem = createOptimProblem('fmincon',...
                        'x0', paramsInitial, ...
                        'objective', objective, ...
                        'lb', lowerBound, ...
                        'ub', upperBound, ...
                        'options', options...
                        );
    
        displayProgress = 'off'; % 'iter';
        ms = MultiStart(...
                       'Display', displayProgress, ...
                       'FunctionTolerance', 2e-4, ...
                       'UseParallel', true);
    
        % Run the multi-start
        [fittedParams,errormulti] = run(ms, problem, startingPointsNum);
    end

    [theFittedSTF, theFittedCenterSTF, theFittedSurroundSTF, ...
        surroundConeIndices, surroundConeWeights] = ...
        ISETBioComputedSTF(fittedParams, constants);

    % RMSerror
    N = numel(theSTF);        
    fitResults.rmsErrors = 100*sqrt(1/N*sum((theSTF-theFittedSTF).^2,2));     

    % Add back the minSTF
    fitResults.theFittedSTFs = theFittedSTF + minSTF;
    fitResults.theFittedCenterSTFs = theFittedCenterSTF + minSTF;
    fitResults.theFittedSurroundSTFs = theFittedSurroundSTF + minSTF;

    fitResults.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;
    fitResults.fittedParams = fittedParams;
    fitResults.surroundConeIndices = surroundConeIndices;
    fitResults.surroundConeWeights = surroundConeWeights;
    fitResults.paramNames = paramNames;
    fitResults.paramsLowerBound = lowerBound;
    fitResults.paramsUpperBound = upperBound;
end

function [surroundConeIndices, surroundConeWeights] = surroundConeIndicesAndWeightsFast(RsDegs, constants)
    % Gaussian weights for the surround cones    
    d = sqrt(sum((bsxfun(@minus, constants.allConePositions, constants.allConePositions(constants.centerConeIndex,:))).^2,2));
    surroundWeights = exp(-(d/RsDegs).^2);

    % Threshold sensitivity for inclusion to the surround summation mechanism
    minSensitivity = 1/100;
    surroundConeIndices = find(surroundWeights >= minSensitivity);
    surroundConeWeights = surroundWeights(surroundConeIndices);

    % Only include cones of the allowable cone types
    idx = [];
    for iConeType = 1:numel(constants.allowableSurroundConeTypes)
        idx2 = find(constants.allConeTypes(surroundConeIndices) == constants.allowableSurroundConeTypes(iConeType));
        idx = cat(1, idx, idx2);
    end

    % Return indices and connection weights of the surround cones
    surroundConeIndices = surroundConeIndices(idx);
    surroundConeWeights = surroundConeWeights(idx);
    surroundConeIndices = reshape(surroundConeIndices, [1 numel(surroundConeIndices)]);
    surroundConeWeights = reshape(surroundConeWeights, [1 numel(surroundConeIndices)]);
end

function [theModelSTF, theModelCenterSTF, theModelSurroundSTF, ...
          surroundConeIndices, surroundConeWeights] = ISETBioComputedSTF(DoGparams, constants)

    KsToKc = DoGparams(2);
    Kc = DoGparams(1);
    Ks = Kc * KsToKc;
    RsDegs = DoGparams(3)*constants.centerConeCharacteristicRadiusDegs;
    
    % Determine surround cone indices and weights
    [surroundConeIndices, surroundConeWeights] = ...
        surroundConeIndicesAndWeightsFast(RsDegs, constants);

    
    %sfsNum = size(constants.coneMosaicSpatiotemporalActivation,1);
    %tBinsNum = size(constants.coneMosaicSpatiotemporalActivation,2);
    %conesNum = size(constants.coneMosaicSpatiotemporalActivation,3);

    % Center model cone responses
    centerMechanismModulations = constants.coneMosaicSpatiotemporalActivation(:,:,constants.centerConeIndex);
    
    % Surround model cone responses
    surroundMechanismInputModulations = constants.coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices);

    % Apply center gain
    centerMechanismModulations = Kc * centerMechanismModulations;

    % Weighted pooling of surround model cone responses
    surroundConeWeights = reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)]);
    weightedSurroundModulations = bsxfun(@times, surroundMechanismInputModulations, surroundConeWeights);

    % Apply surround gain
    surroundMechanismModulations = Ks * sum(weightedSurroundModulations,3);
    
    % Composite center-surround responses
    modelRGCmodulations = centerMechanismModulations - surroundMechanismModulations;
    
    % Fit a sinusoid to the time series responses for each spatial frequency
    % The amplitude of the sinusoid is the STFmagnitude at that spatial frequency
    sfsNum = size(modelRGCmodulations,1);
    theModelSTF = zeros(1, sfsNum);
    theModelCenterSTF = zeros(1, sfsNum);
    theModelSurroundSTF = zeros(1, sfsNum);
    timeHR = linspace(constants.temporalSupportSeconds(1), constants.temporalSupportSeconds(end), 100);
    
    %hFig = figure(10);clf;

    for iSF = 1:sfsNum

        % Retrieve the time-series sesponse for this spatial frequency
        theTimeSeriesResponse = modelRGCmodulations(iSF,:);

        if (1==2)
            % Amplitude of modulation by fitting the entire time-series
            [theFittedSinusoid, fittedParams] = ...
                fitSinusoidToResponseTimeSeries(...
                    constants.temporalSupportSeconds, ...
                    theTimeSeriesResponse, ...
                    WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                    timeHR);
             theModelSTF(iSF) = fittedParams(1);
        else
            % Amplitude of modulation is just the max of the time-series
            theModelSTF(iSF) = max(abs(theTimeSeriesResponse(:)));
        end

%         subplot(3,5,iSF);
%         plot(constants.temporalSupportSeconds, centerMechanismModulations(iSF,:), 'r-');
%         hold on;
%         plot(constants.temporalSupportSeconds, surroundMechanismModulations(iSF,:), 'b-');
% 
         theModelCenterSTF(iSF) = max(abs(squeeze(centerMechanismModulations(iSF,:))));
        theModelSurroundSTF(iSF) = max(abs(squeeze(surroundMechanismModulations(iSF,:))));
    end
    

end