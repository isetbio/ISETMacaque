function idx = indicesOfModelConesWithinEccDegs(theConeMosaic, targetConeType, maxEccDegs)
% Return indices of model cones of a target cone type within a max eccentricity
%
% Syntax:
%   idx = indicesOfModelConesWithinEccDegs(theConeMosaic, targetConeType, maxEccDegs)
%
% Description:
%   Return indices of model cones of a target cone type within a max eccentricity
%
% Inputs:
%    theConeMosaic             - The model cMosaic object
%    targetConeType            - The target cone type
%    maxEccDegs                - The max cone eccentricity
%
% Outputs:
%    idx     - indices of cones of target cone type lying within the target eccentricity
%
% Optional key/value pairs:
%    None
%         

    geometryStruct = struct(...
        'units', 'degs', ...
        'shape', 'ellipse', ...
        'center', [0 0], ...
        'minorAxisDiameter', 2*maxEccDegs, ...
        'majorAxisDiameter', 2*maxEccDegs, ...
        'rotation', 0.0);

    idxAllCones = theConeMosaic.indicesOfConesWithinROI(geometryStruct);
    idxTargetConeType = find(theConeMosaic.coneTypes(idxAllCones) == targetConeType);
    idx = idxAllCones(idxTargetConeType);
end