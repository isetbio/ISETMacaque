function [modelRGCSTF, RGCRFmodel] = STFfromDoGpooledConeMosaicSTFresponses(...
    DoGparams, modelConstants)
% Compute modelRGC STF by applying a DoG-based cone pooling model
%
% Syntax:
%   simulator.modelRGC.STFfromDoGpooledConeMosaicSTFresponses(...
%               DoGparams, modelConstants)
%
% Description:
%   Compute modelRGC STF by applying a DoG-based cone pooling model
%
% Inputs:
%    DoGparams        Vector with DoG params
%    modelConstants   Various constatns of the model
%
% Outputs:
%    modelRGCSTF      The STF of the modelRGC
%    RGCRFmodel       The RF center/surround weights
%
% Optional key/value pairs:
%    None
%     

    % The center gain
    Kc = DoGparams(1);

    % The center characteristic radius in degs
    switch (modelConstants.centerConePoolingScenario)
        case 'single-cone'
            RcDegs = nan;
        case 'multi-cone'
            RcToCenterConeRc = DoGparams(4);
            RcDegs = RcToCenterConeRc * modelConstants.centerConeCharacteristicRadiusDegs;
        otherwise
            error('Unknown rfCenterConePoolingScenario: ''%s''.', modelConstants.centerConePoolingScenario);
    end

    % The surround gain
    KsToKc = DoGparams(2);
    Ks = Kc * KsToKc;

    % The surround characteristic radius in degs
    RsToCenterConeRc = DoGparams(3);
    RsDegs = RsToCenterConeRc * modelConstants.centerConeCharacteristicRadiusDegs;

    % The overall negative dc-offet of the measured STF
    dcOffset = DoGparams(end);
    
    % Determine center cone indices and weights
    [centerConeIndices, centerConeWeights, ...
     centerConesFractionalNum, centroidPosition] = ...
        simulator.modelRGC.coneIndicesAndWeightsForCenter(...
                RcDegs, ...
                modelConstants.centerConeCharacteristicRadiusDegs, ...
                modelConstants.centerConeIndex, ...
                modelConstants.allConePositions);

    % Determine surround cone indices and weights
    [surroundConeIndices, surroundConeWeights] = ...
        simulator.modelRGC.coneIndicesAndWeightsForSurround(RsDegs, ...
        modelConstants.allConePositions, ...
        modelConstants.allConeTypes, ...
        modelConstants.surroundConeTypes, ...
        centroidPosition);

    % Actual center/surround weights
    centerConeWeights = Kc * centerConeWeights;
    surroundConeWeights = Ks * surroundConeWeights;
    
    % Compute RGC responses
    modelRGCmodulations = simulator.modelRGC.poolConeMosaicResponses( ...
            modelConstants.coneMosaicSpatiotemporalActivation(:,:,centerConeIndices), ...
            modelConstants.coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices), ...
            centerConeWeights, ...
            surroundConeWeights);

    % The RGC RF model
    RGCRFmodel = struct(...
        'centerConeIndices', centerConeIndices, ...
        'surroundConeIndices', surroundConeIndices, ...
        'centerConeWeights', centerConeWeights, ...
        'surroundConeWeights', surroundConeWeights);

    % Fit a sinusoid to the time series responses for each spatial frequency
    % The amplitude of the sinusoid is the STFmagnitude at that spatial frequency
    sfsNum = size(modelRGCmodulations,1);
    modelRGCSTF = zeros(1, sfsNum);
    %timeHR = linspace(constants.temporalSupportSeconds(1), constants.temporalSupportSeconds(end), 100);
    
    for iSF = 1:sfsNum
        [~, fittedParams] = ...
            simulator.fit.sinusoidToResponseTimeSeries(...
                modelConstants.temporalSupportSeconds, ...
                modelRGCmodulations(iSF,:), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
        modelRGCSTF(iSF) = dcOffset + fittedParams(1);
    end %iSF
end
