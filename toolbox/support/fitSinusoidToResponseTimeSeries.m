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

    maxAmplitude = max(abs(theResponse));
    theResponse = double(theResponse/maxAmplitude);
    
    deltaPhaseDegs = 1.0;
    deltaAmplitude = 0.01;
    phaseDegs = 0:deltaPhaseDegs:359;
    phaseRadians = phaseDegs/180*pi;
    amplitudes = 0.8:deltaAmplitude:1.2;
    
    fTime = 2.0*pi*stimulusTemporalFrequencyHz*time;
    
    theMinResidual = Inf;
    % Search over phase
    for iPhase = 1:numel(phaseDegs)
        thePhaseRadians = phaseRadians(iPhase);
        theSine = sin(fTime - thePhaseRadians);
        
        % Search over amplitude
        for iAmp = 1:numel(amplitudes)
            theAmplitude = amplitudes(iAmp);
            theSinewave = theAmplitude * theSine;
            theResidual = sum((theSinewave-theResponse).^2);
            
            if (theResidual < theMinResidual)
                theMinResidual = theResidual;
                fittedParams = [theAmplitude*maxAmplitude phaseDegs(iPhase)];
            end
        end
    end
    
    % Generate high-resolution fitted function
    if (~isempty(timeHR))
        fTime = 2.0*pi*stimulusTemporalFrequencyHz*timeHR;
        theFittedResponse = fittedParams(1) * sin(fTime - fittedParams(2)/180*pi);
    else
        theFittedResponse = [];
    end
    
    
    debug = false;
    if (debug)
        timeHR = linspace(time(1), time(end), 100);
        fTime = 2.0*pi*stimulusTemporalFrequencyHz*timeHR;
        theFittedResponse = fittedParams(1) * sin(fTime - fittedParams(2)/180*pi);
        figure(1); clf;
        plot(time, theResponse*maxAmplitude, 'ks');
        hold on;
        plot(timeHR, theFittedResponse, 'r-');
        set(gca, 'YLim', [-1 1]);
        pause
    end
    
end


function OLD
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

