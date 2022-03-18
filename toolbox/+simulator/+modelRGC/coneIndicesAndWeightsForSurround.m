function [coneIndices, coneWeights] = coneIndicesAndWeightsForSurround(...
    RsDegs, allConePositions, allConeTypes, allowableSurroundConeTypes, centerPosition)
% Compute surround cone indices and weights for the DoG model
%
% Syntax:
%   simulator.modelRGC.sconeIndicesAndWeightsForSurround(...
%              RsDegs, allConePositions, allConeTypes, 
%              allowableSurroundConeTypes, centerPosition)
%
% Description:
%   Compute surround cone indices and weights for the DoG model
%
% Inputs:
%    RsDegs
%    allConePositions
%    allConeTypes
%    allowableSurroundConeTypes
%    centerPosition 
%
% Outputs:
%    coneIndices
%    coneWeights
%
% Optional key/value pairs:
%    None
%     

    % Gaussian weights for the surround cones    
    d = sqrt(sum((bsxfun(@minus, allConePositions, centerPosition)).^2,2));
    weights = exp(-(d/RsDegs).^2);

    % Threshold sensitivity for inclusion to the surround summation mechanism
    minSensitivity = 1/100;
    coneIndices = find(weights >= minSensitivity);
    coneWeights = weights(coneIndices);

    % Only include cones of the allowable cone types
    idx = [];
    for iConeType = 1:numel(allowableSurroundConeTypes)
        idx2 = find(allConeTypes(coneIndices) == allowableSurroundConeTypes(iConeType));
        idx = cat(1, idx, idx2);
    end

    % Return indices and connection weights of the surround cones
    coneIndices = coneIndices(idx);
    coneWeights = coneWeights(idx);
    coneIndices = reshape(coneIndices, [1 numel(coneIndices)]);
    coneWeights = reshape(coneWeights, [1 numel(coneIndices)]);
end
