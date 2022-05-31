function  [coneIndices, coneWeights, conesFractionalNum, centroidPosition] = ...
    coneIndicesAndWeightsForCenter(...
                RcDegs, ...
                centerConeCharacteristicRadiusDegs, ...
                centerConeIndex, ...
                allConePositions)
% Compute center cone indices and weights for the DoG model
%
% Syntax:
%   coneIndices, coneWeights, conesFractionalNum, centroidPosition] = ...
%      simulator.modelRGC.coneIndicesAndWeightsForCenter(...
%              RcDegs, centerConeCharacteristicRadiusDegs, ...
%              centerConeIndex, allConePositions);
%
% Description:
%   Compute center cone indices and weights for the DoG model
%
% Inputs:
%   RcDegs  
%   centerConeCharacteristicRadiusDegs 
%   centerConeIndex 
%   allConePositions
%
% Outputs:
%    coneIndices
%    coneWeights
%
% Optional key/value pairs:
%    None
%     


    % Determine how many cones are feeding into the center as (Rc/coneRc)^2
    conesFractionalNum = (RcDegs/centerConeCharacteristicRadiusDegs)^2;
   
    if (isnan(RcDegs) || (conesFractionalNum <= 1.01))
        % Single cone in RF center
        coneWeights = 1;
        coneIndices = centerConeIndex;
        conesFractionalNum = 1;
        centroidPosition = allConePositions(centerConeIndex,:);
        return;
    end

    % Multiple cones in RF center
    % Find the distances from the centerCone to all other cones
    d = sqrt(sum((bsxfun(@minus, allConePositions, allConePositions(centerConeIndex,:))).^2,2));

    % Sort the distances from lowest to highest
    [~, sortedConeIndices] = sort(d, 'ascend');

    % centerConeIndices is the first ceil(conesFractionalNum)
    sortedConeIndices = sortedConeIndices(1:ceil(conesFractionalNum));

    % Find the weights for the weighted centroid
    centroidWeights(1:floor(conesFractionalNum)) = 1;
    if (conesFractionalNum > floor(conesFractionalNum))
        centroidWeights(floor(conesFractionalNum)+1) = conesFractionalNum - floor(conesFractionalNum);
    end
    

    % Compute weighted centroid position
    for k = 1:numel(centroidWeights)
        weightedPos = allConePositions(sortedConeIndices(k),:) * centroidWeights(k);
        if (k == 1)
            centroidPosition = weightedPos;
        else
            centroidPosition = centroidPosition + weightedPos;
        end
    end
    centroidPosition = centroidPosition / sum(centroidWeights);

    % Gaussian cone weights with cone distance from centroid
    d = sqrt(sum((bsxfun(@minus, allConePositions(sortedConeIndices,:), centroidPosition)).^2,2));
    coneWeights = exp(-(d/RcDegs).^2);
    
    minSensitivity = 0.0001/100;
    idx = find(coneWeights >= minSensitivity);

    % Return indices and connection weights of the center cones
    coneIndices = sortedConeIndices(idx);
    coneWeights = coneWeights(idx);
    coneWeights = coneWeights / sum(coneWeights(:));
    
    coneIndices = reshape(coneIndices, [1 numel(coneIndices)]);
    coneWeights = reshape(coneWeights, [1 numel(coneIndices)]);
end
