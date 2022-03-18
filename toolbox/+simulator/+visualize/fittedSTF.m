function fittedSTF(hFig, ax, sfSupport, measuredSTF, measuredSTFSE, ...
    fittedSTF, fittedRMSE, isBestPosition, noXLabel, cellIDstring)
% Visualize a fitted STF
%
% Syntax:
%   simulator.visualize.fittedSTF(hFig, ax, sfSupport, ...
%         measuredSTF, measuredSTFSE, fittedSTF, fittedRMSE, ...
%         isBestPosition, noXLabel, cellIDstring)
%
% Description:
%   Visualize a fitted STF
%
% Inputs:
%    ax
%    sfSupport, measuredSTF, measuredSTFSE
%    fittedSTF
%    fittedRMSE
%    isBestPosition, noXLabel
%    cellIDstring
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    hold(ax, 'on')
    % Plot the standard errors
    for iSF = 1:numel(sfSupport)
        plot(ax, sfSupport(iSF)*[1 1],  measuredSTF(iSF) + measuredSTFSE(iSF)*[-1 1], ...
                'k-', 'LineWidth', 1.5);
    end


    % Plot the measured STF in green
    plot(ax,sfSupport, measuredSTF, 'o', ...
            'MarkerFaceColor', [0.4 0.9 0.6], 'MarkerSize', 8, 'LineWidth', 1.0);

    % Plot the fitted STF in orange
    plot(ax,sfSupport, fittedSTF, 'k-', 'Color', [1 0.7 0.2], 'LineWidth', 4);
    plot(ax,sfSupport, fittedSTF, '-', 'Color', [1 0.4 0.0], 'LineWidth', 2);
        
    if (isBestPosition)
        titleColor = [1 0.2 0.4];
    else
        titleColor = [0.3 0.3 0.3];
    end
    
     
    axis(ax, 'square');
    yMax = max([max(measuredSTF(:)) max(fittedSTF(:))]);
    xtickangle(ax, 0);
    set(ax, 'XScale', 'log', 'XLim', [4 64], ...
            'XTick', [4 8 16 32 64 128], 'YLim', [-0.1 0.8], 'YTick', -0.2:0.2:1.0, ...
            'FontSize', 16);
    
    title(ax, sprintf('rmsE:%.3f', fittedRMSE), ...
        'FontWeight', 'Normal', 'FontSize', 14, 'Color', titleColor);
    grid(ax, 'on');

    if (~noXLabel)
        xlabel(ax, 'spatial freq. (c/deg)');
    else
        set(ax, 'XTickLabel', {}, 'YTickLabel', {});
    end

    text(ax, 4.5, 0.7, cellIDstring, 'FontSize', 12);

end