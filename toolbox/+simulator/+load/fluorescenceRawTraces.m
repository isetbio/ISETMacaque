function [temporalSupportSeconds, responseTrace, spatialFrequency] = fluorescenceRawTraces(monkeyID, varargin)
% Load the measured cells' GCaMP raw fluorescence dF/F response
%
% Syntax:
%   [temporalSupport, responseTrace] = simulator.load.fluorescenceRawTraces(monkeyID, varargin);
%
% Description:
%   Load the measured cells' GCaMP raw fluorescence dF/F response
%   Key-value pair select which session to import, which cells to import
%   (L-center, M-center or all)
%
% Inputs:
%    monkeyID       The monkeyID
%
% Output
%   
%
% Optional key/value pairs:
%    'whichSession'           - either a scalar identifiying a particular session, 
%                               or 'meanOverSessions' or 'allSessions'
%    'whichCenterConeType'    - char. Either 'L', or 'M', or 'all'
%    'whichRGCindex'          - scalar. which cell index
%    'whichSpatialFrequency'  - scalar. which spatial frequency
%

    p = inputParser;
    p.addParameter('whichSession', 1,@isscalar)
    p.addParameter('whichCenterConeType', 'l', @(x)(ismember(lower(x), {'l', 'm'})));
    p.addParameter('whichRGCindex', 1, @isscalar);
    p.addParameter('whichSpatialFrequency', 0, @isscalar);
    p.parse(varargin{:});

    whichSession = p.Results.whichSession;
    whichCenterConeType = p.Results.whichCenterConeType;
    whichRGCindex = p.Results.whichRGCindex;
    whichSpatialFrequency = p.Results.whichSpatialFrequency;


    filepath = fullfile(ISETmacaqueRootPath, 'animals/WilliamsLab');
    fileName = fullfile(filepath, sprintf('%s_timecourses.mat', monkeyID));

    % Load all data
    switch (monkeyID)
        case 'M838'
            load(fileName, 'tcourses1', 'tcourses2', 'tcourses3');
            tcourses(1,:,:,:) = tcourses1;
            tcourses(2,:,:,:) = tcourses2;
            tcourses(3,:,:,:) = tcourses3;
            clear('tcourses1', 'tcourses2', 'tcourses3');

        otherwise
            error('No raw time traces for monkey ''%s''.', monkeyID);
    end

    % Determine serialized cell index
    serializedRGCindex = simulator.animalInfo.serializedRGCindices(monkeyID, whichCenterConeType,  whichRGCindex);
    
    % Determine serialized spatial frequency
    filepath = fullfile(ISETmacaqueRootPath, 'animals/WilliamsLab');
    fileName = fullfile(filepath, sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID));
    load(fileName, 'freqs'); 
    nonZeroSFs = freqs;
    examinedSFs = [0 nonZeroSFs];
    [~,sfIndex] = min(abs(examinedSFs -whichSpatialFrequency));
    spatialFrequency = examinedSFs(sfIndex);

    % Retriece the response for this cell index, this spatial frequency and
    % this session
    responseTrace = (squeeze(tcourses(whichSession, serializedRGCindex, :, sfIndex)))';
    if (size(responseTrace,1) > 1)
        error('Must feed a single trace only\n');
    end


    % Finally, extract exact time stamps for this spatial frequency and
    % this session
    frameTimeStampsBaseDir = sprintf('%s/animals/WilliamsLab/M838FrameLengthData', ISETmacaqueRootPath);
    expDir = sprintf('Expt %d', whichSession);
    if (spatialFrequency == 0)
        % arbitrarily choose the 4 c/deg
        sfDescriptor = '4dcdeg';
    else
        sfDescriptor = sprintf('%dcdeg', floor(spatialFrequency));
    end

    csvFileName = sprintf('%s/%s/%s.csv', frameTimeStampsBaseDir, expDir, sfDescriptor);
    frameTimeStamps = simulator.load.frameTimeStamps(csvFileName);
    
    % Generate recorded time axis from the frame time stamps
    recordedTimeAxisSeconds = zeros(1, numel(frameTimeStamps));

    for iTimeStamp = 1:numel(frameTimeStamps)
        if (iTimeStamp == 1)
            recordedTimeAxisSeconds(iTimeStamp) = frameTimeStamps(iTimeStamp)/1000.0;
        else
            recordedTimeAxisSeconds(iTimeStamp) = recordedTimeAxisSeconds(iTimeStamp-1) + frameTimeStamps(iTimeStamp)/1000.0;
        end
    end
    recordedTimeAxisSeconds = recordedTimeAxisSeconds - recordedTimeAxisSeconds(1);

    % Interpolate from jittered time stamps to a constant samplingfrequency
    targetSamplingFrequencyHz = 1000;
    maxTimeSeconds = recordedTimeAxisSeconds(end);
    dtSeconds = 1/targetSamplingFrequencyHz;
    interpolatedTimeAxisSeconds = 0:dtSeconds:maxTimeSeconds;
    interpolatedResponseTrace = interp1(recordedTimeAxisSeconds, responseTrace, interpolatedTimeAxisSeconds, 'linear');

    % Return values
    temporalSupportSeconds = interpolatedTimeAxisSeconds;
    responseTrace = interpolatedResponseTrace ;
end
