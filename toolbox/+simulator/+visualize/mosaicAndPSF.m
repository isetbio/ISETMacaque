function hFig = mosaicAndPSF(theConeMosaic,  thePSFdata, visualizedDomainRangeMicrons, inFocusWavelength, varargin)
% Visualize cone mosaic and PSF
%
% Syntax:
%   simulator.visualize.mosaicAndPSF(theConeMosaic,  thePSFdata, visualizedDomainRangeMicrons, inFocusWavelength, varargin)
%
% Description:
%   Visualize cone mosaic and PSF
%
% Inputs:
%    theConeMosaic  
%    thePSFdata
%    visualizedDomainRangeMicrons
%    inFocusWavelength
%
% Outputs:
%    hFig
%
% Optional key/value pairs:
%    'figureHandle'              - 
%    'axesHandle'                - 


    p = inputParser;
    p.addParameter('figureHandle', [], @(x)(isempty(x)||isa(x, 'handle')));
    p.addParameter('axesHandle', [], @(x)(isempty(x)||isa(x, 'handle')));
    p.addParameter('noConeMosaic', false, @islogical);
    p.addParameter('displayXYslices', true, @islogical);

    p.parse(varargin{:});
    
    axesHandle = p.Results.axesHandle;
    figureHandle = p.Results.figureHandle;
    noConeMosaic = p.Results.noConeMosaic;
    displayXYslices = p.Results.displayXYslices;

    if (isempty(axesHandle))
        hFig = figure(2000); clf;
        set(hFig, 'Color', [1 1 1], 'Position', [40 40 550 600]);
        ax = subplot('Position', [0.11 0.1 0.85 0.85]);
    else
        ax = axesHandle;
        hFig = figureHandle;
    end
    
    theConeMosaic.visualize('figureHandle', hFig, ...
        'axesHandle', ax, ...
        'domain', 'microns', ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'visualizedConeApertureThetaSamples', 30, ...
        'domainVisualizationLimits', visualizedDomainRangeMicrons*0.5*[-1 1 -1 1], ...
        'domainVisualizationTicks', struct('x', -50:2:50, 'y', -50:2:50), ...
        'crossHairsOnMosaicCenter', ~true, ...
        'backgroundColor', [0.85 0.85 0.85], ...
        'labelCones', ~noConeMosaic, ...
        'noYLabel', ~true, ...
        'noXlabel', ~true, ...
        'plotTitle', ' ', ...
        'fontSize', 24);
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

    if (displayXYslices)
        % Add horizontal slice through the PSF
        m = (size(visualizedPSF,1)-1)/2+1;
        visualizedPSFslice = squeeze(visualizedPSF(m,:));
        idx = find(abs(visualizedPSFslice) >= 0.000001);
        visualizedPSFslice = visualizedPSFslice(idx);
        
        xx = psfSupportMicronsX(idx);
        yy = -visualizedDomainRangeMicrons*0.5*0 + visualizedPSFslice*visualizedDomainRangeMicrons*0.5;
    
        hL = plot(ax,xx, yy, 'k-', 'LineWidth', 6.0);
        hL.Color = [0 0 0 1];
        hLL = plot(ax,xx, yy, 'w--', 'LineWidth', 4);
        hLL.Color = [1,1, 1,0.7];

        if (1==2)
        % Add vertical slice through the PSF
        visualizedPSFslice = squeeze(visualizedPSF(:,m));
        idx = find(abs(visualizedPSFslice) >= 0.001);
        visualizedPSFslice = visualizedPSFslice(idx);
        xx = visualizedDomainRangeMicrons*0.5*0.95 - visualizedPSFslice*visualizedDomainRangeMicrons*0.95;
        yy = psfSupportMicronsY(idx);
    
        
        hL = plot(ax,xx, yy, '-', 'LineWidth', 6.0);
        hL.Color = [1,1,0.8,0.7];
        plot(ax,xx, yy, 'k-', 'LineWidth', 4);
        end

    end
    set(ax, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3], 'LineWidth', 1.0)
    drawnow;

end
