function [dFresponsesLcenterRGCs, dFresponsesMcenterRGCs, dFresponsesScenterRGCs, ...
     dFresponseStdLcenterRGCs,  dFresponseStdMcenterRGCs,  dFresponseStdScenterRGCs, ...
     diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData)

% Load the provided fluorescene STF data
%
% Syntax:
%   d = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData);
%
% Description:
%   Load the provided fluorescene STF data and the diffraction-limited OTF
%
% Inputs:
%    monkeyID            - String, 'M838'
%    sessionData         - String, choose from {'mean', 'session1only', 'session2only', 'session3 only', 'sessionWithHighestSFextension'}
%
% Outputs:
%    dFresponsesLcenterRGCs    - [mCells x N spatial frequencies] matrix of STF responses 
%                                for (putatively) L-center RGCs
%    dFresponsesMcenterRGCs    - [mCells x N spatial frequencies] matrix of STF responses 
%                                for (putatively) M-center RGCs
%    dFresponsesScenterRGCs    - [mCells x N spatial frequencies] matrix of STF responses 
%                                for (putatively) S-center RGCs
%    dFresponseStdLcenterRGCs  - [mCells x N spatial frequencies] matrix of std error of the mean STF responses 
%                                for (putatively) L-center RGCs
%    dFresponseStdMcenterRGCs  - [mCells x N spatial frequencies] matrix of std error of the mean STF responses 
%                                for (putatively) M-center RGCs
%    dFresponseStdScenterRGCs  - [mCells x N spatial frequencies] matrix of std error of the mean STF responses 
%                                for (putatively) S-center RGCs
%    diffractionLimitedOTF     - struct with:
%                                  'sf': spatial frequencies at which STFs were measured and,
%                                  'otf': the corresponding OTF value of a
%                                       6.7 mm diffraction-limited system
%
% Optional key/value pairs:
%    None
%         

    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    measuredDataFileName = fullfile(rootDirName, sprintf('dataResources/WilliamsLab/SpatialFrequencyData_%s_OD_2021.mat', monkeyID));
    
    % Load the measured cells' GCaMP fluorescence dF/F response - based OTFs
    % Note: these have been already deconvolved with the diffraction-limited OTF
    load(measuredDataFileName, 'midget_dfF_otf', 'cone_center_guesses');
    
    midget_dfF_otf_std = [];
    visualizeResampling = false;
    visualizeAllSessionData = false;
            
    switch (sessionData)
        case 'mean'
            fprintf('Using mean (over all sessions) data\n');
            [midget_dfF_otf, midget_dfF_otf_std] = resampleDfFoMeasurements(...
                -99, visualizeResampling, visualizeAllSessionData);
       
        case 'resampleSessionData'
            nSamples = 512;
            fprintf('Resampling session data (n:%d)\n', nSamples);
            
            [midget_dfF_otf, midget_dfF_otf_std] = resampleDfFoMeasurements(...
                nSamples, visualizeResampling, visualizeAllSessionData);
        case 'session1only'
            fprintf('Using data from session 1 only\n');
            midget_dfF_otf = resampleDfFoMeasurements(...
                -1, visualizeResampling, visualizeAllSessionData);
        case 'session2only'
            fprintf('Using data from session 2 only\n');
            midget_dfF_otf = resampleDfFoMeasurements(...
                -2, visualizeResampling, visualizeAllSessionData);
        case 'session3only'
            fprintf('Using data from session 3 only\n');
            midget_dfF_otf = resampleDfFoMeasurements(...
                -3, visualizeResampling, visualizeAllSessionData);
        case 'sessionWithHighestSFextension'
            fprintf('Using data from best session only\n');
            [midget_dfF_otf, midget_dfF_otf_std] = resampleDfFoMeasurements(...
                0, visualizeResampling, visualizeAllSessionData);
        otherwise
            error('sessionData must be either ''mean'', ''resampleSessionData'', ''session1only'', ''session2only'',  ''session3only'' or ''sessionWithHighestSFextension''. It is %s\n', sessionData);
    end
    
    
    
    dFresponsesLcenterRGCs = [];
    dFresponsesMcenterRGCs = [];
    dFresponsesScenterRGCs = [];
    dFresponseStdLcenterRGCs = [];
    dFresponseStdMcenterRGCs = [];
    dFresponseStdScenterRGCs = [];
    
    for iRGC = 1:numel(cone_center_guesses)
        switch cone_center_guesses{iRGC}
            case 'L'
                dFresponsesLcenterRGCs(size(dFresponsesLcenterRGCs,1)+1,:) = midget_dfF_otf(iRGC,:);
                if (~isempty(midget_dfF_otf_std))
                    dFresponseStdLcenterRGCs(size(dFresponseStdLcenterRGCs,1)+1,:) = midget_dfF_otf_std(iRGC,:);
                end
            case 'M'
                dFresponsesMcenterRGCs(size(dFresponsesMcenterRGCs,1)+1,:) = midget_dfF_otf(iRGC,:);
                if (~isempty(midget_dfF_otf_std))
                    dFresponseStdMcenterRGCs(size(dFresponseStdMcenterRGCs,1)+1,:) = midget_dfF_otf_std(iRGC,:);
                end
            case 'S'
                dFresponsesScenterRGCs(size(dFresponsesScenterRGCs,1)+1,:) = midget_dfF_otf(iRGC,:);
                if (~isempty(midget_dfF_otf_std))
                    dFresponseStdScenterRGCs(size(dFresponseStdScenterRGCs,1)+1,:) = midget_dfF_otf_std(iRGC,:);
                end
        end
    end
    
    % Load the OTF of the diffraction limited optics
    load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID),'otf', 'freqs');
    diffractionLimitedOTF.sf = freqs;
    diffractionLimitedOTF.otf = otf;
end


