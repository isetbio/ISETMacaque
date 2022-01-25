function d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, sessionData)
% Load the uncorrected fluorescene STF data
%
% Syntax:
%   d = loadUncorrectedDeltaFluoresenceResponses(monkeyID, sessionData);
%
% Description:
%   The provided STF data have been de-convolved with the OTF of the 6.7mm
%   pupil, diffraction limited system. Here we put back the OTF of that
%   system.
%
% Inputs:
%    monkeyID            - String, 'M838'
%    sessionData         - String, choose from {'mean', 'session1only', 'session2only', 'session3only', 'sessionWithHighestSFextension'}
%
% Outputs:
%    d                   - Struct with data for (putative) L-, M-, S-cone center
%                          dF responses, their std. errors, and the 
%                          diffractionLimitedOTF used to correct the raw measurements
%
% Optional key/value pairs:
%    None
%                          

    % Load measured RGC spatial frequency curves. Note: these responses have
    % already been de-convolved with the diffraction-limited OTF
    [d.dFresponsesLcenterRGCs, ...
     d.dFresponsesMcenterRGCs, ...
     d.dFresponsesScenterRGCs, ...
     d.dFresponseStdLcenterRGCs, ...
     d.dFresponseStdMcenterRGCs, ...
     d.dFresponseStdScenterRGCs, ...
     d.diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData);

    % Undo this correction by adding back the diffraction-limited OTF
    d.dFresponsesLcenterRGCs = bsxfun(@times, d.dFresponsesLcenterRGCs, d.diffractionLimitedOTF.otf);    
    d.dFresponsesMcenterRGCs = bsxfun(@times, d.dFresponsesMcenterRGCs, d.diffractionLimitedOTF.otf);

end
