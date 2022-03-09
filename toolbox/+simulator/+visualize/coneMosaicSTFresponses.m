function [d, hFig] = coneMosaicSTFresponses(coneMosaicResponsesFileName, varargin)
% Visualize cone mosaic responses to stimuli of different SFs
%
% Syntax:
%   simulator.visuzlize.coneMosaicSTFresponses(coneMosaicResponsesFileName, varargin)
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

    % Compute activation range
    activationRange = prctile(coneMosaicSpatiotemporalActivation(:), [2 98]);

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

    % Display the response at the first stimulus frame
    for iFrame = 1:numel(visualizedFrames)
        displayedFrameIndex = visualizedFrames(iFrame);
        for iSF = 1:numel(spatialFrequenciesExamined)
            ax = subplot('Position', d(iSF).v);
            theConeMosaic.visualize('figureHandle', hFig, ...
                    'axesHandle', ax, ...
                    'domain', 'microns', ...
                    'domainVisualizationLimits', domainVisualizationLimits, ...
                    'domainVisualizationTicks', struct('x', -100:10:100, 'y', -100:10:100), ...
                    'visualizedConeAperture', 'geometricArea', ...
                    'visualizedConeApertureThetaSamples', 60, ...
                    'activation', squeeze(coneMosaicSpatiotemporalActivation(iSF,displayedFrameIndex,:)),...
                    'activationRange', activationRange, ...
                    'backgroundColor', [0 0 0], ...
                    'plotTitle', sprintf('t = %2.1f msec, (%2.1f c/deg)', temporalSupportSeconds(displayedFrameIndex)*1000, spatialFrequenciesExamined(iSF)));
             drawnow;
        end
    end

end


function [d, hFig] = figureLayout()

    d = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 5, ...
       'heightMargin',  0.12, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.04, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.065, ...
       'topMargin',      0.05);

    d = d';
    d = d(:);

    hFig = figure(); clf;
    set(hFig, 'Position', [10 10 1500 950], 'Color', [1 1 1]);
end

