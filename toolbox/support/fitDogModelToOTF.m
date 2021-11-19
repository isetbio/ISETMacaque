function [theFittedRetinalOTFs, fittedParams, rmsError] = fitDogModelToOTF(...
    sf, measuredRetinalRGCOTFs, measuredRetinalRGCOTFSTDs, theFittedRFcenterRadius, sfHR, lowerBoundForRsToRc, ...
    multiStartSolver)
    
    % Surround radius no larger than 15 x center radius
    upperBoundForRsToRc = 30;
    
    % Peak sensitivity of the surround no larger than 1.0 x peak
    % sensitivity of the center
    upperBoundForKsToKc = 5.0;
    
    upperBoundForKc = 10*1000 * 1000;
    
    % sigma = 0.204 * innerSegmentDiameter. Min inner segment diameter = 1.9 microns
    lowerBoundForRcDegs = 0.2*sqrt(2) * 0.204 * 1.9 / WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    
    % Model to fit
    if (isempty(theFittedRFcenterRadius))
        % Free Rc
        DoGFunction = @(params,sf)(...
                    params(1)           * ( pi * params(2)^2             * exp(-(pi*params(2)*sf).^2) ) - ...
                    params(1)*params(3) * ( pi * (params(2)*params(4))^2 * exp(-(pi*params(2)*params(4)*sf).^2) ));
               
        %                Kc                 RcDegs                 kS/kC                  Rs/Rc
        initialParams = [1500               1/200                   1e-2                 7];
        lowerBound    = [10                 lowerBoundForRcDegs      1e-5                 lowerBoundForRsToRc];
        upperBound    = [upperBoundForKc    10.0/200                 upperBoundForKsToKc  upperBoundForRsToRc];
        
    else
        % Fixed Rc
        theFittedRFcenterRadius = abs(theFittedRFcenterRadius); 
        DoGFunction = @(params,sf)(...
                    params(1)           * ( pi * theFittedRFcenterRadius^2              * exp(-(pi*theFittedRFcenterRadius*sf).^2) ) - ...
                    params(1)*params(2) * ( pi * (theFittedRFcenterRadius*params(3))^2  * exp(-(pi*theFittedRFcenterRadius*params(3)*sf).^2) ));
                
        %                 Kc                kS/kC                  Rs/Rc
        initialParams = [1500               1e-2                   7];
        lowerBound    = [10                 1e-5                   lowerBoundForRsToRc];
        upperBound    = [upperBoundForKc    upperBoundForKsToKc    upperBoundForRsToRc];
    end
    

    for iCell = 1:size(measuredRetinalRGCOTFs,1)

        % Fit the DOG to this cell's response
        theRetinalResponse = measuredRetinalRGCOTFs(iCell,:);
        
        
        % Initial params
        options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt','Display','off');
        fittedParamsInitial = lsqcurvefit(DoGFunction,initialParams, sf, theRetinalResponse, lowerBound, upperBound, options);

        switch (multiStartSolver)
            case 'lsqcurvefit'
                
                thresholdRMSForRepeatFitting = 0.1;
                maxRefitAttempts = 3;
                refitAttempt = 0;
                keepTrying = true;
                
                while(keepTrying)
                    
                    problem = createOptimProblem('lsqcurvefit',...
                        'x0', fittedParamsInitial, ...
                        'objective', DoGFunction, ...
                        'lb', lowerBound, ...
                        'ub', upperBound,...
                        'xdata', sf,...
                        'ydata', theRetinalResponse);
                
                    displayProgress = 'off'; % 'iter';
                    ms = MultiStart(...
                        'Display', displayProgress, ...
                        'FunctionTolerance', 2e-4, ...
                        'UseParallel', true);

                    startingPointsNum = 30;
                    [fittedParams(iCell,:),errormulti] = run(ms,problem,startingPointsNum );
                
                 
                    theFittedResponse = DoGFunction(fittedParams(iCell,:), sf);
                    nDataPoints = numel(sf);
                    rmsError(iCell) = sqrt(1/nDataPoints * sum((theFittedResponse-theRetinalResponse).^2));
                
                    
                    refitAttempt = refitAttempt+1;
                    if (rmsError(iCell) < thresholdRMSForRepeatFitting) || ...
                       (refitAttempt > maxRefitAttempts)
                        keepTrying = false;
                    else
                        fprintf(2,'RMS error (%2.1f) >  threshold RMS (%2.1f). Trying to fit the data again ...\n', ...
                            rmsError(iCell), thresholdRMSForRepeatFitting);
                        fittedParamsInitial = fittedParams(iCell,:);
                    end
                end
                
            case 'fmincon'
                
                if (isempty(measuredRetinalRGCOTFSTDs))
                    weights = ones(size(theRetinalResponse));
                    fprintf('Fitting DoG model WITHOUT weights\n');
                else
                    theRetinalResponseStd = measuredRetinalRGCOTFSTDs(iCell,:);
                    weights = 1./theRetinalResponseStd;
                    fprintf('Fitting DoG model WITH weights\n');
                end
                
                objective = @(p) sum(weights .* (DoGFunction(p, sf) - theRetinalResponse).^2);
                
                problem = createOptimProblem('fmincon',...
                    'x0', fittedParamsInitial, ...
                    'objective', objective, ...
                    'lb', lowerBound, ...
                    'ub', upperBound ...
                    );
                
                displayProgress = 'off'; % 'iter';
                ms = MultiStart(...
                        'Display', displayProgress, ...
                        'FunctionTolerance', 2e-4, ...
                        'UseParallel', true);

                startingPointsNum = 30;
                [fittedParams(iCell,:),errormulti] = run(ms,problem,startingPointsNum );


                theFittedResponse = DoGFunction(fittedParams(iCell,:), sf);
                nDataPoints = numel(sf);
                rmsError(iCell) = sqrt(1/nDataPoints * sum((theFittedResponse-theRetinalResponse).^2));
        
        end
        
        % Generate high-resolution fitted function
        theFittedRetinalOTFs(iCell,:) = DoGFunction(fittedParams(iCell,:), sfHR);
    end
    
end

