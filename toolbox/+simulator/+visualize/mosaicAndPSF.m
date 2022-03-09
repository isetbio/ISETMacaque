function mosaicAndPSF(theConeMosaic,  thePSFdata, visualizedDomainRangeMicrons, inFocusWavelength)

    hFig = figure(2000); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [40 40 550 600]);
    ax = subplot('Position', [0.1 0.1 0.85 0.85]);
    theConeMosaic.visualize('figureHandle', hFig, ...
        'axesHandle', ax, ...
        'domain', 'microns', ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'visualizedConeApertureThetaSamples', 30, ...
        'domainVisualizationLimits', visualizedDomainRangeMicrons*0.5*[-1 1 -1 1], ...
        'domainVisualizationTicks', struct('x', -20:20:20, 'y', -20:20:20), ...
        'crossHairsOnMosaicCenter', true, ...
        'labelCones', true, ...
        'noYLabel', ~true, ...
        'noXlabel', ~true, ...
        'plotTitle', ' ', ...
        'fontSize', 18);
    psfSupportMicronsX = thePSFdata.supportMinutesX/60*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    psfSupportMicronsY = thePSFdata.supportMinutesY/60*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;

    
    % Add contour plot of the PSF
    hold(ax, 'on');
    cmap = brewermap(1024,'greys');
    alpha = 0.5;
    contourLineColor = [0.0 0.0 0.0];
    [~,idx] = min(abs(thePSFdata.supportWavelengthNM-inFocusWavelength));
    visualizedPSF = squeeze(thePSFdata.psf(:,:,idx));
    visualizedPSF = visualizedPSF / max(visualizedPSF(:));
    cMosaic.semiTransparentContourPlot(ax, psfSupportMicronsX, psfSupportMicronsY, visualizedPSF, [0.03:0.15:0.95], cmap, alpha, contourLineColor);

    % Add horizontal slice through the PSF
    m = (size(visualizedPSF,1)-1)/2+1;
    visualizedPSFslice = squeeze(visualizedPSF(m,:));
    idx = find(abs(visualizedPSFslice) >= 0.01);
    visualizedPSFslice = visualizedPSFslice(idx);
    
    xx = psfSupportMicronsX(idx);
    yy = -visualizedDomainRangeMicrons*0.5*0.95 + visualizedPSFslice*visualizedDomainRangeMicrons*0.5*0.9;
    %shadedAreaPlot(ax,xx,yy, -visualizedDomainRangeMicrons*0.5*0.95, [0.8 0.8 0.8], [0.1 0.1 0.9], 0.5, 1.5);

    hL = plot(ax,xx, yy, '-', 'LineWidth', 4.0);
    hL.Color = [1,1,0.8,0.7];
    plot(ax,xx, yy, 'k-', 'LineWidth', 2);
    
    % Add vertical slice through the PSF
    visualizedPSFslice = squeeze(visualizedPSF(:,m));
    idx = find(abs(visualizedPSFslice) >= 0.01);
    visualizedPSFslice = visualizedPSFslice(idx);
    xx = visualizedDomainRangeMicrons*0.5*0.95 - visualizedPSFslice*visualizedDomainRangeMicrons*0.5*0.9;
    yy = psfSupportMicronsY(idx);
    %shadedAreaPlot(ax,xx,yy, -visualizedDomainRangeMicrons*0.5*0.95, [0.8 0.8 0.8], [0.1 0.1 0.9], 0.5, 1.5);

    
    hL = plot(ax,xx, yy, '-', 'LineWidth', 4.0);
    hL.Color = [1,1,0.8,0.7];
    plot(ax,xx, yy, 'k-', 'LineWidth', 2);
    drawnow;

    
    
%     if (PolansSubject == 0)
%         title(['PSF focused at \lambda = ' sprintf('%2.0fnm', inFocusWavelength)], 'FontWeight', 'normal');
%     else
%         title(['PSF focused at \lambda = ' sprintf('%2.0fnm (Polans subj. %d)', inFocusWavelength, PolansSubject)], 'FontWeight', 'normal');
%     end
%     drawnow;
%     NicePlot.exportFigToPDF(sprintf('PolansSubject%dPSFonMosaic.pdf', PolansSubject), hFig, 300);
end
