function [sfSupportCyclesPerDeg, visualizedOTFslice] = visualizeDiffractionLimitedPSF(thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, theOI, visualizedWavelength)
   
    % Extract PSF at the visualized wavelength
    [~,idx] = min(abs(psfSupportWavelength-visualizedWavelength));
    visualizedPSF = squeeze(thePSF(:,:,idx));
    
    theOptics = oiGet(theOI, 'optics');
    theOTF = opticsGet(theOptics, 'otf data');
    sfSupportCyclesPerMM = opticsGet(theOptics, 'otf fx');
    sfSupportCyclesPerDeg = sfSupportCyclesPerMM/1e3*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    visualizedOTF = squeeze(theOTF(:,:,idx));
    visualizedOTF = fftshift(abs(visualizedOTF));
    r = (size(visualizedOTF,1)-1)/2+1;
    visualizedOTFslice = squeeze(visualizedOTF(r,:));  

    % Extract horizontal slice through PSFmax
    r = (size(visualizedPSF,1)-1)/2+1;
    visualizedPSFslice = squeeze(visualizedPSF(r,:));
    visualizedPSFslice = visualizedPSFslice / max(visualizedPSFslice);
    
    hFig = figure(101);
    % The 2D PSF
    subplot(1,3,1)
    imagesc(psfSupportMinutesX, psfSupportMinutesY, visualizedPSF);
    axis 'image'
    set(gca, 'XLim', 2*[-1 1], 'YLim', 2*[-1 1], 'FontSize', 16);
    xlabel('space (arc min)');
    colormap(gray);
    
    subplot(1,3,2);
    plot(psfSupportMinutesX, visualizedPSFslice, 'ko-', 'LineWidth', 1.5);
    set(gca, 'XLim', 2*[-1 1], 'FontSize', 16);
    grid on;
    axis 'square';
    xlabel('space (arc min)');
    
    % The OTF    
    ax = subplot(1,3,3);
    plot(ax,sfSupportCyclesPerDeg, visualizedOTFslice, 'k-');
    hold(ax, 'on');
    load('SpatialFrequencyData_M838_OD_2021.mat', 'otf', 'freqs');
    hold(ax, 'on');
    plot(freqs, otf, 'bo');
    hold(ax, 'off')
    axis 'square'
    set(ax, 'XScale', 'log', 'XLim', [1 100], 'YLim', [0 1], 'FontSize', 16);
    grid on
    xlabel('spatial frequency (c/deg)');
end