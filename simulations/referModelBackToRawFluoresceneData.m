function referModelBackToRawFluoresceneData
    % Load the raw fluorescence measurements - no corrections whatsoever
    % and the diffraction-limited OTF
    monkeyID = 'M838';
    sessionData = 'mean';
    d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, sessionData);

    % Load the monkey cone mosaic data
    maxRecordedRGCeccArcMin = 6;
    c = loadConeMosaicData(monkeyID, maxRecordedRGCeccArcMin);
    
    % Simulate 0.067D defocus
    defocusDiopters = 0.067;

    % Fit the L-center RGC responses
    hFig = fitResponses(d.diffractionLimitedOTF.sf, d.dFresponsesLcenterRGCs, d.dFresponseStdLcenterRGCs, defocusDiopters, c.fovealConeCharacteristicRadiusDegs, 'L');
    NicePlot.exportFigToPDF('LcenterRGCs.pdf', hFig, 300);

    % Fit the M-center RGC responses
    hFig = fitResponses(d.diffractionLimitedOTF.sf, d.dFresponsesMcenterRGCs, d.dFresponseStdMcenterRGCs, defocusDiopters, c.fovealConeCharacteristicRadiusDegs, 'M');
    NicePlot.exportFigToPDF('McenterRGCs.pdf', hFig, 300);

end


function theModelRF = DoGLineWeightingFunction(params,fovealConeCharacteristicRadiusDegs)
    kc = params(1);
    rc = params(2)*fovealConeCharacteristicRadiusDegs;
    ks = params(3)*kc;
    rs = params(4)*rc;

    deltaDegs = 2.5e-5;
    spatialSupportDegs = -0.25:deltaDegs:0.25;
    center   = kc*rc*sqrt(pi)*exp(-(spatialSupportDegs/rc).^2);
    surround = ks*rs*sqrt(pi)*exp(-(spatialSupportDegs/rs).^2);
    theModelRF = struct(...
        'profile', center-surround, ...
        'center', center, ...
        'surround', surround, ...
        'spatialSupportDegs', spatialSupportDegs);
end

function theSTF = spatialTransferFunctionForDefocusedSystem(DoGparams, ...
    fovealConeCharacteristicRadiusDegs, spatialFrequencySupport, stimulusOTF, residualDefocusOTF)

    theModelRF = DoGLineWeightingFunction(DoGparams, fovealConeCharacteristicRadiusDegs);
    rfProfile = theModelRF.profile;
    deltaDegs = theModelRF.spatialSupportDegs(2)-theModelRF.spatialSupportDegs(1);
    theFT = fft(rfProfile);
    theSTFwoSided = abs(theFT);

    % Extract the one-sided cone OTF (positive frequencies including 0)
    n = (numel(theSTFwoSided)-1)/2;
    nPosFrequenciesNum = n+1;
    maxSF = 1 / (2*deltaDegs);
    deltaSF = maxSF/nPosFrequenciesNum;
    sfAxis = ((1:nPosFrequenciesNum)-1)*deltaSF;
    theSTFOneSided = theSTFwoSided(1:nPosFrequenciesNum);

    % Resample the one sided STF at the measured frequencies
    theSTFOneSided = interp1(sfAxis, theSTFOneSided, spatialFrequencySupport);

    % Compute the STF after it has passed through stimulus and residual defocus OTFs
    theSTF = theSTFOneSided .* stimulusOTF .* residualDefocusOTF;
end

function [theFittedResponse, theModelRF, fittedParams, lowerBound, upperBound] = ...
    fitBlurredDogModelToSTF(sf, theSTF, theSTFstdErr, stimulusOTF, residualDefocusOTF, fovealConeCharacteristicRadiusDegs)
    
    
    
    kc = struct(...
        'low', 1e-4, ...
        'high', 1e4, ...
        'initial', 10);

    RcToFovealConeRc = struct(...
        'low', 0.5, ...
        'high', 5, ...
        'initial', 1.0);

    RcToFovealConeRc = struct(...
        'low', 0.95, ...
        'high', 1.1, ...
        'initial', 1.0);
    
    KsToKc = struct(...
        'low', 1e-5, ...
        'high', 1, ...
        'initial', 1e-2);

    RsToRc = struct(...
        'low', 1.25, ...
        'high', 12, ...
        'initial', 6);

    %                Kc             Rc/fovealConeRc               kS/kC              Rs/Rc
    paramsInitial = [kc.initial    RcToFovealConeRc.initial     KsToKc.initial     RsToRc.initial];
    lowerBound    = [kc.low        RcToFovealConeRc.low         KsToKc.low         RsToRc.low];
    upperBound    = [kc.high       RcToFovealConeRc.high        KsToKc.high        RsToRc.high];
     

    % Subtract minSTF value if that is < 0
    minSTF = min([0 min(theSTF)]);
    theSTF = theSTF - minSTF;
    
    weights = 1./theSTFstdErr;
    objective = @(p) sum(weights .* (spatialTransferFunctionForDefocusedSystem(p, fovealConeCharacteristicRadiusDegs, sf, stimulusOTF, residualDefocusOTF) - theSTF).^2);
   
    options = optimset(...
        'Display', 'off', ...
        'Algorithm', 'interior-point',...
        'GradObj', 'off', ...
        'DerivativeCheck', 'off', ...
        'MaxFunEvals', 10^5, ...
        'MaxIter', 10^3, ...
        'TolX', 10^(-32), ...
        'TolFun', 10^(-32));

    fittedParams = fmincon(objective,paramsInitial,[],[],[],[],lowerBound,upperBound,[],options);

    doMultiStart = true;

    if (doMultiStart)
        startingPointsNum = 1024;

        problem = createOptimProblem('fmincon',...
                        'x0', fittedParams, ...
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
        [fittedParams,errormulti] = run(ms,problem,startingPointsNum );
    end


    theFittedResponse = spatialTransferFunctionForDefocusedSystem(fittedParams, fovealConeCharacteristicRadiusDegs, sf, stimulusOTF, residualDefocusOTF);
    
    % Add back the minSTF
    theFittedResponse = theFittedResponse + minSTF;
    
    % Compute the line weighting function of the best fit DoG model
    theModelRF = DoGLineWeightingFunction(fittedParams,fovealConeCharacteristicRadiusDegs);
end


function hFig = fitResponses(sf, responses, responseStdErrors, defocusDiopters, fovealConeCharacteristicRadiusDegs, centerType)

    % Compute the stimulus OTF at the measured frequencies
    stimulusOTF = computeStimulusOTF(sf);

    % Load the residual defocus OTF
    load(customDefocusOTFFilename(defocusDiopters), 'OTF_ResidualDefocus');

    % Fit each cell separately
    cellsNum = size(responses,1);
    for cellIndex = 1:cellsNum
        fprintf('Fitting cell %d of %d\n', cellIndex, cellsNum);
        theSTF = squeeze(responses(cellIndex,:));
        theSTFstdErr = squeeze(responseStdErrors(cellIndex,:));
        [theFittedSTF(cellIndex,:), theModelRF{cellIndex}, fittedParams(cellIndex,:), lowerBound, upperBound] = ...
            fitBlurredDogModelToSTF(sf, theSTF, theSTFstdErr, stimulusOTF, OTF_ResidualDefocus, fovealConeCharacteristicRadiusDegs);
    end


    % Plot the data
    sv = NicePlot.getSubPlotPosVectors(...
        'colsNum', 11, ...
        'rowsNum', 6, ...
        'heightMargin',  0.06, ...
        'widthMargin',    0.005, ...
        'leftMargin',     0.04, ...
        'rightMargin',    0.00, ...
        'bottomMargin',   0.01, ...
        'topMargin',      0.01);


    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1700 1000], 'Units', 'pixels', 'Color', [1 1 1])
    drawnow;

    displayCellLabels = false;

    fluoresceneSignalRange = [-0.05 0.6];

    for cellIndex = 1:cellsNum
        % Plot the fitted model
        ax = subplot('Position', sv(1,cellIndex).v);
        % Plot the error bars
        errorbar(ax,sf,squeeze(responses(cellIndex,:)),squeeze(responseStdErrors(cellIndex,:)),...
           '-o','Marker','none',...
           'Color', [0.25 0.25 0.25], 'LineWidth', 1.5);

        hold(ax, 'on');
        % Plot the measured data
        scatter(ax, sf, squeeze(responses(cellIndex,:)), 64, 'o', 'filled', ...
              'MarkerEdgeColor', [0.25 0.25 0.25], 'MarkerFaceColor', [0.8 0.8 0.8], ...
              'MarkerFaceAlpha', 1.0, 'LineWidth', 1.0);

        % Plot the fitted model
        plot(ax, sf, squeeze(theFittedSTF(cellIndex,:)), 'r-', 'LineWidth', 1.5);
        
        if (cellIndex>1)
            set(ax, 'YTickLabel', {});
        end
        if (displayCellLabels)
            text(4., 0.6, sprintf('%s%d', centerType, cellIndex), 'FontSize', 14);
        end
        set(ax, 'XScale', 'log', 'XTick', [5 10 20 40 60], 'XLim', [3 70], 'FontSize', 12);
        set(ax, 'YLim', fluoresceneSignalRange);
        grid(ax, 'on');
        xlabel('spatial freq. (c/deg)');
        if (cellIndex == 1)
            ylabel('\DeltaF / f_o')
        end

        % Plot the RF profile of the underlying model
        ax = subplot('Position', sv(2,cellIndex).v);
        m = max([max(theModelRF{cellIndex}.center) max(theModelRF{cellIndex}.surround)]);
        
        % Plot the center
        baseline = 0;
        faceColor = [1 0.5 0.7];
        edgeColor = [1 0 0.5];
        faceAlpha = 0.7;
        lineWidth = 1.0;
        shadedAreaPlot(ax,theModelRF{cellIndex}.spatialSupportDegs*60, ...
                         theModelRF{cellIndex}.center/m, ...
                         baseline, faceColor, edgeColor, faceAlpha, lineWidth);
        hold (ax, 'on');

        % Plot the surround
        faceColor = [0.3 0.9 0.7];
        edgeColor = [0.3 0.8 0.7];
        shadedAreaPlot(ax,theModelRF{cellIndex}.spatialSupportDegs*60, ...
                         -theModelRF{cellIndex}.surround/m, ...
                         baseline, faceColor, edgeColor, faceAlpha, lineWidth);

        % Plot the line weighting function
        plot(ax, theModelRF{cellIndex}.spatialSupportDegs*60, theModelRF{cellIndex}.profile/m, 'k-', ...
            'LineWidth', 1.5);

        % Plot the cones
        fovealConeDiameterArcMin = fovealConeCharacteristicRadiusDegs/sqrt(2.0)/0.204*60;
        for k = -2:2
            xOutline = fovealConeDiameterArcMin*(k+[-0.48 0.48 0.3 0.3 -0.3 -0.3 -0.48]);
            yOutline = [-0.2 -0.2 -0.3 -0.5 -0.5 -0.3 -0.2]-0.1;
            patch(ax, xOutline, yOutline, -10*eps*ones(size(xOutline)), ...
                'FaceColor', [0.85 0.85 0.85], 'EdgeColor', [0.2 0.2 0.2], ...
                'LineWidth', 0.5, 'FaceAlpha', 0.5);
        end

        set(ax, 'YColor', 'none')
        set(ax, 'XLim', 1.5*[-1 1], 'YLim', [-0.6 1]*1.05, 'YTick', [-0.2:0.2:1], ...
            'XTick', [-1 -0.5 0 0.5 1], 'XTickLabel', {'-1.0', '', '0', '', '+1.0'});
        set(ax, 'FontSize', 12);
        xtickangle(ax, 0);
        xlabel(ax, 'space (arc min)');
        

        % The fitted params and their bounds
        paramNames{1} = 'Kc';
        paramNames{2} = 'Rc/fovealConeRc';
        paramNames{3} = 'Ks/Kc';
        paramNames{4} = 'Rs/Rc';
        for pIndex = 1:4
            ax = subplot('Position', sv(2+pIndex,cellIndex).v);

            plot([1 1], [lowerBound(pIndex) upperBound(pIndex)], 'k-', 'LineWidth', 1.5);
            hold(ax, 'on');
            plot(1, fittedParams(cellIndex,pIndex), 'ro', 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 14);
            if (pIndex == 2) || (pIndex == 4)
                set(ax, 'YScale', 'linear')
                set(ax, 'YTick', 1:10)
            else
               set(ax, 'YScale', 'log');
            end
            if (pIndex == 3)
               set(ax, 'YTick', [0.01 0.03 0.1 0.3 1], 'YTickLabel', {'0.01', '0.03', '0.1', '0.3', '1'})
            end

            if (cellIndex > 1)
                set(ax, 'YTickLabel', {});
            end
            set(ax, 'XTickLabel', {}, 'FontSize', 12);
            grid(ax, 'on');
            title(paramNames{pIndex});
        end
        drawnow;

    end % cellIndex
end



