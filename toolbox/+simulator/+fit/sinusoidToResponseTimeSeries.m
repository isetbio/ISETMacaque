function [theFittedResponse, theFittedParams] = sinusoidToResponseTimeSeries(time, theResponse, stimulusTemporalFrequencyHz, timeHR)
% Fit a sinusoid to a response time series
%
% Syntax:
%   simulator.fit.sinusoidToResponseTimeSeries
%
% Description:
%   Fit a sinusoid to a response time series
%
% Inputs:
%    time
%    theResponse
%    stimulusTemporalFrequencyHz
%    timeHR
%
% Outputs:
%    theFittedResponse
%    theFittedParams
%
% Optional key/value pairs:
%    None
    

    maxAmplitude = max(abs(theResponse));
    theResponse = double(theResponse/maxAmplitude);

    deltaPhaseDegs = 2;
    phaseDegs = 0:deltaPhaseDegs:179;
    phaseRadians = phaseDegs/180*pi;
    
    deltaAmplitude = 0.01;
    amplitudes = 0.8:deltaAmplitude:1.2;
    
    fTime = 2.0*pi*stimulusTemporalFrequencyHz*time;
    theResiduals = inf(numel(phaseDegs)*2, numel(amplitudes));
   
    % Search over phase
    for iPhase = 1:numel(phaseDegs)
        thePhaseRadians = phaseRadians(iPhase);
        theSine = sin(fTime - thePhaseRadians);
        
        % Search over amplitude
        for iAmp = 1:numel(amplitudes)
            theAmplitude = amplitudes(iAmp);
            theSinewave = theAmplitude * theSine;
            theResiduals(iPhase,iAmp) = sum((theSinewave-theResponse).^2);
            theResiduals(iPhase+numel(phaseDegs),iAmp) = sum((-theSinewave-theResponse).^2);
        end
    end
    
    [~,idx] = min(theResiduals(:));
    [iPhase, iAmp] = ind2sub(size(theResiduals), idx);
    if (iPhase > numel(phaseDegs))
        thePhaseDegs = phaseDegs(iPhase-numel(phaseDegs))+180;
    else
        thePhaseDegs = phaseDegs(iPhase);
    end
    theFittedParams = [amplitudes(iAmp)*maxAmplitude thePhaseDegs];
    
    % Generate high-resolution fitted function
    if (~isempty(timeHR))
        fTime = 2.0*pi*stimulusTemporalFrequencyHz*timeHR;
        theFittedResponse = fittedParams(1) * sin(fTime - fittedParams(2)/180*pi);
    else
        theFittedResponse = [];
    end
end
