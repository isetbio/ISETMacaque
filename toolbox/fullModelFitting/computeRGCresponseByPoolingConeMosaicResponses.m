function RGCresponses = computeRGCresponseByPoolingConeMosaicResponses(...
    coneResponsesToRGCcenter, ...
    coneResponsesToRGCsurround, ...
    centerConeWeights, ...
    surroundConeWeights, ...
    Kc, Ks)

    % Weighted pooling of center model cone responses
    weightedCenterModulations = bsxfun(@times, coneResponsesToRGCcenter, reshape(centerConeWeights, [1 1 numel(centerConeWeights)]));

    % Sum weighted center cone responses
    totalCenterResponse = sum(weightedCenterModulations,3);

    % Apply center gain
    centerMechanismModulations = Kc * totalCenterResponse;

    % Weighted pooling of surround model cone responses
    weightedSurroundModulations = bsxfun(@times, coneResponsesToRGCsurround, reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)]));
    
    % Sum weighted surround cone responses
    totalSurroundResponse = sum(weightedSurroundModulations,3);

    % Apply surround gain 
    surroundMechanismModulations = Ks * totalSurroundResponse;

    % Composite center-surround responses
    RGCresponses = centerMechanismModulations - surroundMechanismModulations;

end
