function [dFresponsesLcenterRGCs, dFresponsesMcenterRGCs, dFresponsesScenterRGCs, ...
     dFresponseStdLcenterRGCs,  dFresponseStdMcenterRGCs,  dFresponseStdScenterRGCs, ...
     diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData)
 

    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    measuredDataFileName = fullfile(rootDirName, 'dataResources/WilliamsLab/SpatialFrequencyData_M838_OD_2021.mat');
    
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


