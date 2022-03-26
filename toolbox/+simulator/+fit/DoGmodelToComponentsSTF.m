function [DoGparams, theFittedCompositeSTF, ...
         sfHiRes, theFittedCompositeSTFHiRes, ...
         theFittedSTFcenter, theFittedSTFsurround, ...
         theFittedCompositeSTFHiResFullField, ...
         theFittedSTFcenterFullField, theFittedSTFsurroundFullField] = DoGmodelToComponentsSTF(...
                 sf, theCenterSTF, theSurroundSTF, theCompositeSTF, ...
                 centerConeCharacteristicRadiusDegs, ...
                 centerFitWeight, surroundFitWeight, compositeFitWeight)
% Fit the DoG model to the computed components center & surround STFs
%
% Syntax:
%   simulator.fit.DoGmodelToComponentsSTF(sf, theCenterSTF, theSurroundSTF, ...
%        centerConeCharacteristicRadiusDegs)
%
%
% Description: Fit the DoG model to the computed computed components center & surround STFs

    deconvolveStimulus = false;
    if (deconvolveStimulus)
        % Compute the stimulusOTF
        theStimulusOTF = simulator.analyze.stimulusOTF(sf);
        theStimulusOTF = theStimulusOTF * 0 + 1;


        % Before fitting the measured STFs, deconvolved them with the
        % stimulusOTF
        theCenterSTF = theCenterSTF ./ theStimulusOTF;
        theSurroundSTF = theSurroundSTF ./ theStimulusOTF;
        theCompositeSTF = theCompositeSTF ./ theStimulusOTF;
    end
    
    
    % Fitting options 
    options = optimset(...
            'Display', 'off', ...
            'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
            'GradObj', 'off', ...
            'DerivativeCheck', 'off', ...
            'MaxFunEvals', 10^5, ...
            'MaxIter', 10^3);
        
    ms = MultiStart(...
          'Display', 'off', ...
          'StartPointsToRun','bounds-ineqs', ...  % run only initial points that are feasible with respect to bounds and inequality constraints.
          'UseParallel', false);
      
    multiStartsNum = 128;
         
      
    % DoG param initial values and limits: center gain, kc
    Kc = struct(...    
        'low', 1e-4, ...
        'high', 1e4, ...
        'initial', 1);

    % DoG param initial values and limits: Ks/Kc ratio
    KsToKc = struct(...
        'low', 1e-1, ...
        'high', 2, ...
        'initial', 0.1);

    % DoG param initial values and limits: RsToRc ratio
    RsToRc = struct(...
        'low', 0.0, ...
        'high', 7, ...
        'initial', 2);

    % DoG param initial values and limits: RcDegs
    RcDegs = struct(...
        'low', centerConeCharacteristicRadiusDegs*0, ...
        'high', centerConeCharacteristicRadiusDegs*10, ...
        'initial', centerConeCharacteristicRadiusDegs*2);
    
     %                          Kc           kS/kC             RsToRc            RcDegs    
     DoGparams.initialValues = [Kc.initial   KsToKc.initial    RsToRc.initial    RcDegs.initial];
     DoGparams.lowerBounds   = [Kc.low       KsToKc.low        RsToRc.low        RcDegs.low];
     DoGparams.upperBounds   = [Kc.high      KsToKc.high       RsToRc.high       RcDegs.high];
     DoGparams.names         = {'Kc',        'kS/kC',         'RsToRc',         'RcDegs'};
     DoGparams.scale         = {'log',       'log',           'linear',         'linear'};
     
     % The DoG model in the frequency domain
     DoGSTF = @(params,sf)(...
                    params(1)           * ( pi * params(4)^2             * exp(-(pi*params(4)*sf).^2) ) - ...
                    params(1)*params(2) * ( pi * (params(4)*params(3))^2 * exp(-(pi*params(4)*params(3)*sf).^2) ));
        
     % Center STF model
     gaussianCenterSTF = @(params,sf)(params(1) * ( pi * params(4)^2 * exp(-(pi*params(4)*sf).^2)));
     
     % Surround STF model
     gaussianSurroundSTF = @(params,sf)(params(1)*params(2) * ( pi * (params(4)*params(3))^2 * exp(-(pi*params(4)*params(3)*sf).^2)));
     
     
     % Normalize weights with STF power
     centerFitWeight = centerFitWeight / sum(theCenterSTF.^2);
     surroundFitWeight = surroundFitWeight / sum(theSurroundSTF.^2);
     compositeFitWeight = compositeFitWeight / sum(theCompositeSTF.^2);
     
     comboObjective = @(p) ( ...
         centerFitWeight * sum((gaussianCenterSTF(p, sf) - theCenterSTF).^2) + ...
         surroundFitWeight * sum((gaussianSurroundSTF(p, sf) - theSurroundSTF).^2) + ...
         compositeFitWeight * sum((DoGSTF(p, sf) - theCompositeSTF).^2) ...
         );
     
     % Multi-start
     compositeProblem = createOptimProblem('fmincon',...
          'objective', comboObjective, ...
          'x0', DoGparams.initialValues, ...
          'lb', DoGparams.lowerBounds, ...
          'ub', DoGparams.upperBounds, ...
          'options', options...
          );
      
    % Run the multi-start
    DoGparams.bestFitValues = run(ms, compositeProblem, multiStartsNum);
     
    % Compute the fitted STFs
    theFittedCompositeSTF = DoGSTF(DoGparams.bestFitValues, sf);
    theFittedSTFcenter    = DoGparams.bestFitValues(1) * ( pi * DoGparams.bestFitValues(4)^2 * exp(-(pi*DoGparams.bestFitValues(4)*sf).^2) );
    theFittedSTFsurround  = DoGparams.bestFitValues(1)*DoGparams.bestFitValues(2) * ( pi * (DoGparams.bestFitValues(4)*DoGparams.bestFitValues(3))^2 * exp(-(pi*DoGparams.bestFitValues(4)*DoGparams.bestFitValues(3)*sf).^2) );
    
    sf = 0;
    theFittedCompositeSTFHiResFullField = DoGSTF(DoGparams.bestFitValues, sf);
    theFittedSTFcenterFullField = DoGparams.bestFitValues(1) * ( pi * DoGparams.bestFitValues(4)^2 * exp(-(pi*DoGparams.bestFitValues(4)*sf).^2) );
    theFittedSTFsurroundFullField = DoGparams.bestFitValues(1)*DoGparams.bestFitValues(2) * ( pi * (DoGparams.bestFitValues(4)*DoGparams.bestFitValues(3))^2 * exp(-(pi*DoGparams.bestFitValues(4)*DoGparams.bestFitValues(3)*sf).^2) );
     
    % Put back the stimulusOTF
    if (deconvolveStimulus)
        theFittedSTFcenter = theFittedSTFcenter .* theStimulusOTF;
        theFittedSTFsurround = theFittedSTFsurround .* theStimulusOTF;
        theFittedCompositeSTF = theFittedCompositeSTF .* theStimulusOTF;
    end
    
    sfHiRes = logspace(log10(1), log10(100), 64);
    theFittedCompositeSTFHiRes = DoGSTF(DoGparams.bestFitValues, sfHiRes);
end
