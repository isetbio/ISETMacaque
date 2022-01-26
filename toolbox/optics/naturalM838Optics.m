function [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = ...
    naturalM838Optics()

    load('M838_Polychromatic_PSF.mat', ...
        'Z_coeff_M838', 'd_pupil', 'axial_length', ...
        'angularfreqs', 'spatialfreqs',...
        'PSF_420nm', 'PSF_500nm', 'PSF_550nm', ...
        'PSF_620nm', 'PSF_650nm', 'PSF_700nm', ...
        'PSF_750nm', 'PSF_800nm');

    PSFpoly.wavelengthSupport = [420 500 550 620 650 700 750 800];
    PSFpoly.data(:,:,1) = PSF_420nm;
    PSFpoly.data(:,:,2) = PSF_500nm;
    PSFpoly.data(:,:,3) = PSF_550nm;
    PSFpoly.data(:,:,4) = PSF_620nm;
    PSFpoly.data(:,:,5) = PSF_650nm;
    PSFpoly.data(:,:,6) = PSF_700nm;
    PSFpoly.data(:,:,7) = PSF_750nm;
    PSFpoly.data(:,:,8) = PSF_800nm;

    spatialFrequencySupport = angularfreqs;
    spatialSampleSizeDegs = 1/(2*max(spatialFrequencySupport));
    spatialSampleSizeArcMin = spatialSampleSizeDegs*60;
    psfSupportMinutesX = (1:size(PSFpoly.data,2))*spatialSampleSizeArcMin;
    psfSupportMinutesXoriginal = psfSupportMinutesX - mean(psfSupportMinutesX);
    psfSupportMinutesYoriginal = psfSupportMinutesXoriginal;

    % Display the computed PSFs
    hFig = figure(1);
    set(hFig, 'Position', [10 10 1600, 650], 'Color', [1 1 1]);
    for wIndex = 1:numel(PSFpoly.wavelengthSupport)
        ax = subplot(2,4,wIndex);
        theWavePSF = squeeze(PSFpoly.data(:,:,wIndex));
        theWavePSF = theWavePSF / max(theWavePSF(:));
        imagesc(ax,psfSupportMinutesXoriginal, psfSupportMinutesYoriginal, theWavePSF);
        axis(ax, 'image')
        set(ax, 'XLim', 10*[-1 1], 'YLim', 10*[-1 1], 'FontSize', 16);
        if (wIndex >= 5)
            xlabel('space (arc min)');
        end
        title(sprintf('%2.0f nm', PSFpoly.wavelengthSupport(wIndex)));
        colormap(gray);
        drawnow;
    end


    % Compute the optics from the Zernike coeffs
    wavelengthsListToCompute = PSFpoly.wavelengthSupport;
    wavefrontSpatialSamples = 512;
    measPupilDiamMM = d_pupil*1000
    targetPupilDiamMM = measPupilDiamMM;
    micronsPerDegree = WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    wavelengthsListToCompute = PSFpoly.wavelengthSupport; %[750 800];
    measWavelength = 420; 
    showTranslation = false;
    noLCA = true;

    Z_coeff_M838 = 0*Z_coeff_M838;

    [thePSF, ~, ~,~, psfSupportMinutesX, psfSupportMinutesY, theWVF] = ...
        computePSFandOTF(Z_coeff_M838, ...
             wavelengthsListToCompute, wavefrontSpatialSamples, ...
             measPupilDiamMM, ...
             targetPupilDiamMM, measWavelength, showTranslation, ...
             'doNotZeroCenterPSF', ~true, ...
             'micronsPerDegree', micronsPerDegree, ...
             'upsampleFactor', 2, ...
             'flipPSFUpsideDown', true, ...
             'noLCA', noLCA, ...
             'name', 'M838 optics');
   
    dxArcMin = psfSupportMinutesX(2)-psfSupportMinutesX(1)

    
    % Generate the OI from the wavefront map
    theOI = wvf2oiSpecial(theWVF, micronsPerDegree, targetPupilDiamMM);
    
    posVectors =  NicePlot.getSubPlotPosVectors(...
        'rowsNum', 2, 'colsNum', 8, ...
        'rightMargin', 0.00, ...
        'leftMargin', 0.025, ...
        'widthMargin', 0.015, ...
        'heightMargin', 0.05, ...
        'bottomMargin', 0.02, ...
        'topMargin', 0.03);


    hFig = figure(2); clf;
    set(hFig, 'Position', [10 10 1600, 650], 'Color', [1 1 1]);
    psfRange = 1.0;
    thePSF =  thePSF/max(thePSF(:));
    for wIndex = 1:numel(wavelengthsListToCompute)
        ax = subplot('Position', posVectors(1,wIndex).v);
        theWavePSF = squeeze(thePSF(:,:,wIndex));
        %theWavePSF = theWavePSF / max(theWavePSF(:));
        imagesc(ax,psfSupportMinutesX, psfSupportMinutesY, ...
            theWavePSF);
        hold(ax, 'on');
        
        m = round(size(theWavePSF,1)/2)+1;
        plot(psfSupportMinutesX, -psfRange*(3/4)+psfRange*1.5*theWavePSF(m,:), ...
            '-', 'Color', [1 0.2 0.1], 'LineWidth', 1.5);
        axis(ax, 'image');
        axis(ax, 'xy');
        set(ax, 'XLim', psfRange*[-1 1], 'YLim', psfRange*[-1 1], ...
            'XTick', -1:0.2:1, 'YTick', -1:0.2:1, 'FontSize', 16);
        if (wIndex>1)
            set(ax, 'YTickLabel', {});
        end
        grid(ax, 'on');
        ax.GridColor = [0 1 1];
        ax.GridAlpha = 0.3;
        title(ax,sprintf('%2.0f nm', wavelengthsListToCompute(wIndex)));
        xlabel(ax,'space (arc min)');
       
        ax = subplot('Position', posVectors(2,wIndex).v);
        theWavePSF = squeeze(PSFpoly.data(:,:,wIndex));
        theWavePSF = theWavePSF / max(theWavePSF(:));
        imagesc(ax,psfSupportMinutesXoriginal, psfSupportMinutesYoriginal, theWavePSF);
        axis(ax, 'image')
        set(ax, 'XLim', 10*[-1 1], 'YLim', 10*[-1 1], 'XTick', [-9 0 9], 'YTick', [], 'FontSize', 16);
        grid on
        title(sprintf('PSF-%d', wavelengthsListToCompute(wIndex)));
        xlabel('space (arc min)');
        colormap(brewermap(1024, '*greys'));
        drawnow;
    end
end
