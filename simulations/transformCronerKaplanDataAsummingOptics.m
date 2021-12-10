function transformCronerKaplanDataAsummingOptics()
    
    [Rc, Rs] = CronerKaplanFig4Data();
    obj = WatsonRGCModel();
    eccSupport = logspace(log10(0.01), log10(40), 50);
    coneSpacingDegs = 2* obj.coneRFSpacingAndDensityAlongMeridian(eccSupport, 'nasal meridian', 'deg', 'deg^2');
    coneSpacingMicrons = coneSpacingDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    coneRcMicrons = 0.204*coneSpacingMicrons*sqrt(2);
    
    
    
    wavelengthSupport = 550;
        
    if (1==2)
        pupilDiameterMM = 3.0;
        opticalDefocusDiopters = 0.0;
        PolansSubject = [];
        eccDirection = [];
        opticsLabel = sprintf('%2.1f mm pupil, defocus:%2.2fD', pupilDiameterMM, opticalDefocusDiopters);
        noLCA = true;
        [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = diffractionLimitedOptics(...
                pupilDiameterMM, wavelengthSupport, ...
                wavelengthSupport, ...
                WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                opticalDefocusDiopters, 'noLCA', noLCA);
            psfSupportMicrons = psfSupportMinutesX/60 * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
            visualRcMicrons{1} = mapRetinalRcToVisualRc(eccSupport, coneRcMicrons, thePSF, psfSupportMicrons, [], [], opticalDefocusDiopters, []);
        legendContents = {'Curcio, nasal meridian', opticsLabel, 'C&K''93 Rc', 'C&K''93 Rs'};
        pdfFilename = sprintf('DiffractionLimited_Defocus%2.2fD.pdf', opticalDefocusDiopters);
    else
        thePSF = [];
        psfSupportMicrons = [];
        pupilDiameterMM = 3.0;
    
        examinedPolansSubjects = [2 6 8 9 10]; % [1:30]; %40]; % [2 6 8 9 10];
        opticalDefocusDiopters = 0.0;
        coneCoupling = ~true;
        opticsLabel = {};
        visualRcMicrons = {};
        for k = 1:numel(examinedPolansSubjects)
            PolansSubject = examinedPolansSubjects(k)
            opticsLabel{numel(opticsLabel)+1} = sprintf('Polans subject %d + %2.2dD blur', PolansSubject, opticalDefocusDiopters);
            
            eccDirection = -1;
            visualRcMicronsDiffractionLimitedOptics1 = mapRetinalRcToVisualRc(eccSupport, coneRcMicrons, thePSF, psfSupportMicrons, PolansSubject, eccDirection, opticalDefocusDiopters, coneCoupling);

            if (isempty(visualRcMicronsDiffractionLimitedOptics1))
                fprintf('Skipping subject %d\n', PolansSubject);
                continue;
            end
            
            eccDirection = 1;
            visualRcMicronsDiffractionLimitedOptics2 = mapRetinalRcToVisualRc(eccSupport, coneRcMicrons, thePSF, psfSupportMicrons, PolansSubject, eccDirection, opticalDefocusDiopters, coneCoupling);
            if (isempty(visualRcMicronsDiffractionLimitedOptics2))
                fprintf('Skipping subject %d\n', PolansSubject);
                continue;
            end
            
            visualRcMicrons{numel(visualRcMicrons)+1} = 0.5*(visualRcMicronsDiffractionLimitedOptics1+visualRcMicronsDiffractionLimitedOptics2);
        end
        if (1==1)
            m = visualRcMicrons{1};
            n = numel(visualRcMicrons)
            for k = 2:n
                m = m + visualRcMicrons{k};
            end
            visualRcMicrons = {};
            visualRcMicrons{1} = m/n;
            if (coneCoupling)
                if (opticalDefocusDiopters~=0)
                    opticsLabel = sprintf('Polans subject (mean) + cone coupling + 2.2fD blur', opticalDefocusDiopters);
                else
                    opticsLabel = sprintf('Polans subject (mean) + cone coupling');
                end
            else
                opticsLabel = sprintf('Polans subject (mean) + %2.2fD blur', opticalDefocusDiopters);
            end
            legendContents = {'Curcio, temporal meridian', opticsLabel, 'C&K''93 Rc', 'C&K''93 Rs'};
        else
            legendContents = {'Curcio, temporal meridian', opticsLabel{1}, opticsLabel{2}, opticsLabel{3}, opticsLabel{4}, opticsLabel{5}, 'C&K''93 Rc', 'C&K''93 Rs'};
        end
        
        
        
        %
        pdfFilename = sprintf('Polans_Defocus%2.2fD_coneCoupling%d.pdf', opticalDefocusDiopters, coneCoupling);
    end
    
    colors = brewermap(6, 'Set1');
    
    hFig = figure(1);
    clf;
    set(hFig, 'Position', [10 10 900 555], 'Color', [1 1 1]);
    ax = subplot('Position', [0.1 0.1 0.86 0.85]);
    
    plot(ax, eccSupport, coneRcMicrons, '--', 'LineWidth', 1.5, 'Color', [1 0.5 .2]);
    hold(ax, 'on')
    for k = 1:numel(visualRcMicrons)
        plot(ax, eccSupport, visualRcMicrons{k}, '-', 'LineWidth', 1.5, 'Color', colors(k,:));
    end
    
    scatter(ax, Rc.eccDegs, Rc.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 100, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.2 0.2 0.2]);
       
    scatter(ax, Rs.eccDegs, Rs.radiusDegs*WilliamsLabData.constants.micronsPerDegreeRetinalConversion, 100, 's', ...
        'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerEdgeColor', [0.2 0.2 0.2]);
    hold(ax, 'off')
    hL = legend(ax,...
           legendContents,...
           'Location', 'EastOutside');
       set(hL, 'color', 'none', 'Box', 'off');
       set(ax, 'Xscale', 'log', 'YScale', 'log', ...
         'XTick', [0.01 0.03 0.1 0.3 1 3 10 30 100],  'XTickLabel', {'0.01', '0.03', '0.1', '0.3', '1', '3', '10', '30', '100'}, ...
         'YTick', [0.3 1 3 10 30 100 300], 'YTickLabel', {'0.3', '1', '3', '10', '30', '100', '300'}, ...
         'XLim', [0.01 50], 'YLim', [0.3 100], 'FontSize', 16);
       axis(ax, 'square');
       grid(ax, 'on');
       xlabel(ax, 'eccentricity (degs)');
       ylabel(ax,'Rc (microns)');
    NicePlot.exportFigToPDF(pdfFilename, hFig, 300);
end

function visualRcMicrons = mapRetinalRcToVisualRc(eccSupport, coneRcMicrons, thePSF, psfSupportMicrons, PolansSubject, eccDirection, opticalDefocusDiopters, coneCoupling)

    if (isempty(thePSF))
        pupilDiameterMM = 3.0;
        wavelengthSupport = 550;
        for iCone = 1:numel(coneRcMicrons)
%            [theOI, thePSFforCone(iCone,:,:), psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = ...
%                 ArtalOptics.oiForSubjectAtEccentricity(PolansSubject, 'right eye', [eccDirection*round(eccSupport(iCone)) 0], ...
%                     pupilDiameterMM, wavelengthSupport, WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
%                     'zeroCenterPSF', true, ...
%                     'inFocusWavelength', wavelengthSupport, ...
%                     'subtractCentralRefraction', true);
               [theOI, thePSFforCone(iCone,:,:), psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = ...  
                PolansOptics.oiForSubjectAtEccentricity(PolansSubject, 'right eye', [eccDirection*round(eccSupport(iCone)) 0], ...
                    pupilDiameterMM, wavelengthSupport, WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                    'zeroCenterPSF', true, ...
                    'inFocusWavelength', wavelengthSupport, ...
                    'subtractCentralRefraction', PolansOptics.constants.subjectRequiresCentralRefractionCorrection(PolansSubject), ...
                    'refractiveErrorDiopters', opticalDefocusDiopters);
            psfSupportMicrons = psfSupportMinutesX/60 * WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
        end
    else
        thePSFtoUse = thePSF / max(thePSF(:));
    end
    

    if (isempty(psfSupportMicrons))
        visualRcMicrons = [];
        return;
    end
    
    dx = psfSupportMicrons(2)-psfSupportMicrons(1);
    rMicrons = 0:dx:100;
    rMicrons = [-fliplr(rMicrons) rMicrons(2:end)];
    [X,Y] = meshgrid(rMicrons, rMicrons);
    
    
    
    for iCone = 1:numel(coneRcMicrons)
        
        if (isempty(thePSF))
            thePSFtoUse = squeeze(thePSFforCone(iCone,:,:));
            thePSFtoUse = thePSFtoUse / max(thePSFtoUse(:));
        end
        
      
        if (coneCoupling)
            surroundConesWeight = exp(-0.4);
            coneSeparation = coneRcMicrons(iCone)/0.204;
            retinalCenterRF0 = exp(-(X/coneRcMicrons(iCone)).^2) .* exp(-(Y/coneRcMicrons(iCone)).^2);
            retinalCenterRF = exp(-(X/coneRcMicrons(iCone)).^2) .* exp(-(Y/coneRcMicrons(iCone)).^2) + ...
                          surroundConesWeight * exp(-((X-coneSeparation)/coneRcMicrons(iCone)).^2) .* exp(-(Y/coneRcMicrons(iCone)).^2) + ...
                          surroundConesWeight * exp(-((X-coneSeparation/2)/coneRcMicrons(iCone)).^2) .* exp(-((Y+coneSeparation*sqrt(3)/2)/coneRcMicrons(iCone)).^2) + ...
                          surroundConesWeight * exp(-((X+coneSeparation/2)/coneRcMicrons(iCone)).^2) .* exp(-((Y-coneSeparation*sqrt(3)/2)/coneRcMicrons(iCone)).^2) + ...
                          surroundConesWeight * exp(-((X-coneSeparation/2)/coneRcMicrons(iCone)).^2) .* exp(-((Y-coneSeparation*sqrt(3)/2)/coneRcMicrons(iCone)).^2);
        else
            retinalCenterRF = exp(-(X/coneRcMicrons(iCone)).^2) .* exp(-(Y/coneRcMicrons(iCone)).^2);
        end
        
        retinalCenterRF = retinalCenterRF / max(retinalCenterRF(:));              
        visualCenterRF = conv2(retinalCenterRF, thePSFtoUse, 'same');
        visualCenterRF = visualCenterRF / max(visualCenterRF(:));
        
        m = (size(visualCenterRF,1)-1)/2+1;
        theVisualSlice = squeeze(sum(visualCenterRF,2));
        theRetinalSlice = squeeze(sum(retinalCenterRF,2));
        theVisualSlice = theVisualSlice' /max(theVisualSlice);
        theRetinalSlice = theRetinalSlice' / max(theRetinalSlice);

        
        [theFittedVisualSlice, fittedParams] = fitGaussian(rMicrons, theVisualSlice, rMicrons, coneRcMicrons(iCone));
        visualRcMicrons(iCone) = fittedParams(3);
        
        if (1==2)
        figure(2);
        clf;
%         subplot(2,2,1);
%         imagesc(retinalCenterRF0); hold on;
%         axis 'image';
%         set(gca, 'XLim', m + 30*[-1 1], 'Ylim', m + 30*[-1 1]);
        
        subplot(2,2,2)
        imagesc(retinalCenterRF);
        axis 'image';
        set(gca, 'XLim', m + 30*[-1 1], 'Ylim', m + 30*[-1 1]);
        
        subplot(2,2,3)
        imagesc(visualCenterRF);
        axis 'image';
        set(gca, 'XLim', m + 30*[-1 1], 'Ylim', m + 30*[-1 1]);
        
        subplot(2,2,4);
        plot(rMicrons, theRetinalSlice, 'k-', 'LineWidth', 1.5); hold 'on';
        plot(rMicrons, theVisualSlice, 'rs', 'MarkerSize', 12, 'LineWidth', 1.5);
        plot(rMicrons, theFittedVisualSlice, 'r-', 'LineWidth', 1.5); 
        set(gca, 'XLim', visualRcMicrons(iCone)*4*[-1 1], 'YLim', [0 1.1]);
        title(sprintf('retinal Rc: %2.2f um, visual Rc: %2.2f um', coneRcMicrons(iCone),   visualRcMicrons(iCone)));
        end
        
        
    end
    

end


function [theFittedSlice, fittedParams] = fitGaussian(spaceMicrons, theSlice, spaceHR, initialRc)
    
    % nlinfit options
    opts.RobustWgtFun = []; %'talwar';
    opts.MaxIter = 1000;
    
    % Model to fit
    GaussianFunction = @(params,sf)(...
                    params(1) * ( exp(-((spaceMicrons-params(2))/params(3)).^2) ));
    
    initialParams = [1   0  initialRc/2];
    lowerBound    = [0   -30  0.1];
    upperBound    = [1   30   100];
    
     % Fit
    % Global optimization
    options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt','Display','off');
    
    fittedParams = lsqcurvefit(GaussianFunction,initialParams, spaceMicrons, theSlice, lowerBound, upperBound, options);
    
    % Generate high-resolution fitted function
    theFittedSlice = GaussianFunction(fittedParams, spaceHR);
    
end

