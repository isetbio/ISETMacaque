function runBatchComputeSyntheticRGCPhysiologicalOpticsSTFs()
% Batch generate synthetic RGC STFs under physiological optics
%
% Syntax:
%   runBatchComputeSyntheticRGCPhysiologicalOpticsSTFs()
%
% Description:
%   Batch generate synthetic RGC STFs under physiological optics, fit the
%   obtained STFs and generate figures with population statistics.
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

    % Monkey to analyze
    monkeyID = 'M838';

    % Choose which optics scenario to run. This overrides default
    % values set in simulator.performOperation().

    % M838 optics scenario
    operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
    operationOptions.pupilSizeMM = 2.5;

    % Polans subject optics scenario
    operationOptions.opticsScenario = simulator.opticsScenarios.PolansOptics;
    operationOptions.subjectID = 2; % [2 8 9]
    operationOptions.pupilSizeMM = 3.0;
    

    % Choose which stimulus type to use. This overrides default
    % values set in simulator.performOperation().
    % To list the available options, type:
    %    enumeration simulator.stimTypes
    operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;

 
    % Select the location of the synthetic RGCs by sampling cone positions
    % within the central cone mosaic.
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...     % select cones within the central 6 arc min
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options
    operationOptions.fitParams = struct(...
        'multiStartsNum', 512, ...
        'accountForNegativeSTFdata', true, ...
        'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
        );
    
    % Compute synthesized STF responses
    operation = simulator.operations.computeSynthesizedRGCSTFresponses;
   
     % Get all recorded RGC infos
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    dataOut = cell(1, numel(coneRGCindices));
    for iRGCindex = 1:numel(coneRGCindices)    
        
        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        % Synthesize RGCID string
        RGCIDstring = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex);
        
        % Select optimal residual defocus for deriving the synthetic RGC model
        residualDefocus = simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(...
            monkeyID, RGCIDstring);
        
         % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        % Params used to derive the (single-cone center)RGC model. 
        % The important parameter here is the residualDefocus assumed
        operationOptions.syntheticRGCmodelParams = struct(...
            'opticsParams', struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', residualDefocus), ...
            'stimulusParams', struct(...
                'type', simulator.stimTypes.monochromaticAO), ...
            'cMosaicParams', struct(...
                'coneCouplingLambda', 0.0), ...
            'rfCenterConePoolingScenario', 'single-cone', ...
            'rmsSelector', 'unweighted'...
          );
    
        % Go !
        dataOut{iRGCindex} = simulator.performOperation(operation, operationOptions, monkeyID);
    end
    
    % Visualize population Rc/Rs stats
    simulator.visualize.populationRcRsStats(dataOut);
    
    % Visualize population Ks/Kc stats
    simulator.visualize.populationKsKcStats(dataOut);
    
    % Visualize population integrated surround/center sensitivity stats
    simulator.visualize.populationIntegratedSurroundCenterSensitivityStats(dataOut);
end

