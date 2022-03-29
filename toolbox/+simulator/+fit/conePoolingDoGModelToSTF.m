function fitResults = conePoolingDoGModelToSTF(STFdataToFit, fitParams, theConeMosaic, ...
       rfCenterConeIndex, rfCenterConePoolingScenario, allowableSurroundConeTypes, ...
       coneMosaicSpatiotemporalActivation, temporalSupportSeconds)
% Fit the measured fluorescence STF data for a particular center cone
%
% Syntax:
%   simulator.fit.conePoolingDoGModelToSTF(STFdataToFit, fitParams, ...
%            theConeMosaic, rfCenterConeIndex, rfCenterConePoolingScenario, ...
%            allowableSurroundConeTypes, ...
%            coneMosaicSpatiotemporalActivation, temporalSupportSeconds
%
%
% Description: Fit the measured fluorescence STF data using variants
%              the DoG model operating on ISETBIO model coneMosaicResponses
%              to the same stimuli used to measure the fluorescence STF
%
    
    % Assemble all the constants needed to fit the model so we can pass
    % them to the optimizer function
    modelConstants.centerConeIndex = rfCenterConeIndex;
    modelConstants.centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(rfCenterConeIndex);
    modelConstants.centerConePoolingScenario = rfCenterConePoolingScenario;
    modelConstants.surroundConeTypes = allowableSurroundConeTypes;

    modelConstants.allConePositions = theConeMosaic.coneRFpositionsDegs;
    modelConstants.allConeTypes = theConeMosaic.coneTypes;
    modelConstants.coneMosaicSpatiotemporalActivation = coneMosaicSpatiotemporalActivation;
    modelConstants.temporalSupportSeconds = temporalSupportSeconds;
    
    % Select spatial frequency weighting factors
    switch(fitParams.spatialFrequencyBias)
        case simulator.spatialFrequencyWeightings.standardErrorOfTheMeanBased
            sfWeightingFactors = 1./(STFdataToFit.responseSE);

        case simulator.spatialFrequencyWeightings.boostHighEnd
            sfWeightingFactors = 1./(STFdataToFit.responseSE) .* ...
                                 linspace(0.1,1,numel(STFdataToFit.responseSE));

        case simulator.spatialFrequencyWeightings.flat
            sfWeightingFactors = ones(1,numel(STFdataToFit.responseSE));
    end

    % Ensure that we have correct weights dimensionality
    assert(all(size(sfWeightingFactors) == size(STFdataToFit.responses)), ...
        sprintf('Size of weighting factors does not agree with response size'));


    % DoG param initial values and limits: center gain, kc
    Kc = struct(...    
        'low', 1e-4, ...
        'high', 1e5, ...
        'initial', 1);

    % DoG param initial values and limits: Ks/Kc ratio
    KsToKc = struct(...
        'low', 1e-3, ...
        'high', 1, ...
        'initial', 0.1);

    % DoG param initial values and limits: RsToCenterConeRc ratio
    RsToCenterConeRc = struct(...
        'low', 1.5, ...
        'high', 40, ...
        'initial', 5);

    % DoG param initial values and limits: RcToCenterConeRc ratio (only for
    % mutiple cone rf center model variant
    RcToCenterConeRc = struct(...
        'low', 1.0, ...
        'high', 7.0, ...
        'initial', 1.1);

    switch (rfCenterConePoolingScenario)
        case 'single-cone'
            %                          Kc            kS/kC            RsToCenterConeRc          
            DoGparams.initialValues = [Kc.initial   KsToKc.initial    RsToCenterConeRc.initial];
            DoGparams.lowerBounds   = [Kc.low       KsToKc.low        RsToCenterConeRc.low    ];
            DoGparams.upperBounds   = [Kc.high      KsToKc.high       RsToCenterConeRc.high   ];
            DoGparams.names         = {'Kc',        'kS/kC',         'RsToCenterConeRc'};
        
        case 'multi-cone'
            %                          Kc            kS/kC             RsToCenterConeRc          RcToCenterConeRc    
            DoGparams.initialValues = [Kc.initial   KsToKc.initial    RsToCenterConeRc.initial   RcToCenterConeRc.initial];
            DoGparams.lowerBounds   = [Kc.low       KsToKc.low        RsToCenterConeRc.low       RcToCenterConeRc.low];
            DoGparams.upperBounds   = [Kc.high      KsToKc.high       RsToCenterConeRc.high      RcToCenterConeRc.high];
            DoGparams.names         = {'Kc',        'kS/kC',         'RsToCenterConeRc',         'RcToCenterConeRc'};

        otherwise
            error('Unknown rfCenterConePoolingScenario: ''%s''.', rfCenterConePoolingScenario);
    end
 
    if (fitParams.accountForNegativeSTFdata)
        % Add extra parameter at the end, encoding dcoffset
        negativeIndices = find(STFdataToFit.responses<0);
        if (isempty(negativeIndices))
           dcOffsetInitialValue = 0;
        else
            dcOffsetInitialValue = mean(STFdataToFit.responses(negativeIndices));
        end
        DoGparams.initialValues(numel(DoGparams.initialValues)+1) = dcOffsetInitialValue;
        DoGparams.lowerBounds(numel(DoGparams.lowerBounds)+1) = min([0 min(STFdataToFit.responses(:))]);
        DoGparams.upperBounds(numel(DoGparams.upperBounds)+1) = 0;  % dc-offset can only be negative
        DoGparams.names{numel(DoGparams.names)+1} = 'dcOffset';
    else
        DoGparams.initialValues(numel(DoGparams.initialValues)+1) = 0;
        DoGparams.lowerBounds(numel(DoGparams.lowerBounds)+1) = 0;
        DoGparams.upperBounds(numel(DoGparams.upperBounds)+1) = 0;
        DoGparams.names{numel(DoGparams.names)+1} = 'dcOffset';
    end

    % Prefit test
    modelRGCSTF = simulator.modelRGC.STFfromDoGpooledConeMosaicSTFresponses(...
        DoGparams.initialValues, modelConstants);

    assert(all(size(modelRGCSTF) == size(sfWeightingFactors)), ...
        sprintf('size of ISETBioComputedSTF not compatible with STF'));
    % End of prefit test


    % Ready to fit
    options = optimset(...
            'Display', 'off', ...
            'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
            'GradObj', 'off', ...
            'DerivativeCheck', 'off', ...
            'MaxFunEvals', 10^5, ...
            'MaxIter', 10^3);
    
    % The optimization objective
    objective = @(p) sum(sfWeightingFactors .* (simulator.modelRGC.STFfromDoGpooledConeMosaicSTFresponses(p, modelConstants) - STFdataToFit.responses).^2);

    % Multi-start
    problem = createOptimProblem('fmincon',...
          'objective', objective, ...
          'x0', DoGparams.initialValues, ...
          'lb', DoGparams.lowerBounds, ...
          'ub', DoGparams.upperBounds, ...
          'options', options...
          );
    
    ms = MultiStart(...
          'Display', 'off', ...
          'StartPointsToRun','bounds-ineqs', ...  % run only initial points that are feasible with respect to bounds and inequality constraints.
          'UseParallel', true);
      
    % Run the multi-start
    [DoGparams.bestFitValues,errormulti] = run(ms, problem, fitParams.multiStartsNum);

    % Compute best-fit STF and extract RGCRFmodel cone pooling weights
    [bestFitRGCSTF, bestFitRGCRFmodel, bestFitRGCSTFcenter, bestFitRGCSTFsurround] = simulator.modelRGC.STFfromDoGpooledConeMosaicSTFresponses(...
        DoGparams.bestFitValues, modelConstants);


    % Compute the RMSE of the fit
    bestFitRMSE = sqrt(sum(sfWeightingFactors .* (bestFitRGCSTF - STFdataToFit.responses).^2)/sum(sfWeightingFactors(:)));

    
    fitResults = struct(...
        'DoGparams', DoGparams, ...
        'fittedRGCRF', bestFitRGCRFmodel, ...
        'fittedRMSE', bestFitRMSE, ...
        'fittedSTF', bestFitRGCSTF, ...
        'fittedSTFcenter', bestFitRGCSTFcenter, ...
        'fittedSTFsurround', bestFitRGCSTFsurround);
end