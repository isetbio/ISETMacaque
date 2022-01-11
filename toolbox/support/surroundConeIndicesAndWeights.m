function [surroundConeIndices, surroundConeWeights] = surroundConeIndicesAndWeights(...
        theConeMosaic, centerModelConeIndex, RsDegs, allowableConeTypes)
% Compute the indices and weights of cones feeding to the RF surround
%
% Syntax:
%   [surroundConeIndices, surroundConeWeights] = surroundConeIndicesAndWeights(...
%        theConeMosaic, centerModelConeIndex, RsDegs, allowableConeTypes)
%
% Description:
%   Compute the indices and weights of cones feeding to the RF surround of
%   a model RGC which is connected theConeMosaic, which has a RF center connected
%   to the centerModelConeIndex model cone, and which has a RF surround that
%   pools signals from cones with a Gaussian weighting function whose 
%   characteristic radius is RsDegs. Only cones of the allowableConeTypes
%   can be included in the surround.
%
% Inputs:
%    theConeMosaic           - The model input cMosaic object
%    centerModelConeIndex    - The index of the cone driving the RGC center
%    RsDegs                  - The characteristic radius of the surround
%                              pooling mechanism
%    allowableConeTypes      - The types of allowable cones feeding into
%                              the surround
%
% Outputs:
%    surroundConeIndices     - The indices of cones feeding into the
%                              surround pooling mechanism
%    surroundConeWeights     - The connection weights of the surround cones
%
% Optional key/value pairs:
%    None
%         

    % The position of the center cone
    theCenterConePosition = theConeMosaic.coneRFpositionsDegs(centerModelConeIndex,:);

    % Gaussian weights for the surround cones    
    d = sqrt(sum((bsxfun(@minus, theConeMosaic.coneRFpositionsDegs, theCenterConePosition)).^2,2));
    surroundWeights = exp(-(d/RsDegs).^2);

    % Threshold sensitivity for inclusion to the surround summation mechanism
    minSensitivity = 1/100;
    surroundConeIndices = find(surroundWeights >= minSensitivity);
    surroundConeWeights = surroundWeights(surroundConeIndices);

    % Only include cones of the allowable cone types
    idx = [];
    for iConeType = 1:numel(allowableConeTypes)
        idx2 = find(theConeMosaic.coneTypes(surroundConeIndices) == allowableConeTypes(iConeType));
        idx = cat(1, idx, idx2);
    end

    % Return indices and connection weights of the surround cones
    surroundConeIndices = surroundConeIndices(idx);
    surroundConeWeights = surroundConeWeights(idx);
    surroundConeIndices = reshape(surroundConeIndices, [1 numel(surroundConeIndices)]);
    surroundConeWeights = reshape(surroundConeWeights, [1 numel(surroundConeIndices)]);
end

