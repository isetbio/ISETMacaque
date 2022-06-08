function fittedSTF(hFig, ax, sfSupport, measuredSTF, measuredSTFSE, ...
    fittedSTF, fittedRMSE, isBestPosition, cellIDstring, varargin)
% Visualize a fitted STF
%
% Syntax:
%   simulator.visualize.fittedSTF(hFig, ax, sfSupport, ...
%         measuredSTF, measuredSTFSE, fittedSTF, fittedRMSE, ...
%         isBestPosition, cellIDstring, varargin)
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

    p = inputParser;
    p.addParameter('fittedNeuralSTFcomponents', [], @(x)(isempty(x)||isstruct(x)));
    p.addParameter('noXLabel', false, @islogical);
    p.addParameter('noYLabel', false, @islogical);
    p.addParameter('yAxisScaling', 'linear', @(x)((ischar(x))&&(ismember(x,{'linear', 'log'}))));

    p.parse(varargin{:});
    noXLabel = p.Results.noXLabel;
    noYLabel = p.Results.noYLabel;
    yAxisScaling = p.Results.yAxisScaling;
    fittedNeuralSTFcomponents = p.Results.fittedNeuralSTFcomponents;

    hold(ax, 'on')

    if (isempty(fittedNeuralSTFcomponents))

        % Plot the standard errors
        if (~isempty(measuredSTFSE))
            for iSF = 1:numel(sfSupport)
                plot(ax, sfSupport(iSF)*[1 1],  measuredSTF(iSF) + measuredSTFSE(iSF)*[-1 1], ...
                        'k-', 'LineWidth', 1.5);
            end
        end
    
        % Plot the measured STF in green
        faceColor = [0.3 1 0.4]*0.5;
    
        if (ndims(measuredSTF) == 3) && (size(measuredSTF,3) > 1)
            % Multiple responses - lines
            for iResponse = 1:size(measuredSTF,3)
                faceColor(2) = 0.3+0.7*iResponse/size(measuredSTF,3);
                hp = plot(ax,sfSupport, measuredSTF(1,:,iResponse), '-', ...
                    'Color', faceColor*0.5, 'LineWidth', 1.5);
                hp.Color(4) = 0.3;
            end
            % Means
            faceColor(2) = 1.0;
            hp = plot(ax,sfSupport, mean(measuredSTF,3), '-', ...
                    'Color', faceColor*0.2, 'LineWidth', 1.5);
            %hp.Color(4) = 0.3;
            scatter(ax,sfSupport, mean(measuredSTF,3), 100, 'filled', 'MarkerEdgeColor', [0 0 0], ...
                    'MarkerFaceColor', faceColor, 'MarkerFaceAlpha', 1.0, 'MarkerEdgeAlpha', 1.0, 'LineWidth', 1.0);
        else
            faceColor(2) = 1.0;
            % Single response
            scatter(ax,sfSupport, mean(measuredSTF,3), 100, 'filled', 'MarkerEdgeColor', [0 0 0], ...
                    'MarkerFaceColor', faceColor, 'MarkerFaceAlpha', 1.0, 'MarkerEdgeAlpha', 1.0, 'LineWidth', 1.0);
        end
    
    
        if (~isempty(fittedSTF))
            % Plot the fitted STF in orange
            plot(ax,sfSupport, fittedSTF, 'k-', 'Color', [1 0.7 0.2], 'LineWidth', 4);
            plot(ax,sfSupport, fittedSTF, '-', 'Color', [1 0.4 0.0], 'LineWidth', 2);
        end

    else
        % The neural STF
        max(fittedNeuralSTFcomponents.center)
        max(fittedNeuralSTFcomponents.surround)
        maxY = max([...
            max(fittedNeuralSTFcomponents.center(:)) ...
            max(fittedNeuralSTFcomponents.surround(:)) ...
            ])

        fittedNeuralSTFcomponents.center = fittedNeuralSTFcomponents.center / maxY;
        fittedNeuralSTFcomponents.surround = fittedNeuralSTFcomponents.surround / maxY;
        compositeNeuralSTF = abs(fittedNeuralSTFcomponents.center - fittedNeuralSTFcomponents.surround);
        
        

        plot(ax,fittedNeuralSTFcomponents.sfSupport, compositeNeuralSTF, 'k--',  'LineWidth', 2);
        plot(ax,fittedNeuralSTFcomponents.sfSupport, fittedNeuralSTFcomponents.center, 'r',  'LineWidth', 1.5);
        plot(ax,fittedNeuralSTFcomponents.sfSupport, fittedNeuralSTFcomponents.surround, 'b', 'LineWidth', 1.5);
    end


    if (isBestPosition)
        titleColor = [1 0.2 0.4];
    else
        titleColor = [0.3 0.3 0.3];
    end
    
    axis(ax, 'square');
    xtickangle(ax, 0);
    set(ax,'TickDir','both', 'TickLength',[0.1, 0.01]/4);

    set(ax, 'LineWidth', 1.0, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3]);
    set(ax, 'XScale', 'log', 'XLim', [4 60], ...
            'XTick', [4 6 10 20 40 60], 'YLim', [-0.1 0.8], 'YTick', -0.2:0.2:1.0, ...
            'FontSize', 18);
    set(ax, 'YScale', yAxisScaling);

    if (strcmp(yAxisScaling, 'log'))
        set(ax,'yLim', [0.02 0.8], 'YTick', [0.02 0.05 0.1 0.2 0.4 0.8]);
    end

    if (~isempty(fittedRMSE))
        title(ax, sprintf('rmsE:%.3f', fittedRMSE), ...
            'FontWeight', 'Normal', 'FontSize', 18, 'Color', titleColor);
    end

    grid(ax, 'on');

    if (~noXLabel)
        xlabel(ax, 'spatial freq. (c/deg)');
    else
        set(ax, 'XTickLabel', {});
    end

    if (~noYLabel)
        if (isempty(fittedNeuralSTFcomponents))
            ylabel(ax, 'fluorescence (\DeltaF/F)');
        else
            ylabel(ax, 'neural STF');
        end

    else
        set(ax, 'YTickLabel', {});
    end

    if (~isempty(cellIDstring))
        if (~isempty(fittedNeuralSTFcomponents))
            text(ax, 4.5, -0.05, cellIDstring, 'FontSize', 12);
        else
            text(ax, 4.5, 0.7, cellIDstring, 'FontSize', 12);
        end
    end

    if (~isempty(fittedNeuralSTFcomponents))
        set(ax, 'YLim', [-0.1 1.01]);
    end

end