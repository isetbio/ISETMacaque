
function [theFittedRetinalOTFHR, fittedParams] = fitGaussianToOTF(sf, theRetinalOTF, sfHR, ...
    lowerBoundForGain, upperBoundForGain)
    
    % nlinfit options
    opts.RobustWgtFun = []; %'talwar';
    opts.MaxIter = 1000;
    
    % Model to fit
    GaussianFunction = @(params,sf)(...
                    params(1) * ( exp(-(pi*params(2)*sf).^2) ));
    
    % Initial params: Kc     RcDegs
    %initialParams = [10000     1/200];
    %lowerBound    = [1000    0.1/200];
    %upperBound    = [100000 10.0/200];
    
    initialParams = [1     1/200];
    lowerBound    = [lowerBoundForGain    0.1/200];
    upperBound    = [upperBoundForGain 10.0/200];
    
    % Fit
    % Global optimization
    options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt','Display','off');
    
    
    fittedParamsInitial = lsqcurvefit(GaussianFunction,initialParams, sf, theRetinalOTF, lowerBound, upperBound, options);
    
    problem = createOptimProblem('lsqcurvefit',...
        'x0',fittedParamsInitial, ...
        'objective',GaussianFunction,...
        'lb',lowerBound, ...
        'ub',upperBound,...
        'xdata',sf,...
        'ydata',theRetinalOTF);
    
    displayProgress = 'off'; % 'iter';
    ms = MultiStart(...
        'Display', displayProgress, ...
        'FunctionTolerance', 2e-4, ...
        'UseParallel', true);
    
    [fittedParams,errormulti] = run(ms,problem,20);
    
    % Generate high-resolution fitted function
    theFittedRetinalOTFHR = GaussianFunction(fittedParams, sfHR);
end