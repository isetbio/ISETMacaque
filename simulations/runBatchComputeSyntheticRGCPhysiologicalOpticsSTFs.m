function runBatchComputeSyntheticRGCPhysiologicalOpticsSTFs()
% Batch generate and analyze STFs by applying synthetic RGC cone pooling models
% to cone mosaic responses obtained under physiological optics.
%
% Syntax:
%   runBatchComputeSyntheticRGCPhysiologicalOpticsSTFs()
%
% Description:
%   Batch generate STFs by applying synthetic RGC cone pooling models (derived 
%   by fitting center/surround pooled  weighted cone mosaic responses to 
%   diffraction-limited DF/F STF measurements - see runBatchFit()) to cone 
%   mosaic responses obtained under physiological optics. 
%   Then fit the generated STFs using a DoG model and generate figures with 
%   key parameters of the DoG model.
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

    % Choose what operation to run.
    operation = simulator.operations.computeSynthesizedRGCSTFresponses;

    % Here we are using an achromatic stimulus, matching a typical achromatic STF experiment
    operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;

    % Choose which optics scenario to run. 
    % M838 physiological optics with 2.5 mm pupil
    operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
    operationOptions.pupilSizeMM = 2.5;

    % Or choose Polans subject physiological optics
%     operationOptions.opticsScenario = simulator.opticsScenarios.PolansOptics;
%     operationOptions.subjectID = 2; % [2 8 9]
%     operationOptions.pupilSizeMM = 3.0;
    
 
    % Select the spatial sampling within the cone mosaic
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea". This must match what was
    % specified in runBatchFit()
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...     % select cones within the central 6 arc min
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options - this will select which RGC model to employ
    operationOptions.fitParams = struct(...
         'multiStartsNum', 512, ...
         'accountForNegativeSTFdata', true, ...
         'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
         );
    
   
    % Get all recorded RGC info
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);


    % Run for all non lowpass RGCs
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID, ...
        'excludedRGCIDs', simulator.animalInfo.lowPassRGCs(monkeyID));


    residualDefocusDioptersExamined = -99;     % This will use each cell's optimal residual defocus
    residualDefocusDioptersExamined = 0.067;

    dataOut = cell(1, numel(coneRGCindices));
    for iRGCindex = 1:numel(coneRGCindices)    
        
        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        if (residualDefocusDioptersExamined == -99)
            % Optimal residual defocus for each cell
            residualDefocusForModel = ...
                    simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                    sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));
        else
           % Examined residual defocus
           residualDefocusForModel = residualDefocusDioptersExamined;
        end

        operationOptions.residualDefocusDiopters = [];


        % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        operationOptions.syntheticSTFtoFit = 'compositeCenterSurroundResponseBased';
        %operationOptions.syntheticSTFtoFit = 'weightedComponentCenterSurroundResponseBased';

        operationOptions.syntheticSTFtoFitComponentWeights = struct(...
            'center', 0, ...
            'surround', 0, ...
            'composite', 1);
            
        % Params used to derive the (single-cone center)RGC model. 
        % The important parameter here is the residualDefocus assumed
        operationOptions.syntheticRGCmodelParams = struct(...
            'opticsParams', struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', residualDefocusForModel), ...
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

