function hFig = plotModelRGCWeights(figNo, theConeMosaic, centerModelConeIndices, ...
        surroundModelConeIndices, centerConeWeights, surroundConeWeights)
% Plot the model RGC cone weights
%
% Syntax:
%   plotModelRGCWeights(figNo, theConeMosaic, centerModelConeIndices, ...
%       surroundModelConeIndices, centerConeWeights, surroundConeWeights)
%
% Description:
%   Plot the model RGC cone weights
%
% Inputs:
%    figNo                       - the figure number
%    theConeMosaic               - the model cMosaic object
%    centerModelConeIndices      - the indices of cones feeding into the RF center
%    surroundModelConeIndices    - the indices of cones feeding into the RF surround
%    centerConeWeights           - the connection weights of cones feeding into the RF center
%    surroundConeWeights         - the connection weights of cones feeding into the RF surround
%
% Outputs:
%   hFig  - the generate figure handle
%
%

    centerConeTypes = theConeMosaic.coneTypes(centerModelConeIndices);
    surroundConeTypes = theConeMosaic.coneTypes(surroundModelConeIndices);
    centerConesPositions = theConeMosaic.coneRFpositionsMicrons(centerModelConeIndices,:);
    surroundConesPositions = theConeMosaic.coneRFpositionsMicrons(surroundModelConeIndices,:);

    % Plot cones feeding into RGC center
    hFig = figure(figNo); clf;
    set(hFig, 'Position', [20 20 450 450]);
    for k = 1:numel(centerModelConeIndices)
        switch (centerConeTypes(k))
            case theConeMosaic.LCONE_ID
                color = [1 0.5 0.5];
            case theConeMosaic.MCONE_ID
                color = [0.5 0.8 0.5];
            case theConeMosaic.SCONE_ID
                color = [0 0 1];
            otherwise
                error('Unknown cone type')
        end

        plot(centerConesPositions(k,1), centerConesPositions(k,2), 'ko', ...
            'MarkerFaceColor', color, ...
            'MarkerSize', max([1 60*centerConeWeights(k)]), ...
            'LineWidth', 1.5);
        hold 'on'
    end

    % Plot cones feeding into RGC surround
    for k = 1:numel(surroundModelConeIndices)
        switch (surroundConeTypes(k))
            case theConeMosaic.LCONE_ID
                color = [1 0.5 0.5];
            case theConeMosaic.MCONE_ID
                color = [0.5 0.8 0.5];
            case theConeMosaic.SCONE_ID
                color = [0 0 1];
            otherwise
                error('Unknown cone type')
        end
        plot(surroundConesPositions(k,1), surroundConesPositions(k,2), 'ks', ...
            'MarkerFaceColor', color, ...
            'MarkerSize', max([1 60*surroundConeWeights(k)]), ...
            'LineWidth', 1.5);
    end

    minXY = min(surroundConesPositions, [], 1);
    maxXY = max(surroundConesPositions, [], 1);
    rangeX = 0.6*(maxXY(1) - minXY(1));
    rangeY = 0.6*(maxXY(2) - minXY(2));

    meanXY = mean(surroundConesPositions, 1);
    range = max([rangeX rangeY]);
    xRange = round(meanXY(1) + range*[-1 1]);
    yRange = round(meanXY(2) + range*[-1 1]);

    set(gca, 'FontSize', 16, 'XLim', xRange, 'YLim', yRange, ...
        'XTick', xRange(1):2:xRange(end), ...
        'YTick', yRange(1):2:yRange(end))
    axis 'square'
    xlabel('microns');
    ylabel('microns');
end
