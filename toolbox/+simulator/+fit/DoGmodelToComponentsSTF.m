function [DoGparams, theFittedCompositeSTF, ...
         sfHiRes, theFittedCompositeSTFHiRes, ...
         theFittedSTFcenter, theFittedSTFsurround, ...
         theFittedSTFcenterHiRes, theFittedSTFsurroundHiRes, ...
         theFittedCompositeSTFHiResFullField, ...
         theFittedSTFcenterFullField, theFittedSTFsurroundFullField] = DoGmodelToComponentsSTF(...
                 sf, theCenterSTF, theSurroundSTF, theCompositeSTF, ...
                 centerConeCharacteristicRadiusDegs, ...
                 centerFitWeight, surroundFitWeight, compositeFitWeight, spatialFrequencyWeights)
% Fit the DoG model to the computed components center & surround STFs
%
% Syntax:
%   simulator.fit.DoGmodelToComponentsSTF(sf, theCenterSTF, theSurroundSTF, ...
%        centerConeCharacteristicRadiusDegs)
%
%
% Description: Fit the DoG model to the computed computed components center & surround STFs

    deconvolveStimulus = ~true;
    if (deconvolveStimulus)
        fprintf('Deconvolving stimulus OTF\n');
        % Compute the stimulusOTF
        theStimulusOTF = simulator.analyze.stimulusOTF(sf);
        %theStimulusOTF = theStimulusOTF * 0 + 1;

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
      
    multiStartsNum = 256;
         
      
    % DoG param initial values and limits: center gain, kc
    Kc = struct(...    
        'low', 1e-4, ...
        'high', 1e7, ...
        'initial', 1);

    % DoG param initial values and limits: Ks/Kc ratio
    KsToKc = struct(...
        'low', 1e-3, ...
        'high', 1.0, ...
        'initial', 0.1);

    % DoG param initial values and limits: RsToRc ratio
    RsToRc = struct(...
        'low', 1.0, ...
        'high', 10, ...
        'initial', 2);

    % DoG param initial values and limits: RcDegs
    RcDegs = struct(...
        'low', centerConeCharacteristicRadiusDegs*0, ...
        'high', centerConeCharacteristicRadiusDegs*60, ...
        'initial', centerConeCharacteristicRadiusDegs*2);
    
     %                          Kc           kS/kC             RsToRc            RcDegs    
     DoGparams.initialValues = [Kc.initial   KsToKc.initial    RsToRc.initial    RcDegs.initial];
     DoGparams.lowerBounds   = [Kc.low       KsToKc.low        RsToRc.low        RcDegs.low];
     DoGparams.upperBounds   = [Kc.high      KsToKc.high       RsToRc.high       RcDegs.high];
     DoGparams.names         = {'Kc',        'kS/kC',         'RsToRc',         'RcDegs'};
     DoGparams.scale         = {'log',       'log',           'linear',         'linear'};
     
     % Center STF model
     gaussianCenterSTF = @(params,sf)(params(1) * ( pi * params(4)^2 * exp(-(pi*params(4)*sf).^2)));
     
     % Surround STF model
     gaussianSurroundSTF = @(params,sf)(params(1)*params(2) * ( pi * (params(4)*params(3))^2 * exp(-(pi*params(4)*params(3)*sf).^2)));
     
     % The DoG model in the frequency domain
     DoGSTF = @(params,sf)(abs(gaussianCenterSTF(params,sf) - gaussianSurroundSTF(params,sf)));
        
   
     
     % Normalize weights with STF power so that if the center/surround
     % responses are huge and the center-surround is small we do not
     % completely ignore the center-surround
     centerFitWeight = centerFitWeight / max(abs(theCenterSTF(:)));
     surroundFitWeight = surroundFitWeight / max(abs(theSurroundSTF(:)));
     compositeFitWeight = compositeFitWeight / max(abs(theCompositeSTF(:)));
     
     comboObjective = @(p) ( ...
         centerFitWeight * sum(spatialFrequencyWeights.*(gaussianCenterSTF(p, sf) - theCenterSTF).^2) + ...
         surroundFitWeight * sum(spatialFrequencyWeights.*(gaussianSurroundSTF(p, sf) - theSurroundSTF).^2) + ...
         compositeFitWeight * sum(spatialFrequencyWeights.*(DoGSTF(p, sf) - theCompositeSTF).^2) ...
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
    theFittedSTFcenter    = gaussianCenterSTF(DoGparams.bestFitValues, sf);
    theFittedSTFsurround  = gaussianSurroundSTF(DoGparams.bestFitValues, sf);
    
    % Compute the hires fitted STFs
    sfHiRes = linspace(sf(1), sf(end), 256);
    theFittedCompositeSTFHiRes = DoGSTF(DoGparams.bestFitValues, sfHiRes);
    theFittedSTFcenterHiRes = gaussianCenterSTF(DoGparams.bestFitValues, sfHiRes);
    theFittedSTFsurroundHiRes = gaussianSurroundSTF(DoGparams.bestFitValues, sfHiRes);

    % Compute the value at 0
    theFittedCompositeSTFHiResFullField = DoGSTF(DoGparams.bestFitValues, 0);
    theFittedSTFcenterFullField = gaussianCenterSTF(DoGparams.bestFitValues, 0);
    theFittedSTFsurroundFullField = gaussianSurroundSTF(DoGparams.bestFitValues, 0);
     
    % Put back the stimulusOTF
    if (deconvolveStimulus)
        theFittedSTFcenter = theFittedSTFcenter .* theStimulusOTF;
        theFittedSTFsurround = theFittedSTFsurround .* theStimulusOTF;
        theFittedCompositeSTF = theFittedCompositeSTF .* theStimulusOTF;

        theStimulusOTFHiRes = interp1(sf, theStimulusOTF, sfHiRes);
        theFittedCompositeSTFHiRes = theFittedCompositeSTFHiRes .* theStimulusOTFHiRes;
        theFittedSTFcenterHiRes = theFittedSTFcenterHiRes .* theStimulusOTFHiRes;
        theFittedSTFsurroundHiRes = theFittedSTFsurroundHiRes.* theStimulusOTFHiRes;
    end
    
    
end
