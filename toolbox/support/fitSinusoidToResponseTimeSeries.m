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

    options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt','Display','off');
    
    % Model to fit
    % f = baseline (0) + amplitude * sin(2*pi*F*time - phase)
    sinFunction = @(params,time)(params(3)*0 + params(1) * sin(2.0*pi*stimulusTemporalFrequencyHz*time - params(2)/180*pi));

    % Initial params
    initialParams(1) = 0.7;     % amplitude
    initialParams(2) = 0.0;     % phase
    initialParams(3) = 0.0;     % baseline
    
    maxAmplitude = max(abs(theResponse));
    theResponse = theResponse/maxAmplitude;
    
    lowerBound = [0.8   -360     0];
    upperBound = [1     360     0];
    
    % Fit
    fittedParams = lsqcurvefit(sinFunction,initialParams, time, double(theResponse), lowerBound, upperBound, options);
    if (fittedParams(1) < 0)
        fittedParams(1) = -fittedParams(1);
        fittedParams(2) =  fittedParams(2) + 180;
    end
    fittedParams(1) = fittedParams(1) * maxAmplitude;

    % Generate high-resolution fitted function
    theFittedResponse = sinFunction(fittedParams,timeHR);
end

