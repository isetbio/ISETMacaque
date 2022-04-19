function fittedRGCRF(hFig, axCenter, axSurround, axProfile, ...
    theConeMosaic, fittedRGCRF, noXLabel, noSurroundXLabel)
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

    % Compute the RFcenter profile
    for iCone = 1:numel(fittedRGCRF.centerConeIndices)
        theConeIndex = fittedRGCRF.centerConeIndices(iCone);
        xConePosDegs = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
        coneRcDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(theConeIndex);
        coneProfile = exp(-((xSupportDegs-xConePosDegs)/coneRcDegs).^2);
        if (iCone == 1)
             centerProfile = fittedRGCRF.centerConeWeights(iCone)*coneProfile;
        else
             centerProfile = centerProfile + ...
                             fittedRGCRF.centerConeWeights(iCone)*coneProfile; 
        end
    end % iCone

    % Compute the RFsurround profile
    for iCone = 1:numel(fittedRGCRF.surroundConeIndices)
        theConeIndex = fittedRGCRF.surroundConeIndices(iCone);
        xConePosDegs = theConeMosaic.coneRFpositionsDegs(theConeIndex,1);
        coneRcDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(theConeIndex);
        coneProfile = exp(-((xSupportDegs-xConePosDegs)/coneRcDegs).^2);
        if (iCone == 1)
             surroundProfile = fittedRGCRF.surroundConeWeights(iCone)*coneProfile;
        else
             surroundProfile = surroundProfile + ...
                             fittedRGCRF.surroundConeWeights(iCone)*coneProfile; 
        end
    end % iCone

    % Activation range
    maxActivationRange = max(abs(theSurroundConeWeights(:)));
    
    % XY range
    centerConePositionMicrons = mean(...
        theConeMosaic.coneRFpositionsMicrons(fittedRGCRF.centerConeIndices,:), 1);
    xRangeMicrons = centerConePositionMicrons(1) + 8*[-1 1];
    yRangeMicrons = centerConePositionMicrons(2) + 8*[-1 1];

    domainVisualizationTicks = struct('x', -64:4:64, 'y', -64:4:64);
    domainVisualizationTicksNoY = struct('x', -64:4:64, 'y', []);
    domainVisualizationTicksNoXY = struct('x', [], 'y', []);
    domainVisualizationLimits = [xRangeMicrons(1) xRangeMicrons(2) yRangeMicrons(1) yRangeMicrons(2)];

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
        'noYLabel', noXLabel, ...
        'noXLabel', noXLabel, ...
        'fontSize', 18, ...
        'plotTitle', ' '); 

    if (noSurroundXLabel)
        ticks = domainVisualizationTicksNoXY;
    else
        ticks = domainVisualizationTicksNoY;
    end
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

    % Visualize the RFprofile
    xSupportMicrons = xSupportDegs* WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    maxProfile = 1.05*max([max(centerProfile) max(surroundProfile)]);
    centerProfile = centerProfile/maxProfile;
    surroundProfile = surroundProfile/maxProfile;

    % RF center
    faceColor = 1.7*[100 0 30]/255;
    edgeColor = faceColor; [0.7 0.2 0.2];
    faceAlpha = 0.4;
    lineWidth = 0.1;
    baseline = 0;
    simulator.visualize.rfProfileArea(axProfile, xSupportMicrons, centerProfile, ...
             baseline, faceColor, edgeColor, faceAlpha, lineWidth);
    hold(axProfile, 'on');
    
    % RF surround
    faceColor = [75 150 200]/255;
    edgeColor = faceColor; %[0.3 0.3 0.7];
    simulator.visualize.rfProfileArea(axProfile, xSupportMicrons, -surroundProfile, ...
            baseline, faceColor, edgeColor, faceAlpha, lineWidth);
    plot(axProfile, xSupportMicrons, centerProfile-surroundProfile, 'k-', 'LineWidth', 1.5);
    axis(axProfile, 'square');
    
    grid(axProfile, 'on');
    set(axProfile, 'XLim', xRangeMicrons, 'XTick', domainVisualizationTicks.x, ...
        'YLim', [-1 1], 'YTick', -1:0.25:1, 'YTickLabel', {});
    set(axProfile, 'FontSize', 18);
    if (noSurroundXLabel)
        set(axProfile,'XTickLabel', {});
    else
        xlabel(axProfile, 'space (microns)');
    end
    xtickangle(axProfile, 0)
end
