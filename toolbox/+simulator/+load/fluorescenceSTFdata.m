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
%    'deconvolveOTF'          - logical. Whether to deconvolved the baked-in OTF

    p = inputParser;
    p.addParameter('whichSession', 'meanOverSessions', @(x)(ischar(x)||isscalar(x)));
    p.addParameter('whichCenterConeType', 'all', @(x)(ismember(lower(x), {'l', 'm', 'all'})));
    p.addParameter('whichRGCindices', [1], @isscalar);
    p.addParameter('deconvolveOTF', true, @islogical);
    p.parse(varargin{:});

    whichSession = p.Results.whichSession;
    whichCenterConeType = p.Results.whichCenterConeType;
    whichRGCindices = p.Results.whichRGCindices;
    deconvolvedOTF = p.Results.deconvolveOTF;

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
    
    % Remove the OTF which is already baked in
    if (deconvolvedOTF)
        midget_dfF_otf_all = bsxfun(@times, midget_dfF_otf_all, otf); 
    end

    switch (whichCenterConeType)
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
        'responses',   midget_dfF_otf_all(whichRGCindices,:), ...
        'responseSE' , midget_dfF_otf_all_errors(whichRGCindices,:), ... 
        'spatialFrequencySupport', spatialFrequencySupport, ...
        'otf', otf);

end
