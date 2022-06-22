function fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
    theConeMosaic, fittedRGCRF, cellIDstring, noXLabel, noYLabel, noSurroundXLabel)
% Visualize a fitted RGC model 
%
% Syntax:
%   simulator.visualize.fittedRGCRF(axCenter, axSurround, axProfile, ...
%                theConeMosaic, fittedRGCRF)
%
% Description:
%   Visualize a fitted RGCRF model 
%
% Inputs:
%    axCenter, axSurround, axProfile
%    theConeMosaic
%    fittedRGCRF
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    conesNum = size(theConeMosaic.coneRFpositionsDegs,1);
    % The RF center map
    theCenterConeWeights = zeros(1, conesNum);
    theCenterConeWeights(fittedRGCRF.centerConeIndices) = fittedRGCRF.centerConeWeights;

    % The RF surround map
    theSurroundConeWeights = zeros(1, conesNum);
    theSurroundConeWeights(fittedRGCRF.surroundConeIndices) = -fittedRGCRF.surroundConeWeights;

    % Compute the spatial support for the RF profile
    centerConePositionDegs = mean(...
        theConeMosaic.coneRFpositionsDegs(fittedRGCRF.centerConeIndices,:), 1);
    xSupportDegs = centerConePositionDegs(1) + (-0.1:0.0005:0.1);
    ySupportDegs = centerConePositionDegs(2) + (-0.1:0.0005:0.1);

    % Compute the RFcenter profile
    for iCone = 1:numel(fittedRGCRF.centerConeIndices)
        theConeIndex = fittedRGCRF.centerConeIndices(iCone);
        cone2DProfile = simulator.coneMosaic.Gaussian2DApertureForCone(theConeMosaic, theConeIndex, xSupportDegs, ySupportDegs, 'degs');
        centerCone1DProfiles(iCone,:) = fittedRGCRF.centerConeWeights(iCone) * sum(cone2DProfile,1);
        if (iCone == 1)
             center2DProfile = fittedRGCRF.centerConeWeights(iCone)*cone2DProfile;
        else
             center2DProfile = center2DProfile + ...
                             fittedRGCRF.centerConeWeights(iCone)*cone2DProfile; 
        end
    end % iCone

    % Compute the RFsurround profile
    for iCone = 1:numel(fittedRGCRF.surroundConeIndices)
        theConeIndex = fittedRGCRF.surroundConeIndices(iCone);
        cone2DProfile = simulator.coneMosaic.Gaussian2DApertureForCone(theConeMosaic, theConeIndex, xSupportDegs, ySupportDegs, 'degs');
        surroundCone1DProfiles(iCone,:) = fittedRGCRF.surroundConeWeights(iCone) * sum(cone2DProfile,1);
        if (iCone == 1)
             surround2DProfile = fittedRGCRF.surroundConeWeights(iCone)*cone2DProfile;
        else
             surround2DProfile = surround2DProfile + ...
                             fittedRGCRF.surroundConeWeights(iCone)*cone2DProfile; 
        end
    end % iCone

    % Activation range
    maxActivationRange = max(abs(theSurroundConeWeights(:)));
    
    % XY range
    centerConePositionMicrons = mean(...
        theConeMosaic.coneRFpositionsMicrons(fittedRGCRF.centerConeIndices,:), 1);
    xRangeMicrons = centerConePositionMicrons(1) + 6*[-1 1];
    yRangeMicrons = centerConePositionMicrons(2) + 6*[-1 1];

    domainVisualizationTicks = struct('x', -64:4:64, 'y', -64:4:64);
    domainVisualizationTicksNoY = struct('x', -64:4:64, 'y', []);
    domainVisualizationTicksNoXY = struct('x', [], 'y', []);
    domainVisualizationLimits = [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)];

    if (~isempty(axCenter))
        % Visualize the RF center
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', axCenter, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', domainVisualizationLimits , ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theCenterConeWeights, ...
            'activationRange', 1.2*maxActivationRange*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'noYLabel', true, ...
            'noXLabel', noSurroundXLabel, ...
            'fontSize', 18, ...
            'plotTitle', ' '); 
    end

    if (noSurroundXLabel)
        ticks = domainVisualizationTicksNoXY;
    else
        ticks = domainVisualizationTicksNoY;
    end

    if (~isempty(axSurround))
        % Visualize the RF surround    
        theConeMosaic.visualize(...
            'figureHandle', hFig, 'axesHandle', axSurround, ...
            'domain', 'microns', ...
            'domainVisualizationLimits', domainVisualizationLimits , ...
            'domainVisualizationTicks', ticks, ...
            'visualizedConeAperture', 'lightCollectingArea4sigma', ...
            'activation', theSurroundConeWeights, ...
            'activationRange', 1.2*maxActivationRange*[-1 1], ...
            'activationColorMap', brewermap(1024, '*RdBu'), ...
            'noYLabel', true, ...
            'noXLabel', noSurroundXLabel, ...
            'fontSize', 18, ...
            'plotTitle', ' '); 
    end

    if (~isempty(axProfile))
        % Visualize the RFprofile
        xSupportMicrons = xSupportDegs* WilliamsLabData.constants.micronsPerDegreeRetinalConversion;

        % To generate line weighting profile, sum over rows
        centerLineWeightingFunction = sum(centerCone1DProfiles,1);
        surroundLineWeightingFunction = sum(surroundCone1DProfiles,1);

        maxProfile = 1.0*max([max(centerLineWeightingFunction(:)) max(surroundLineWeightingFunction(:))]);

        centerLineWeightingFunction = centerLineWeightingFunction/maxProfile;
        surroundLineWeightingFunction = surroundLineWeightingFunction/maxProfile;
    
        % RF center
        faceColor = 1.7*[100 0 30]/255;
        edgeColor = faceColor;
        faceAlpha = 0.4;
        lineWidth = 0.1;
        baseline = 0;
        hold(axProfile, 'on');
        for iCone = 1:size(centerCone1DProfiles,1)
            simulator.visualize.rfProfileArea(axProfile, xSupportMicrons, centerCone1DProfiles(iCone,:)/maxProfile, ...
                baseline, faceColor, edgeColor, faceAlpha, lineWidth);
        end
        %plot(axProfile, xSupportMicrons, centerLineWeightingFunction, 'r-', 'LineWidth', 1.5);

        
        % RF surround
        faceColor = [75 150 200]/255;
        edgeColor = faceColor;
        for iCone = 1:size(surroundCone1DProfiles,1)
            simulator.visualize.rfProfileArea(axProfile, xSupportMicrons, -surroundCone1DProfiles(iCone,:)/maxProfile, ...
                baseline, faceColor, edgeColor, faceAlpha, lineWidth);
        end
        %plot(axProfile, xSupportMicrons, -surroundLineWeightingFunction, 'b-', 'LineWidth', 1.5);

        % The difference
        plot(axProfile, xSupportMicrons, centerLineWeightingFunction-surroundLineWeightingFunction, 'k-', 'LineWidth', 1.5);
        axis(axProfile, 'square');
        
        grid(axProfile, 'on');
        set(axProfile, 'XLim', xRangeMicrons, 'XTick', domainVisualizationTicks.x, ...
            'YLim', [-1 1], 'YTick', -1:0.5:1, 'YTickLabel', sprintf('%2.1f\n', -1:0.5:1));
        set(axProfile, 'FontSize', 18);
        if (noXLabel)
            set(axProfile,'XTickLabel', {});
        else
            xlabel(axProfile, 'space (microns)');
        end

        if (noYLabel)
            set(axProfile,'YTickLabel', {});
        else
            ylabel(axProfile, 'sensitivity');
        end
        xtickangle(axProfile, 0);

        if (~isempty(cellIDstring))
            text(axProfile, xRangeMicrons(2) - 0.25*(xRangeMicrons(2)-xRangeMicrons(1)), 0.9, cellIDstring, 'FontSize', 12);
        end

    end


end
