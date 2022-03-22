function [RGCresponses, centerResponses, surroundResponses] = poolConeMosaicResponses(...
    coneResponsesToRGCcenter, ...
    coneResponsesToRGCsurround, ...
    centerConeWeights, ...
    surroundConeWeights)
% Compute RGC responses by applying a DoG-based cone pooling model
%
% Syntax:
%   simulator.modelRGC.poolConeMosaicResponses(...
%               DoGparams, modelConstants)
%
% Description:
%   Compute RGC responses by applying a DoG-based cone pooling model
%
% Inputs:
%    coneResponsesToRGCcenter
%    coneResponsesToRGCsurround
%    centerConeWeights
%    surroundConeWeights
%
% Outputs:
%    RGCresponses
%    centerResponses
%    surroundResponses
%
% Optional key/value pairs:
%    None
%     


    % Weighted pooling of center model cone responses
    weightedCenterModulations = bsxfun(@times, coneResponsesToRGCcenter, reshape(centerConeWeights, [1 1 numel(centerConeWeights)]));

    % Sum weighted center cone responses
    centerResponses = sum(weightedCenterModulations,3);

    % Weighted pooling of surround model cone responses
    weightedSurroundModulations = bsxfun(@times, coneResponsesToRGCsurround, reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)]));
    
    % Sum weighted surround cone responses
    surroundResponses = sum(weightedSurroundModulations,3);

    % Composite center-surround responses
    RGCresponses = centerResponses - surroundResponses;

end


