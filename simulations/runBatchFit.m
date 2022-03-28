function runBatchFit
% Fit diffraction-limited DF/F STFs using ISETBIO to obtain a cone pooling
% center/surround RF model
%
% Syntax:
%   runBatchFit()
%
% Description:
%   Batch fit a set of RGC STFs obtained under diffraction-limited optics.
%   The user can specify different scenarios to fit:
%
%  - the amount of residual defocus that the AOSLO system used for obtaining
%    these STFs may have had, e.g., 0.067 D
%    (specified in operationOptions.residualDefocusDiopters)
%
%  - the cone pooling scenario {'single-cone', or 'multi-cone'}
%    (specified in operationOptions.rfCenterConePoolingScenariosExamined)
% 
%  - the number of positions within the model cone mosaic to fit
%    (specified in operationOptions.coneMosaicSamplingParams)
%  
%  - various other fitting params e.g., the # of multi-starts, 
%    whether to account for negative values in the fluorescence STF measurements, 
%    or whether to bias some part of the STF
%    (specified in  operationOptions.fitParams)
%
%   The called method (simulator.fit.fluorescenceSTFData) derives a cone
%   pooling model (containing the cone indices and their connection weights
%   to the RF center and the RF surround) which is obtained by best fitting 
%   the measured STF data with pooled responses from a model cone mosaic 
%   to the same stimuli used to measure the DF/F STF. The responses from the 
%   model cone mosaic are computed by calling
%   runBatchGenerateConeMosaicResponsesAOSLOOpticsResidualDefocus()
%   The derived cone pooling model is saved on the disk.
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         
% History:
%    March 2022   NPC    Wrote it
%

    % Monkey to employ
    monkeyID = 'M838';

    % Choose what operation to run.
    operation = simulator.operations.fitFluorescenceSTFresponses;

    % Always use the monochromatic AO stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % Choose which optics scenario to run.
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = ...
        {'single-cone', 'multi-cone'};

    % Select the spatial sampling within the cone mosaic
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options
    operationOptions.fitParams = struct(...
        'multiStartsNum', 512, ...
        'accountForNegativeSTFdata', true, ...
        'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
        );
    
     % Which RGCs to fit
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);


    % Do the fit for each cell
    for iRGCindex = 1:numel(coneRGCindices)    
        
        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        % Synthesize RGCID string
        RGCIDstring = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex);
        
        % Select optimal residual defocus for deriving the synthetic RGC model
        operationOptions.residualDefocusDiopters = simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(...
            monkeyID, RGCIDstring);
        
        % OR a single defocus
        %operationOptions.residualDefocusDiopters = 0.067;
            
        % All set, go!
        simulator.performOperation(operation, operationOptions, monkeyID);
    end
end