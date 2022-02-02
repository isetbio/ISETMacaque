function [theFittedResponse, fittedParams] = fitSinusoidToResponseTimeSeries(time, theResponse, stimulusTemporalFrequencyHz, timeHR)
% Fit a sinusoid to a response time series
%
% Syntax:
%   [theFittedResponse, fittedParams] = fitSinusoidToResponseTimeSeries(time, theResponse, stimulusTemporalFrequencyHz, timeHR)
%
% Description:
%   Fit a sinusoid to a response time series and extract the amplitude and
%   phase of the sinusoid. 
%
% Inputs:
%    time                         - temporal support (in seconds) of the time series response
%    theResponse                  - the response time series
%    stimulusTemporalFrequencyHz  - the temporal frequency of the stimulus
%    timeHR                       - the high-resolution temporal support
%                                   for computing the fitted sinusoid
%
% Outputs:
%    theFittedResponse            - the fitted time-series response
%                                    evaluated at the timeHR temporal support
%    fittedParams                 - a 2x1 matrix with the amplitude and
%                                     phase (in degrees) of the best fit sinusoid
%
% Optional key/value pairs:
%    None
%         

    options = optimset(...
        'Display', 'off');
    
%         'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
%         'GradObj', 'off', ...
%         'DerivativeCheck', 'off');
    %, ...
    %    'MaxFunEvals', 10^5, ...
    %    'MaxIter', 10^3);
    
    % Model to fit
    % f = amplitude * sin(2*pi*F*time - phase)
    sinFunction = @(params,time)(params(1) * sin(2.0*pi*stimulusTemporalFrequencyHz*time - params(2)/180*pi));

    % Initial params
    initialParams(1) = 1.0;     % amplitude
    initialParams(2) = 0.0;     % phase
    
    % Bounds
    lowerBound = [0.5   -360];
    upperBound = [1.0    360];
    
    maxAmplitude = max(abs(theResponse));
    theResponse = double(theResponse/maxAmplitude);

    % Fit
    objective = @(p) sum((sinFunction(p, time) - theResponse).^2);
    fittedParams = fmincon(objective, initialParams,[],[],[],[],lowerBound,upperBound,[], options);
    
    if (fittedParams(1) < 0)
        fittedParams(1) = -fittedParams(1);
        fittedParams(2) =  fittedParams(2) + 180;
    end
    fittedParams(1) = fittedParams(1) * maxAmplitude;
    
    % Generate high-resolution fitted function
    if (~isempty(timeHR))
        theFittedResponse = sinFunction(fittedParams,timeHR);
    else
        theFittedResponse = [];
    end

end

