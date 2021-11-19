function plotModelledRGCFits(theFixedRcFittedModeledRGCOTFHR, theFreeRcFittedModeledRGCOTFHR, dFresponsesRGCs, dFresponsesStdRGCs, ...
    theFittedModelConeOTFHR, modelConeOTFs, theFixedRcMicrons, theFixedRcDoGParams, theFreeRcDoGParams, ...
    theFixedRcRMSErrors, theFreeRcRMSErrors,  ...
    lowerBoundForRsToRcInFreeRcFits, lowerBoundForRsToRc, ...
    sf, sfHR, coneString, coneColor, videoFilename)         
                   
    rgcCellsNum = size(theFixedRcFittedModeledRGCOTFHR,1);
    modelConesNum = size(theFixedRcFittedModeledRGCOTFHR,2);

            
    rowsNum = 3;
    colsNum = 4;
    sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.04, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.02);
     sv = sv';            
     
     videoOBJ1 = VideoWriter(videoFilename, 'MPEG-4');
     videoOBJ1.FrameRate = 10;
     videoOBJ1.Quality = 100;
     videoOBJ1.open();
     
     videoOBJ2 = VideoWriter(sprintf('%s_RFs_fixedRc', videoFilename), 'MPEG-4');
     videoOBJ2.FrameRate = 10;
     videoOBJ2.Quality = 100;
     videoOBJ2.open();
     
     videoOBJ3 = VideoWriter(sprintf('%s_RFs_freeRc', videoFilename), 'MPEG-4');
     videoOBJ3.FrameRate = 10;
     videoOBJ3.Quality = 100;
     videoOBJ3.open();
     
     
     
     spatialSupportMicrons = linspace(-9,9,200);
     
     hFig2 = figure(11); clf;
     set(hFig2, 'Color', [1 1 1],'Position', [300 200 2100 1300]);
     
     % The RFs when Rc is fixed to that of the modelCone
     for iCone = 1:modelConesNum
        % The input cone OTF
        ax = subplot('Position', sv(1).v);
        cla(ax);
        drawSubergions(ax, spatialSupportMicrons, theFixedRcMicrons(iCone), [], [], coneColor*0.5);
            
        for iRGC = 1:rgcCellsNum
            ax = subplot('Position', sv(iRGC+1).v);
            cla(ax);
            Rc = theFixedRcMicrons(iCone);
            RsOverRc = theFixedRcDoGParams(iRGC,iCone,3);
            Rs = RsOverRc * Rc;
            KsOverKc = theFixedRcDoGParams(iRGC,iCone,2);
            rfMax = drawSubergions(ax, spatialSupportMicrons, Rc, Rs, KsOverKc, coneColor*0.5, '-');
            
            text(ax, -9, rfMax*0.75, sprintf('Rc: %2.2f um\nKc/Ks: %2.2f\nRs/Rc: %2.2f\nrmsError: %2.3f', ...
                       Rc, ...
                       1/KsOverKc, ...
                       RsOverRc, ...
                       theFixedRcRMSErrors(iRGC,iCone)*100), ...
                       'FontSize', 14, 'FontName', 'source code pro', 'Color', coneColor*0.5);
      
        end
        drawnow;
        videoOBJ2.writeVideo(getframe(hFig2));
        NicePlot.exportFigToPDF(sprintf('%s_RFs_fixedRc_coneID_%d.pdf', videoFilename, iCone), hFig2, 300);
     end
     videoOBJ2.close();
    
     
     % The RFs when Rc is free
     hFig3 = figure(12); clf;
     set(hFig3, 'Color', [1 1 1],'Position', [300 200 2100 1300]);
     
     for iCone = 1:modelConesNum
        % The input cone OTF
        ax = subplot('Position', sv(1).v);
        cla(ax);
        
        drawSubergions(ax, spatialSupportMicrons, theFixedRcMicrons(iCone), [], [], [0 0 0]);
            
        for iRGC = 1:rgcCellsNum
            ax = subplot('Position', sv(iRGC+1).v);
            cla(ax);
            freeRcDegs = theFreeRcDoGParams(iRGC,iCone,2);
            freeRcMicrons = freeRcDegs * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
            Rc = freeRcMicrons;
            RsOverRc = theFreeRcDoGParams(iRGC,iCone,4);
            Rs = RsOverRc * Rc;
            KsOverKc = theFreeRcDoGParams(iRGC,iCone,3);
            rfMax = drawSubergions(ax, spatialSupportMicrons, Rc, Rs, KsOverKc, [0 0 0], '--');
            
            text(ax, -9, rfMax*0.75, sprintf('Rc: %2.2f um\nKc/Ks: %2.1f\nRs/Rc: %2.2f (LB:%2.2f)\nrmsError: %2.3f', ...
                     freeRcMicrons, ...
                     1/KsOverKc, ...
                     RsOverRc, ...
                     lowerBoundForRsToRcInFreeRcFits, ...
                     theFreeRcRMSErrors(iRGC,iCone)*100), ...
                     'FontSize', 14, 'FontName', 'source code pro', 'Color', [0 0 0]);
                   
        end
        drawnow;
        videoOBJ3.writeVideo(getframe(hFig3));
        NicePlot.exportFigToPDF(sprintf('%s_RFs_freeRc_coneID_%d.pdf', videoFilename, iCone), hFig3, 300);
     
     end
     videoOBJ3.close();
     
     
     hFig1 = figure(10); clf;
     set(hFig1, 'Color', [1 1 1],'Position', [700 200 2100 1300]);
    
     for iCone = 1:modelConesNum
        % The input cone OTF
        ax = subplot('Position', sv(1).v);
        plot(ax, sf, squeeze(modelConeOTFs(iCone,:)), 'o', ...
                'LineWidth', 1.5, 'MarkerEdgeColor', coneColor*0.5, 'LineWIdth', 1.5, 'MarkerFaceColor', coneColor, 'MarkerSize', 12);
        hold(ax, 'on');
        plot(ax, sfHR, squeeze(theFittedModelConeOTFHR(iCone,:)), '-', 'Color', coneColor*0.5, 'LineWidth', 2); 
        
        hold(ax, 'off');
        set(ax, 'XLim', [4 60], 'YLim', [-0.15 1.0], 'XScale', 'log', 'XTick', [5 10 20 40 60], 'YTick', 0:0.2:1);
        grid(ax, 'on')
        title(sprintf('input cone (Rc = %2.2f microns)', theFixedRcMicrons(iCone)));
        xlabel(ax,'spatial frequency (c/deg)');
        ylabel(ax,'OTF');
        set(ax, 'FontSize', 18);

        for iRGC = 1:rgcCellsNum
            ax = subplot('Position', sv(iRGC+1).v);
            
            errorbar(ax, sf, squeeze(dFresponsesRGCs(iRGC,:)), squeeze(dFresponsesStdRGCs(iRGC,:)), 'o', ...
                'LineWidth', 1.5, 'Color', coneColor*0.5, 'MarkerFaceColor', coneColor, 'MarkerEdgeColor', coneColor*0.5, 'MarkerSize', 12);
            hold(ax, 'on');
            p1 = plot(ax, sf, squeeze(dFresponsesRGCs(iRGC,:)), 'o', ...
                'LineWidth', 1.5, 'MarkerEdgeColor', coneColor*0.5, 'LineWidth', 1.5, 'MarkerFaceColor', coneColor, 'MarkerSize', 12);
            
            p2 = plot(ax, sfHR, squeeze(theFixedRcFittedModeledRGCOTFHR(iRGC,iCone,:)), '-', 'Color', coneColor*0.5, 'LineWidth', 2); 
            p3 = plot(ax, sfHR, squeeze(theFreeRcFittedModeledRGCOTFHR(iRGC,iCone,:)), '--', 'Color', [0 0 0], 'LineWidth', 2); 
            plot(ax, [1 100], [0 0], 'k-');
            hold(ax, 'off');
            set(ax, 'XLim', [3 60], 'YLim', [-0.15 1.0], 'XScale', 'log', 'XTick', [5 10 20 40 60], 'YTick', 0:0.2:1);
            grid(ax, 'on')
            text(ax, 3.2, 0.88, sprintf('Rc: %2.2f um\nKc/Ks: %2.2f\nRs/Rc: %2.2f\nrmsError: %2.3f', ...
                       theFixedRcMicrons(iCone), ...
                       1/theFixedRcDoGParams(iRGC,iCone,2), ...
                       theFixedRcDoGParams(iRGC,iCone,3), ...
                       theFixedRcRMSErrors(iRGC,iCone)*100), ...
                       'FontSize', 14, 'FontName', 'source code pro', 'Color', coneColor*0.5);
            text(ax, 3.2, 0.55, sprintf('Rc: %2.2f um\nKc/Ks: %2.1f\nRs/Rc: %2.2f (LB:%3.2f)\nrmsError: %2.3f', ...
                       theFreeRcDoGParams(iRGC,iCone,2)*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                       1/theFreeRcDoGParams(iRGC,iCone,3), ...
                       theFreeRcDoGParams(iRGC,iCone,4), ...
                       lowerBoundForRsToRcInFreeRcFits, ...
                       theFreeRcRMSErrors(iRGC,iCone)*100), ...
                       'FontSize', 14, 'FontName', 'source code pro', 'Color', [0 0 0]);
           
            
%             lgnHandle = legend(ax, [p1 p2 p3], ...
%                 {'\DeltaF/Fo response', ...
%                  sprintf('fixed Rc model (%2.2f um)', theFixedRcMicrons(iCone)), ...
%                  sprintf('free  Rc model (%2.2f um)', theFreeRcMicrons(iRGC,iCone))}, 'Location', 'NorthWest');
%            set(lgnHandle, 'color','none', 'box', 'off');
            xlabel(ax,'spatial frequency (c/deg)');
            ylabel(ax,'\DeltaF/Fo');
            title(sprintf('measured %s RGC #%d',coneString, iRGC));
            set(ax, 'FontSize', 18, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3]);
            box(ax, 'off');
        end
        drawnow;
        videoOBJ1.writeVideo(getframe(hFig1));
        NicePlot.exportFigToPDF(sprintf('%s_coneID_%d.pdf', videoFilename, iCone), hFig1, 300);
        
        
     end
     videoOBJ1.close();
        
end

function rfMax = drawSubergions(ax, spatialSupportMicrons, Rc, Rs, KsOverKc, centerColor, lineStyle)
      
    baseline=0;
    faceAlpha = 0.7;
    lineWidth = 1.5;
    
    %params(1) = gain
    %params(2) = characteristicRadius
    lineWeightingFunction = @(params,space)(...
                    params(1) * params(2) * sqrt(pi)*exp(-(space/params(2)).^2));
                
    pCenter = [1 Rc];
    centerProfile = lineWeightingFunction(pCenter, spatialSupportMicrons);
    shadedAreaPlot(ax, spatialSupportMicrons, centerProfile, baseline, [0.85 0.85 0.85], centerColor, faceAlpha, lineWidth); 
    
    if (isempty(KsOverKc)) || (isempty(Rs))
        pSurround = [];
        sensitivityRange = [0 max(centerProfile)];
    else
        pSurround = [KsOverKc Rs];
        hold(ax, 'on');
        surroundProfile = lineWeightingFunction(pSurround, spatialSupportMicrons);
        maxCS = max([max(centerProfile) max(surroundProfile)]);
        sensitivityRange = maxCS*[-1 1];
        rfProfile = centerProfile - surroundProfile;
        shadedAreaPlot(ax, spatialSupportMicrons, -surroundProfile, baseline, [0.5 0.5 0.5], [0 0 0],  faceAlpha, lineWidth);
        plot(ax, spatialSupportMicrons, rfProfile, lineStyle, 'Color', [0 0 0], 'LineWidth', 2.0); hold(ax, 'off');
    end
    
    rfMax = max(centerProfile);
    set(ax, 'YLim', sensitivityRange, 'XLim', [spatialSupportMicrons(1) spatialSupportMicrons(end)]);
    set(ax, 'XTick', -9:1:9);
    xlabel(ax, 'space (microns)');
    ylabel(ax, 'sensitivity');
    set(ax, 'FontSize', 18, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3]);
end
            