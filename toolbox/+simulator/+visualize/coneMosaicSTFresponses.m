function visHandles = coneMosaicSTFresponses(coneMosaicResponsesFileName, varargin)
% Visualize cone mosaic responses to stimuli of different SFs
%
% Syntax:
%   simulator.visualize.coneMosaicSTFresponses(coneMosaicResponsesFileName, varargin)
%
% Description:
%   Visualize closecone mosaic responses to stimuli of different SFs
%
% Inputs:
%    coneMosaicResponsesFileName       Fullpath to the file containing the computed coneMosaicResponses
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%       

    p = inputParser;
    p.addParameter('framesToVisualize', 1, @(x)(isnumeric(x)));
    p.addParameter('visualizedDomainRangeMicrons', [], @(x)(isempty(x)||(isscalar(x))));
    p.parse(varargin{:});
    framesToVisualize = p.Results.framesToVisualize;
    visualizedDomainRangeMicrons = p.Results.visualizedDomainRangeMicrons;

    % Import the data
    load(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined');

    % Convert to modulations
    b = coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, coneMosaicSpatiotemporalActivation, b), 1./b);

    % Compute activation range
    activationRange = max(abs(coneMosaicSpatiotemporalActivation(:)))*[-1 1];

    % Setup figure layout
    [d, hFig] = figureLayout();
    
    if (isempty(framesToVisualize))
        % Visualize all frames
        visualizedFrames = 1:size(coneMosaicSpatiotemporalActivation,2);
    else
        visualizedFrames = framesToVisualize;
    end

    if (isempty(visualizedDomainRangeMicrons))
        domainVisualizationLimits = [];
    else
        domainVisualizationLimits = visualizedDomainRangeMicrons/2 * [-1 1 -1 1];
    end

    % Ticks
    ticksXY = struct('x', -100:10:100, 'y', -100:10:100);
    ticksXonly = struct('x', -100:10:100, 'y', []);
    ticksYonly = struct('x', [], 'y', -100:10:100);
    ticksNone = struct('x', [], 'y', []);

    % Region of interest
    theROI = regionOfInterest('shape', 'line', ...
                'from', [-visualizedDomainRangeMicrons/2, 0], 'to', [visualizedDomainRangeMicrons/2, 0], ...
                'thickness', 6);

    % Identify cone indices within ROI
    identifiedConeIndices = theROI.indicesOfPointsInside(theConeMosaic.coneRFpositionsMicrons);
    lConeIndices = find(theConeMosaic.coneTypes(identifiedConeIndices) == theConeMosaic.LCONE_ID);
    mConeIndices = find(theConeMosaic.coneTypes(identifiedConeIndices) == theConeMosaic.MCONE_ID);
    identifiedLConeIndices = identifiedConeIndices(lConeIndices );
    identifiedMConeIndices = identifiedConeIndices(mConeIndices );

    % Identified cone x-coords
    identifiedLConeXPositionsMicrons = theConeMosaic.coneRFpositionsMicrons(identifiedLConeIndices ,1);
    identifiedMConeXPositionsMicrons = theConeMosaic.coneRFpositionsMicrons(identifiedMConeIndices ,1);


    for iFrame = 1:numel(visualizedFrames)
        displayedFrameIndex = visualizedFrames(iFrame);
        for iSF = 1:numel(spatialFrequenciesExamined)
            ax = subplot('Position', d(iSF).v);
            if (mod((iSF-1), 5) == 0) && ~(floor((iSF-1)/5) == 2)
                ticks = ticksYonly;
            elseif (floor((iSF-1)/5) == 2) && ~(mod((iSF-1), 5) == 0)
                ticks = ticksXonly;
            elseif (mod((iSF-1), 5) == 0) && (floor((iSF-1)/5) == 2)
                ticks = ticksXY;
            else
                ticks = ticksNone;
            end

            theMosaicActivation = squeeze(coneMosaicSpatiotemporalActivation(iSF,displayedFrameIndex,:));
            identifiedLConeActivations = theMosaicActivation(identifiedLConeIndices);
            identifiedMConeActivations = theMosaicActivation(identifiedMConeIndices);

            theConeMosaic.visualize('figureHandle', hFig, ...
                    'axesHandle', ax, ...
                    'domain', 'microns', ...
                    'domainVisualizationLimits', domainVisualizationLimits, ...
                    'domainVisualizationTicks', ticks, ...
                    'visualizedConeAperture', 'geometricArea', ...
                    'visualizedConeApertureThetaSamples', 60, ...
                    'activation', theMosaicActivation,...
                    'activationRange', activationRange, ...
                    'backgroundColor', [0 0 0], ...
                    'noXLabel', true, ...
                    'noYLabel', true, ...
                    'plotTitle', sprintf('%2.1f c/deg', spatialFrequenciesExamined(iSF)));

             hold(ax, 'on');
    
             yOffset = 0;
             yGain = 30;
             plot(ax, identifiedLConeXPositionsMicrons,  yOffset + yGain*(identifiedLConeActivations)/(activationRange(2)), ...
                 'k-', 'LineWidth', 3.0);
             plot(ax, identifiedMConeXPositionsMicrons,  yOffset + yGain*(identifiedMConeActivations)/(activationRange(2)), ...
                 'k-', 'LineWidth', 3.0);
             plot(ax, identifiedLConeXPositionsMicrons,  yOffset + yGain*(identifiedLConeActivations)/(activationRange(2)), ...
                 'k-', 'LineWidth', 1.5, 'Color', theConeMosaic.lConeColor);
             plot(ax, identifiedMConeXPositionsMicrons,  yOffset + yGain*(identifiedMConeActivations)/(activationRange(2)), ...
                 'k-', 'LineWidth', 1.5, 'Color', theConeMosaic.mConeColor);

             scatter(ax, identifiedLConeXPositionsMicrons,  yOffset + yGain*(identifiedLConeActivations)/(activationRange(2)), ...
                 100, 'filled', 'LineWidth', 1.5, 'MarkerFaceColor', theConeMosaic.lConeColor, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.85);
             scatter(ax, identifiedMConeXPositionsMicrons, yOffset + yGain*(identifiedMConeActivations)/(activationRange(2)), ...
                 100, 'filled', 'LineWidth', 1.5, 'MarkerFaceColor', theConeMosaic.mConeColor, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.85);
             drawnow;
        end
    end

    % Figure and axes handle for plotting the PSF
    visHandles.hFig = hFig;
    visHandles.axPSF = subplot('Position', d(15).v);
end


function [d, hFig] = figureLayout()

    d = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 5, ...
       'heightMargin',  0.1, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.03, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.065, ...
       'topMargin',      0.02);

    d = d';
    d = d(:);

    hFig = figure(); clf;
    set(hFig, 'Position', [10 10 1500 950], 'Color', [1 1 1]);
end

