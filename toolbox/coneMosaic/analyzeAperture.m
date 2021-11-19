function [spatialSupportMicrons, g, frequencySupportCyclesPerDegree, gAmplitudeSpectrum] = ...
    analyzeAperture(sigmaGaussianApertureMicrons, upsampleFactor)

    spatialSupportMicrons = 20*[-1 1];
    spatialSampleMicrons = WilliamsLabData.constants.pixelSizeMicronsOnRetina/upsampleFactor;
    x = 0:spatialSampleMicrons:spatialSupportMicrons(2);
    spatialSupportMicrons = [-fliplr(x) x(2:end)];
    midPoint = (numel(spatialSupportMicrons)-1)/2+1;
    
    [X,Y] = meshgrid(spatialSupportMicrons,spatialSupportMicrons);
    dx = x(2)-x(1);
    
    characteristicRadiusMicrons = sqrt(2) * sigmaGaussianApertureMicrons
    FWHM_halfMicrons = sqrt(2*log(2)) * sigmaGaussianApertureMicrons
    FWHMmicrons = 2* FWHM_halfMicrons;
    
    rPillbox = characteristicRadiusMicrons;
    areaGauss   = pi * characteristicRadiusMicrons^2
    areaPillbox = pi * rPillbox^2
        

    % Generate Gaussian with an area = 1
    g = 1 / areaGauss * exp(-0.5*(X/sigmaGaussianApertureMicrons).^2).*exp(-0.5*(Y/sigmaGaussianApertureMicrons).^2);
    
    % Generate pillbox with an area = 1
    p = X * 0;
    R = sqrt(X.^2+Y.^2);
    p(abs(R)<=rPillbox) = 1;
    p = 1 / areaPillbox * p;

    % Spatially integrate the gaussian to make sure it integrates to 1.0
    netGauss = sum(g(:))*dx*dx
    
    % Spatially integrate the pillbox to make sure it integrates to 1.0
    netPillbox = sum(p(:))*dx*dx

    
    sv = NicePlot.getSubPlotPosVectors(...
               'colsNum', 3, ...
               'rowsNum', 2, ...
               'heightMargin',  0.09, ...
               'widthMargin',    0.05, ...
               'leftMargin',     0.04, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.05, ...
               'topMargin',      0.02);
           
    hFig = figure(333); clf;
    set(hFig, 'Color', [1 1 1]);
    subplot('Position', sv(1,1).v);
    % Plot the Gaussian aperture
    imagesc(spatialSupportMicrons,spatialSupportMicrons,g);
    xlabel('microns');
    ylabel('microns');
    axis 'image';
    axis 'xy';
    set(gca, 'XLim', [-5 5], 'YLim', [-5 5],  'XTick', -5:1:5, 'YTick', -5:1:5);
    set(gca, 'FontSize', 14);
    title('$A = \pi \times R_c^2 = \pi \times 2 \times \sigma^2$', 'Interpreter', 'latex')
    colormap(brewermap(1024, '*greys'));

    % Plot the pillbox aperture
    subplot('Position', sv(2,1).v);
    imagesc(spatialSupportMicrons,spatialSupportMicrons,p);
    xlabel('microns');
    ylabel('microns');
    axis 'image';
    axis 'xy';
    set(gca, 'XLim', [-5 5],  'YLim', [-5 5], 'XTick', -5:1:5, 'YTick', -5:1:5);
    set(gca, 'FontSize', 14);
    title('$A = \pi \times (\mbox{FWHM}/2)^2 = \pi \times 2 \times ln(2) \times \sigma^2$', 'Interpreter', 'latex')

    % Plot 1-D slices
    subplot('Position', sv(1,2).v);
    plot(spatialSupportMicrons, g(midPoint,:), 'r-', 'LineWidth', 3);
    set(gca, 'XLim', [-5 5], 'XTick', -5:1:5, 'YTick', 0:0.1:1.0, 'YLim', [0 0.5]);
    grid on;
    xlabel('microns');
    hold on

    % Label the +/- 1 sigma region
    % +/-1 sigma
    plot(sigmaGaussianApertureMicrons*[-1 1], max(g(:))*exp(-0.5)*[1 1], 'ro-', 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 2.0);
    %text(sigmaGaussianApertureMicrons+0.1, max(g(:))*exp(-0.5), '\pm  \sigma', 'FontSize', 14);

    % Label the +/- characteristic radius  region
    plot(characteristicRadiusMicrons *[-1 1], max(g(:))*exp(-1)*[1 1], 'ro-', 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 2.0);
    %text(characteristicRadiusMicrons+0.1, max(g(:))*exp(-1), '\pm  R_c(\surd{2} \times \sigma)', 'FontSize', 14);

    % FWHM
    plot(FWHM_halfMicrons*[-1 1], max(g(:))*0.5*[1 1], 'ro-', 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 2.0);
    grid on;
    box off
    %text(FWHM_halfMicrons+0.1, max(g(:))*0.5, 'FWHM: 2 \times \surd{(2 \times ln(2)} \times \sigma ', 'FontSize', 14);
    axis 'square';
    %title(sprintf('area: %2.3f', netGauss));
    set(gca, 'FontSize', 20);
    
    subplot('Position', sv(2,2).v);
    plot(spatialSupportMicrons, p(midPoint,:), 'k-', 'LineWidth', 1.5); hold on
    plot(spatialSupportMicrons, g(midPoint,:), 'r-', 'LineWidth', 1.5);
    plot(characteristicRadiusMicrons *[-1 1], max(g(:))*exp(-1)*[1 1], 'ro-', 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.0);
    text(characteristicRadiusMicrons+0.1, max(g(:))*exp(-1), '\pm  R_c (\surd{2} \times \sigma)', 'FontSize', 14);

    axis 'square';
     set(gca, 'XLim', [-5 5], 'XTick', -5:1:5, 'YTick', 0:0.1:1.0, 'YLim', [0 0.5]);
    grid on;
    set(gca, 'FontSize', 14);
    xlabel('microns');
    
    load('/Volumes/SSDdisk/MATLAB/projects/ISETMacaque/toolbox/dataResources/coneMosaicM838.mat', 'cm');
    load('SpatialFrequencyData_M838_OD_2021.mat','otf', 'freqs');
    diffractionLimitedOTF.sf = freqs;
    diffractionLimitedOTF.otf = otf;
    
    
    subplot('Position', sv(1,3).v);
    [~,gAmplitudeSpectrum, frequencySupportCyclesPerDegree] = ...
        analyze1DSpectrum(spatialSupportMicrons/cm.micronsPerDegree, ...
        g(midPoint,:), 'KaiserWindow', 1, 'none');
    
    theOTF = interp1(diffractionLimitedOTF.sf, diffractionLimitedOTF.otf, frequencySupportCyclesPerDegree);
    gAmplitudeSpectrumConePlusOTF = gAmplitudeSpectrum .* theOTF ;
    plot(frequencySupportCyclesPerDegree, gAmplitudeSpectrumConePlusOTF/max(gAmplitudeSpectrumConePlusOTF)* max(diffractionLimitedOTF.otf), 'r-', 'LineWidth', 1.5); hold on;
    xlabel('spatial frequency (c/deg)');
    ylabel('OTF');
    set(gca, 'XLim', [4 60], 'XTick', [5 10 20 40 60], 'YLim', [0 1], 'XScale', 'log', 'FontSize', 14)
    grid on
    axis 'square'
    
    subplot('Position', sv(2,3).v);
    [~,pAmplitudeSpectrum, frequencySupportCyclesPerDegree] = analyze1DSpectrum(spatialSupportMicrons/cm.micronsPerDegree, ...
        p(midPoint,:), 'KaiserWindow', 1, 'none');
    pAmplitudeSpectrumConePlusOTF = pAmplitudeSpectrum .* theOTF;
    plot(frequencySupportCyclesPerDegree, pAmplitudeSpectrumConePlusOTF/max(pAmplitudeSpectrumConePlusOTF)* max(diffractionLimitedOTF.otf), 'k-', 'LineWidth', 1.5); hold on
    plot(frequencySupportCyclesPerDegree, gAmplitudeSpectrumConePlusOTF/max(gAmplitudeSpectrumConePlusOTF)* max(diffractionLimitedOTF.otf), 'r-', 'LineWidth', 1.5);
    set(gca, 'XLim', [4 60], 'XTick', [5 10 20 40 60], 'YLim', [0 1], 'XScale', 'log', 'FontSize', 14)
    xlabel('spatial frequency (c/deg)');
    ylabel('OTF');
    grid on
    axis 'square'
end
