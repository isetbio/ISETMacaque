function fitRawFluorescenceResponses

    monkeyID = 'M838';
    sessionData = 'mean';

    % Load measured RGC spatial frequency curves. Note: these responses have
    % already been de-convolved with the diffraction-limited OTF
    [dFresponsesLcenterRGCs, ...
     dFresponsesMcenterRGCs, ...
     dFresponsesScenterRGCs, ...
     dFresponseStdLcenterRGCs, ...
     dFresponseStdMcenterRGCs, ...
     dFresponseStdScenterRGCs, ...
     diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData);

     
     load('cone_data_M838_OD_2021.mat', 'cone_locxy_diameter_838OD');
     coneDiameterMicrons = cone_locxy_diameter_838OD(:,3);
     conePositionMicrons = cone_locxy_diameter_838OD(:,1:2);
     coneEccMicrons = sqrt(sum(conePositionMicrons.^2,2));
     idx = find(coneEccMicrons < 20);
     
     coneDiameterDegs = coneDiameterMicrons / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
     coneMosaicRcDegs = 0.204*coneDiameterDegs*sqrt(2);
     lowerBoundForRcDegs = min(coneMosaicRcDegs);
     
     meanFovealConeRcDegs = mean(coneMosaicRcDegs(idx));
     
     % ---- Fit with the DoG model (with free Rc) --- 
     rcDegs = [];

     % ---- Fit with the DoG model (with fixed Rc) --- 
     %rcDegs = prctile(coneMosaicRcDegs, 10);
     
     % ---- Fit with the DoG model (with fixed Rc) --- 
     rcDegs = meanFovealConeRcDegs;

     % ---- Use different lower bound for RsToTc for each cell
     determineLowerBoundForRsToRcForEachCell = ~true;
     
     % Compute stimulus OTF
     stimulusOTF = computeStimulusOTF(diffractionLimitedOTF.sf);

     opticalDefocusDiopters = 0.067;

     if (opticalDefocusDiopters > 0)
        % assumed residual defocus
        load(customDefocusOTFFilename(opticalDefocusDiopters), ...
                'OTF_ResidualDefocus', 'sfsExamimed');
        OTF_ResidualDefocusOnly = OTF_ResidualDefocus./diffractionLimitedOTF.otf;
     else
        OTF_ResidualDefocusOnly = ones(size(stimulusOTF));
     end
     sfsExamimed = diffractionLimitedOTF.sf;

     % Deconvolve the effect of stimulus
     dFresponsesLcenterRGCs = bsxfun(@times, dFresponsesLcenterRGCs, 1./stimulusOTF);
     dFresponsesMcenterRGCs = bsxfun(@times, dFresponsesMcenterRGCs, 1./stimulusOTF);
     dFresponseStdLcenterRGCs = bsxfun(@times, dFresponseStdLcenterRGCs, 1./stimulusOTF);
     dFresponseStdMcenterRGCs = bsxfun(@times, dFresponseStdMcenterRGCs, 1./stimulusOTF);
     
     % Deconvolve the effect of residual defocus
     dFresponsesLcenterRGCs = bsxfun(@times, dFresponsesLcenterRGCs, 1./OTF_ResidualDefocusOnly);
     dFresponsesMcenterRGCs = bsxfun(@times, dFresponsesMcenterRGCs, 1./OTF_ResidualDefocusOnly);
     dFresponseStdLcenterRGCs = bsxfun(@times, dFresponseStdLcenterRGCs, 1./OTF_ResidualDefocusOnly);
     dFresponseStdMcenterRGCs = bsxfun(@times, dFresponseStdMcenterRGCs, 1./OTF_ResidualDefocusOnly);
     

     coneType = 'Lcone';
     switch (coneType)
         case 'Lcone'
             mtfs = dFresponsesLcenterRGCs;
             mtfs_stDev = dFresponseStdLcenterRGCs;
         case 'Mcone'
             mtfs = dFresponsesMcenterRGCs;
             mtfs_stDev = dFresponseStdMcenterRGCs;
     end

     [yFits, sfHR, fittedDoGParams, rmsErrors] = fitSpatialTransferFunctions(...
         coneType, sfsExamimed, mtfs, mtfs_stDev, ...
         lowerBoundForRcDegs , determineLowerBoundForRsToRcForEachCell, ...
         rcDegs, opticalDefocusDiopters);

     for cellIndex = 1:size(fittedDoGParams,1)
        params = fittedDoGParams(cellIndex,:);
        if (isempty(rcDegs))
            Kc(cellIndex) = params(1); Rc(cellIndex) = params(2);
            KsOverKc = params(3); RsOverRc = params(4);
        else
            Kc(cellIndex) = params(1); Rc(cellIndex) = rcDegs;
            KsOverKc = params(2); RsOverRc = params(3);
        end
        Ks(cellIndex) = Kc (cellIndex) * KsOverKc; 
        Rs(cellIndex) = Rc(cellIndex) * RsOverRc;
     end

     maxRsLcells = min([2.2 max(Rs)*60]);
     hFigA = figure(20); clf;
     set(hFigA, 'Position', [10 10 600 600], 'Color', [1 1 1]);
     ax = subplot('Position', [0.13 0.13 0.85 0.85]);
     yyaxis(ax, 'right')
     h = histogram(coneMosaicRcDegs*60, 0:0.02:1);
     h.FaceColor = [0.85 0.85 0.85];
     h.EdgeColor = [0.3 0.3 0.3];
     h.FaceAlpha = 0.5;
     yyaxis(ax, 'left');
     scatter(Rc*60, Rs*60, 16^2, 'filled', 'MarkerFaceAlpha', 0.5, ...
         'MarkerFaceColor', [1 0.5 0.5], 'MarkerEdgeColor', [ 0.5 0 0], ...
         'LineWidth',1.0);
     
     hFigB = figure(21); clf;
     set(hFigB, 'Position', [10 10 600 600], 'Color', [1 1 1]);
     ax = subplot('Position', [0.13 0.13 0.85 0.85]);
     scatter(ax, Rc/meanFovealConeRcDegs, Rs/meanFovealConeRcDegs, 16^2, 'filled', ...
         'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', [1 0 0], 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth',1.0);
     for k = 1:numel(Rc)
         if (k > 9)
             kk = -1;
         else
             kk = 1;
         end
         text(ax, Rc(k)/meanFovealConeRcDegs+0.1, Rs(k)/meanFovealConeRcDegs+kk*0.05, sprintf('L%d', k), 'FontSize', 12);
     end
     
     
     hFigC = figure(22); clf;
     set(hFigC, 'Position', [10 10 1000 600], 'Color', [1 1 1]);
     ax = subplot('Position', [0.13 0.13 0.85 0.85]);
     scatter(ax, 0*Rc+0.01, Rs./Rc, 16^2, 'filled', ...
         'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', [1 0 0], 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth',1.0);
     
     
     coneType = 'Mcone';
     switch (coneType)
         case 'Lcone'
             mtfs = dFresponsesLcenterRGCs;
             mtfs_stDev = dFresponseStdLcenterRGCs;
         case 'Mcone'
             mtfs = dFresponsesMcenterRGCs;
             mtfs_stDev = dFresponseStdMcenterRGCs;
     end

     [yFits, sfHR, fittedDoGParams, rmsErrors] = fitSpatialTransferFunctions(...
         coneType, sfsExamimed, mtfs, mtfs_stDev, ...
         lowerBoundForRcDegs, determineLowerBoundForRsToRcForEachCell, ...
         rcDegs, opticalDefocusDiopters);

     Kc = []; Rc = []; Ks = []; Rs = [];
     for cellIndex = 1:size(fittedDoGParams,1)
        params = fittedDoGParams(cellIndex,:);
        if (isempty(rcDegs))
            Kc(cellIndex) = params(1); Rc(cellIndex) = params(2);
            KsOverKc = params(3); RsOverRc = params(4);
        else
            Kc(cellIndex) = params(1); Rc(cellIndex) = rcDegs;
            KsOverKc = params(2); RsOverRc = params(3);
        end
        Ks(cellIndex) = Kc (cellIndex) * KsOverKc; 
        Rs(cellIndex) = Rc(cellIndex) * RsOverRc;
     end

     maxRsMcells = min([2.2 1.1*max(Rs)*60]);
     
     figure(20);
     maxRange = max([maxRsMcells maxRsLcells]);
     hold(gca, 'on')
     scatter(Rc*60, Rs*60, 16^2, 'filled', 'MarkerFaceAlpha', 0.5, ...
         'MarkerFaceColor', [0.5 1 0.5], 'MarkerEdgeColor', [0 0.5 0], ...
         'LineWidth', 1.0);
     plot([0 maxRange], [0 maxRange], 'k-', 'LineWidth', 1.0);
     xlabel('Rc (arcmin)');
     ylabel('Rs (arcmin)');

     set(gca, 'FontSize', 24, 'XLim', [0 maxRange], 'YLim', [0 maxRange], ...
         'XTick', 0:0.25:2, 'YTick', 0:0.25:6);
     grid(gca, 'on');
     axis(gca, 'square');

     figure(21);
     minRsRcRatio = 0;
     maxRsRcRatio = 10;
     tickLevels = 0:0.5:10;
     tickLabels = {'0', '', '1', '', '2', '', '3', '', '4', '', '5', '', '6', '', '7', '', '8', '', '9', '', '10'};
     scaling = 'Linear';

     
     hold(gca, 'on');
     scatter(gca,Rc/meanFovealConeRcDegs, Rs/meanFovealConeRcDegs, 16^2, 'filled', ...
         'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', [0 0.5 0], 'MarkerFaceColor', [0.5 1 0.5], 'LineWidth',1.0);

     for k = 1:numel(Rc)
         text(gca, Rc(k)/meanFovealConeRcDegs+0.1, Rs(k)/meanFovealConeRcDegs, sprintf('M%d', k), 'FontSize', 12);
     end
     
     
     plot(gca, [minRsRcRatio maxRsRcRatio],[minRsRcRatio maxRsRcRatio], 'k-', 'LineWidth', 1.0);
     
     
     set(gca, 'FontSize', 24, 'XLim', [minRsRcRatio maxRsRcRatio], 'YLim', [minRsRcRatio maxRsRcRatio], ...
         'XTick', tickLevels, 'YTick', tickLevels, ...
         'XTickLabel', tickLabels, 'YTickLabel', tickLabels, ...
         'XScale', scaling, 'YScale', scaling);
     xlabel(gca, 'RGC Rc / foveal cone Rc ratio');
     ylabel(gca, 'RGC Rs / foveal cone Rs ratio');
     grid(gca, 'on');
     axis(gca, 'square');
     
     
     figure(22);
     minRsRcRatio = 0.5;
     maxRsRcRatio = 20;
     tickLevels = 0:20;
     

     hold(gca, 'on');
     scatter(gca, 0*Rc+0.01, Rs./Rc, 16^2, 'filled', ...
         'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', [0 0.5 0], 'MarkerFaceColor', [0.5 1 0.5], 'LineWidth',1.0);
     
     % Add Cronner&Kaplan data
     [Rc, Rs] = CronerKaplanFig4Data();
     
     scatter(gca, Rc.eccDegs, Rs.radiusDegs ./ Rc.radiusDegs, 12^2, 's', 'filled', ...
         'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', [0 0.5 0], 'MarkerFaceColor', [0.5 0.5 0.5], 'LineWidth',1.0);
     
     set(gca, 'FontSize', 24, 'XLim', [0.01 10], 'YLim', [minRsRcRatio maxRsRcRatio], ...
         'XTick', [0.01 0.03 0.1 0.3 1 3 10 30], 'YTick', tickLevels, ...
         'YTickLabel', tickLabels, ...
         'XScale', 'log', 'YScale', 'linear');
     xlabel(gca, 'eccentricity (degs)');
     ylabel(gca, 'Rs / Rc ratio');
     grid(gca, 'on');
     
     
     
     if (isempty(rcDegs))
        figName = sprintf('summary_freeRc_defocus_%2.3fD.pdf', opticalDefocusDiopters);
     else
        figName = sprintf('summary_Rc_%2.3farcmin_defocus_%2.3fD.pdf', rcDegs*60, opticalDefocusDiopters);
     end

     NicePlot.exportFigToPDF(figName, hFigA, 300);
     
     if (isempty(rcDegs))
        figName = sprintf('summary2_freeRc_defocus_%2.3fD.pdf', opticalDefocusDiopters);
     else
        figName = sprintf('summary2_Rc_%2.3farcmin_defocus_%2.3fD.pdf', rcDegs*60, opticalDefocusDiopters);
     end

     NicePlot.exportFigToPDF(figName, hFigB, 300);
     

end

function [yFits, sfHR, fittedDoGParams, rmsErrors] = ...
    fitSpatialTransferFunctions(coneType, sfs, mtfs, mtfStandardDev, ...
    lowerBoundForRcDegs, determineLowerBoundForRsToRcForEachCell, ...
    rcDegs, opticalDefocusDiopters)

    
    cellsNum = size(mtfs,1);
    sfHR = linspace(sfs(1), sfs(end), 100);

    rowsNum = 2;
    colsNum = 11;
    sv = NicePlot.getSubPlotPosVectors(...
                       'colsNum', colsNum, ...
                       'rowsNum', rowsNum, ...
                       'heightMargin',  0.03, ...
                       'widthMargin',    0.02, ...
                       'leftMargin',     0.02, ...
                       'rightMargin',    0.00, ...
                       'bottomMargin',   0.00, ...
                       'topMargin',      0.05);

    

    if (isempty(mtfStandardDev))
       multiStartSolver = 'lsqcurvefit';
    else
       multiStartSolver = 'fmincon';
    end
                
    if (~determineLowerBoundForRsToRcForEachCell)
        lowerBoundForRsToRc = 1.0*ones(1,cellsNum);
        
    else
        lowerBoundsForRsToRc = 0.5:0.25:5;
    
        for iLowerBoundIndex = 1:numel(lowerBoundsForRsToRc)
            lowerBoundForRsToRc  = lowerBoundsForRsToRc(iLowerBoundIndex);
            for cellIndex = 1:cellsNum
                y = mtfs(cellIndex,:);
                yError = mtfStandardDev(cellIndex,:);
                
                [~, ~, rmsErrors(iLowerBoundIndex , cellIndex)] = ...
                            fitDogModelToOTF(...
                                sfs, y, yError, ...
                                rcDegs, sfHR, ...
                                lowerBoundForRcDegs, ...
                                lowerBoundForRsToRc, ...
                                multiStartSolver);
            end
        end
        
        lowerBoundForRsToRc = ones(1, cellsNum);
        if (isempty(rcDegs))
            if (opticalDefocusDiopters == 0)
                if (~isempty(strfind(coneType, 'M')))
                    lowerBoundForRsToRc = [1. 2.25 1. 1.75];
                else
                    lowerBoundForRsToRc(1) = 1.;
                    lowerBoundForRsToRc(2) = 1.;
                    lowerBoundForRsToRc(3) = 1.;
                    lowerBoundForRsToRc(4) = 1.75;
                    lowerBoundForRsToRc(5) = 1.;
                    lowerBoundForRsToRc(6) = 1.;
                    lowerBoundForRsToRc(7) = 4.5;
                    lowerBoundForRsToRc(8) = 1.;
                    lowerBoundForRsToRc(9) = 1.;
                    lowerBoundForRsToRc(10) = 1.;
                    lowerBoundForRsToRc(11) = 2.0;
                end
            end

            if (opticalDefocusDiopters == 0.067)
                if (~isempty(strfind(coneType, 'M')))
                    lowerBoundForRsToRc = [1. 1. 1. 3];
                else
                    lowerBoundForRsToRc(1) = 1.75;
                    lowerBoundForRsToRc(2) = 2.0;
                    lowerBoundForRsToRc(3) = 1.;
                    lowerBoundForRsToRc(4) = 3.00;
                    lowerBoundForRsToRc(5) = 4.00;
                    lowerBoundForRsToRc(6) = 1.;
                    lowerBoundForRsToRc(7) = 2.75;
                    lowerBoundForRsToRc(8) = 2.00;
                    lowerBoundForRsToRc(9) = 1.;
                    lowerBoundForRsToRc(10) = 1.;
                    lowerBoundForRsToRc(11) = 1.;
                end
            end
        end

        hFig = figure(); clf;
        set(hFig, 'Position', [10 10 2000 550], 'Color', [1 1 1]);
        for cellIndex = 1:cellsNum
            ax = subplot('Position', sv(1,cellIndex).v);
            scatter(ax, lowerBoundsForRsToRc, rmsErrors(:, cellIndex), 100, 'filled',  ...
                'LineWidth', 1.5, 'MarkerEdgeColor', [1 0 0], 'MarkerFaceColor', [1 0.5 0.5], 'MarkerFaceAlpha', 0.5);
            hold(ax, 'on');
            plot(ax, lowerBoundForRsToRc(cellIndex)*[1 1], [min(squeeze(rmsErrors(:, cellIndex))) max(squeeze(rmsErrors(:, cellIndex)))], 'k--', 'LineWidth', 1.5);
            xlabel(ax,'lower bound for Rs/Rc');
            ylabel(ax, 'rms error')
            set(ax, 'YTick', [], 'XTick', 0:0.5:10, 'XLim', [1 5], ...
                'XTickLabel', {'','', '1', '', '2', '', '3', '', '4', '', '5', '', '6', '', '7', '', '8', '', '9', '', '10'});
            set(ax, 'FontSize', 14);
            xtickangle(ax, 0)
            grid(ax, 'on');
            axis(ax, 'square');
        end

        if (isempty(rcDegs))
        figName = sprintf('%s_error_freeRc_defocus_%2.3fD.pdf', coneType,opticalDefocusDiopters);
            else
        figName = sprintf('%s_error_Rc_%2.3farcmin_defocus_%2.3fD.pdf', coneType, rcDegs*60, opticalDefocusDiopters);
        end
        NicePlot.exportFigToPDF(figName, hFig, 300);

        rmsErrors = [];
    end

        
    for cellIndex = 1:cellsNum
            y = mtfs(cellIndex,:);
            yError = mtfStandardDev(cellIndex,:);
            [yFits(cellIndex,:), fittedDoGParams(cellIndex,:), rmsErrors(cellIndex)] = ...
                        fitDogModelToOTF(...
                            sfs, y, yError, ...
                            rcDegs, sfHR, ...
                            lowerBoundForRcDegs, ...
                            lowerBoundForRsToRc(cellIndex), ...
                            multiStartSolver);
    end

    

    % Plot results
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 2000 550], 'Color', [1 1 1]);
    for cellIndex = 1:cellsNum
        ax = subplot('Position', sv(1,cellIndex).v);
        hold(ax, 'on');
        % Plot the std.errors
        if (~isempty(mtfStandardDev))
            for k = 1:size(mtfStandardDev,2)
                plot(sfs(k)*[1 1], mtfs(cellIndex,k)+mtfStandardDev(cellIndex,k)*[-1 1], 'k-', 'LineWidth', 1.0);
            end
        end
        plot(ax, sfs, mtfs(cellIndex,:), 'ko'); 
        plot(ax, sfHR, yFits(cellIndex,:), 'r-', 'LineWidth', 1.5);
        set(ax, 'XLim', [0 60], 'YLim', [-0.2 2.4]);
        set(ax, 'XTick', [1 3 6 10 20 30 60 100], 'XScale', 'log', 'FontSize', 14);
        set(ax, 'YTick', -0.2:0.2:2.4);
        grid(ax, 'on');
        %axis(ax, 'square')
        if (isempty(rcDegs))
            fittedRc = fittedDoGParams(cellIndex,2);
            title(ax, sprintf('Rc (free): %2.3f arc min\n defocus:%0.3fD', fittedRc*60, opticalDefocusDiopters), 'FontWeight', 'Normal', 'FontSize', 12)
        else
            title(ax, sprintf('Rc (fixed): %2.3f arc min\n defocus:%0.3fD', rcDegs*60, opticalDefocusDiopters), 'FontWeight', 'Normal', 'FontSize', 12)
        end

    end

    % Plot the line weigthing function
    retinalSpaceDegs = -0.05:0.001:0.05;
    for cellIndex = 1:cellsNum
        params = fittedDoGParams(cellIndex,:);
        if (isempty(rcDegs))
            Kc = params(1); Rc = params(2);
            KsOverKc = params(3); RsOverRc = params(4);
        else
            Kc = params(1); Rc = rcDegs;
            KsOverKc = params(2); RsOverRc = params(3);
        end
        Ks = Kc * KsOverKc; Rs = Rc * RsOverRc;
        center   =  Kc * Rc * sqrt(pi) * exp(-(retinalSpaceDegs/Rc).^2);
        surround = -Ks * Rs * sqrt(pi) * exp(-(retinalSpaceDegs/Rs).^2);

        ax = subplot('Position', sv(2,cellIndex).v);
        plot(ax, retinalSpaceDegs*60, center, 'r-', 'LineWidth', 1.5);
        hold(ax, 'on');
        plot(ax, retinalSpaceDegs*60, surround, 'b-', 'LineWidth', 1.5);
        plot(ax, retinalSpaceDegs*60, center+surround, 'k-', 'LineWidth', 1.0);
        set(ax, 'XTick', -10:1:10, 'XLim', [-3 3], 'YTick', [], 'FontSize', 14);
        grid(ax, 'on');
        axis(ax, 'square')
        xlabel(ax, 'space (arc min)')
        title(ax, sprintf('Rs/Rc:%2.2f\nKc/Ks:%2.1f', RsOverRc, 1/KsOverKc), ...
            'FontWeight', 'Normal', 'FontSize', 12);
    end

    if (isempty(rcDegs))
        figName = sprintf('%s_analysis_freeRc_defocus_%2.3fD.pdf', coneType,opticalDefocusDiopters);
    else
        figName = sprintf('%s_analysis_Rc_%2.3farcmin_defocus_%2.3fD.pdf', coneType, rcDegs*60, opticalDefocusDiopters);
    end

    NicePlot.exportFigToPDF(figName, hFig, 300);

end
