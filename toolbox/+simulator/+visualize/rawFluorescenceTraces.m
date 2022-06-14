function rawFluorescenceTraces(hFig, ax, temporalSupportSeconds, ...
    theResponseTrace, cellIDstring, spatialFrequency, varargin)
% Visualize a fitted STF
%
% Syntax:
%   simulator.visualize.rawFluorescenceTraces(hFig, ax, temporalSupport, ...
%    theTraces, cellIDstring, spatialFrequency, varargin)
%
% Description:
%   Visualize the ra fluorescence traces for a particular cell and a
%   particular spatial frequency
%
% Inputs:
%    ax
%    
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    p = inputParser;
    p.addParameter('noXLabel', false, @islogical);
    p.addParameter('noYLabel', false, @islogical);
    p.addParameter('xLims', [], @isnumeric);
    p.addParameter('yLims', [], @isnumeric);
    p.addParameter('xTicks', [], @isnumeric);
    p.addParameter('xLabel', '', @ischar);
    p.addParameter('yLabel', '', @ischar);
    p.parse(varargin{:});

    xLims = p.Results.xLims;
    yLims = p.Results.yLims;
    xTicks = p.Results.xTicks;
    xLabelString = p.Results.xLabel;
    yLabelString = p.Results.yLabel;
    noXLabel = p.Results.noXLabel;
    noYLabel = p.Results.noYLabel;
    
   
    plot(ax,temporalSupportSeconds, theResponseTrace, '-', ...
                    'Color', [0.8 0.8 0.8], 'LineWidth', 1.0);
    
    xtickangle(ax, 0);
    set(ax,'TickDir','both', 'TickLength',[0.1, 0.01]/4);

    set(ax, 'LineWidth', 1.0, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3], 'FontSize', 18);

    if (~isempty(xLims))
        set(ax, 'XLim', xLims);
    end

    if (~isempty(xTicks))
        set(ax,'XTick', xTicks);
    end

    if (~isempty(yLims))
        set(ax, 'YLim', yLims);
    end

    grid(ax, 'on');

    if (~noXLabel) && (~isempty(xLabelString))
        xlabel(ax, xLabelString);
    else
        set(ax, 'XTickLabel', {});
    end

    if (~noYLabel) && (~isempty(yLabelString))
        ylabel(ax, yLabelString);
    else
        set(ax, 'YTickLabel', {});
    end

    if (~isempty(cellIDstring))
       text(ax, 4.5, -0.05, cellIDstring, 'FontSize', 12);
    end
end

