function stfDataStruct = fluorescenceSTFdata(monkeyID, varargin)
% Load the measured cells' GCaMP fluorescence dF/F response - based OTFs
%
% Syntax:
%   stfDataStruct = simulator.load.fluorescenceSTFdata(monkeyID, varargin);
%
% Description:
%   Load the measured cells' GCaMP fluorescence dF/F response - based OTFs
%   Key-value pair select which session to import, which cells to import
%   (L-center, M-center or all) and whether to remove the baked-in diffraction-limited OTF
%
% Inputs:
%    monkeyID       The monkeyID
%
% Output
%    stfDataStruct              - struct with fields
%      - responses                  - the responses
%      - responseSE                 - the std. err of the responses
%      - spatialFrequencySupport    - the SF support
%      - otf                        - the diffraction-limited OTF
%
% Optional key/value pairs:
%    'whichSession'           - either a scalar identifiying a particular session, 
%                               or 'meanOverSessions' or 'allSessions'
%    'whichCenterConeType'    - char. Either 'L', or 'M', or 'all'
%    'whichRGCindex'          - scalar. which cell index
%    'undoOTFdeconvolution'   - logical. Whether to undo the baked in deconvolution by the diffr.limited OTF

    p = inputParser;
    p.addParameter('whichSession', 'meanOverSessions', @(x)(ischar(x)||isscalar(x)));
    p.addParameter('whichCenterConeType', 'l', @(x)(ismember(lower(x), {'l', 'm'})));
    p.addParameter('whichRGCindex', [1], @isscalar);
    p.addParameter('undoOTFdeconvolution', true, @islogical);
    p.parse(varargin{:});

    whichSession = p.Results.whichSession;
    whichCenterConeType = p.Results.whichCenterConeType;
    whichRGCindex = p.Results.whichRGCindex;
    undoOTFdeconvolution = p.Results.undoOTFdeconvolution;

    if (ischar(whichSession))
        assert(ismember(whichSession, {'meanOverSessions', 'allSessions'}), ...
            '''whichSession'' must be set to either ''meanOverSessions'', or ''allSessions'' or a specific session.');
    end

    % Load the examined spatial frequencies, the assumed OTF, and the
    % center cone types
    filepath = fullfile(ISETmacaqueRootPath, 'animals/WilliamsLab');
    fileName = fullfile(filepath, sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID));
    load(fileName, 'freqs', 'otf', 'cone_center_guesses'); 
    spatialFrequencySupport = freqs;

    % Load the measured cells' GCaMP fluorescence dF/F response - based OTFs
    % Note: these have been already deconvolved with the diffraction-limited OTF
    fileName = fullfile(filepath, sprintf('SpatialFrequencyDataMean_%s_alltrials.mat', monkeyID));
    load(fileName, 'midget_dfF_otf_all');

    % Load the standard errors
    fileName = fullfile(filepath, sprintf('SpatialFrequencyDataStd_%s_alltrials.mat', monkeyID));
    load(fileName, 'midget_dfF_otf_all_errors');
    
    % Remove the deconvolution by the OTF which is already baked in
    if (undoOTFdeconvolution)
        midget_dfF_otf_all = bsxfun(@times, midget_dfF_otf_all, otf); 
    end

    switch (upper(whichCenterConeType))
        case 'L'
            idx = find(strcmp(cone_center_guesses, 'L')==1);
            midget_dfF_otf_all = midget_dfF_otf_all(idx,:,:);
            midget_dfF_otf_all_errors = midget_dfF_otf_all_errors(idx,:,:);
        case 'M'
            idx = find(strcmp(cone_center_guesses, 'M')==1);
            midget_dfF_otf_all = midget_dfF_otf_all(idx,:,:);
            midget_dfF_otf_all_errors = midget_dfF_otf_all_errors(idx,:,:);
    end


    if (ischar(whichSession))&&(strcmp(whichSession, 'meanOverSessions'))
        midget_dfF_otf_all = mean(midget_dfF_otf_all,3);
        midget_dfF_otf_all_errors = mean(midget_dfF_otf_all_errors,3);
    elseif (isscalar(whichSession))
        midget_dfF_otf_all = midget_dfF_otf_all(:,:,whichSession);
        midget_dfF_otf_all_errors = midget_dfF_otf_all_errors(:,:,whichSession);
    end

    % Return the data
    stfDataStruct = struct(...
        'whichCenterConeType', whichCenterConeType, ...
        'whichRGCindex', whichRGCindex, ...
        'responses',   midget_dfF_otf_all(whichRGCindex,:,:), ...
        'responseSE' , midget_dfF_otf_all_errors(whichRGCindex,:,:), ... 
        'spatialFrequencySupport', spatialFrequencySupport, ...
        'otf', otf);

end
