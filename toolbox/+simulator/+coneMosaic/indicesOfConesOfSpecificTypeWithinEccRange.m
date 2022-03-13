function coneIndices = indicesOfConesOfSpecificTypeWithinEccRange(theConeMosaic, ...
              whichCenterConeType,  coneMosaicSamplingParams)
% Find indices of cone of specific type (L or M) within an eccentricity range
%
% Syntax:
%   simulator.coneMosaic.indicesOfConesOfSpecificTypeWithinEccRange(...
%        theConeMosaic, whichCenterConeType, coneMosaicSamplingParams)
%
%
% Description: Find indices of cone of specific type (L or M) within an 
%              eccentricity range
%
%

    switch (upper(whichCenterConeType))
        case 'L'
            targetConeID = theConeMosaic.LCONE_ID;
        case 'M'
            targetConeID = theConeMosaic.MCONE_ID;
        otherwise
            error('whichCenterConeType must be set to either ''L'' or ''M''.')
    end

    % Define geometry struct for the region of interest
    maxEccDegs = coneMosaicSamplingParams.maxEccArcMin/60;
    geometryStruct = struct(...
        'units', 'degs', ...
        'shape', 'ellipse', ...
        'center', [0 0], ...
        'minorAxisDiameter', 2*maxEccDegs, ...
        'majorAxisDiameter', 2*maxEccDegs, ...
        'rotation', 0.0);

    % All cones within the ROI
    idxAllCones = theConeMosaic.indicesOfConesWithinROI(geometryStruct);

    % Select only those cones of the target cone type
    idxTargetConeType = find(theConeMosaic.coneTypes(idxAllCones) == targetConeID);
    idx = idxAllCones(idxTargetConeType);
    
    % sort them according to eccentricity
    p = theConeMosaic.coneRFpositionsMicrons(idx,:);
    [~,sortedIndices] = sort(sum(p.^2,2), 'ascend');
    idx = idx(sortedIndices);

    % Select up to coneMosaicSamplingParams.positionsExamined number of
    % these cones
    if (numel(idx)>coneMosaicSamplingParams.positionsExamined)
        skip = round(numel(idx)/coneMosaicSamplingParams.positionsExamined);
        idx = idx(1:skip:end);
        if (numel(idx) > coneMosaicSamplingParams.positionsExamined)
           idx = idx(1:coneMosaicSamplingParams.positionsExamined);
        end
    end

    coneIndices = idx;
end