function hFig = plotModelRGCSTFtimeSeriesResponses(figName, ...
    timeSeriesResponses, temporalSupportSeconds, ...
    timeSeriesResponseFits, temporalSupportSecondsResponseFits, ...
    examinedSpatialFrequencies)
% Plot the model RGC STF time-series responses
%
% Syntax:
%   plotModelRGCSTFtimeSeriesResponses(figName, timeSeriesResponses, temporalSupportSeconds, ...
%       timeSeriesResponseFits, temporalSupportSecondsResponseFits, ...
%       examinedSpatialFrequencies)
%
% Description:
%   Plot the model RGC STF time-series responses and their fits
%
% Inputs:
%    figName                             - the figure name
%    timeSeriesResponses                 - the computed time series responses [sfs x timebins]
%    temporalSupportSeconds              - the response temporal support 
%    timeSeriesResponseFits              - the fitted time series responses
%    temporalSupportSecondsResponseFits  - the fitted reponses temporal support
%    examinedSpatialFrequencies          - the spatial frequencies examined 

% Outputs:
%   hFig  - the generate figure handle
%
%

    hFig = figure();
    set(hFig, 'Position', [10 10 1400 750], 'Color', [1 1 1], 'Name', figName);

    sv = NicePlot.getSubPlotPosVectors(...
        'colsNum', 5, ...
        'rowsNum', 3, ...
        'heightMargin',  0.1, ...
        'widthMargin',    0.05, ...
        'leftMargin',     0.04, ...
        'rightMargin',    0.00, ...
        'bottomMargin',   0.01, ...
        'topMargin',      0.05);
    sv = sv';

    for iSF = 1:numel(examinedSpatialFrequencies)
        ax = subplot('Position', sv(iSF).v);
        plot(ax,temporalSupportSecondsResponseFits, timeSeriesResponseFits(iSF,:), ...
            'r-', 'LineWidth', 1.5);
        hold(ax, 'on');
        plot(ax,temporalSupportSeconds, timeSeriesResponses(iSF,:), ...
            'ko', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5]);
        set(ax, 'YLim', [-1.1 1.1], 'YTick', -1:0.2:1);
        set(ax, 'XTick', 0:0.1:10, 'FontSize', 14);
        if (iSF > 1)
            set(ax, 'YTickLabel', {});
            set(ax, 'XTickLabel', {});
        else
            xlabel(ax,'time (seconds)')
        end

        grid(ax, 'on')  
        title(ax,sprintf('SF: %2.1f c/deg', examinedSpatialFrequencies(iSF)));
    end
end