function runBatchVisualize
% Batch visualize a number of RGC models for different conditions
%
% Syntax:
%   runBatchFit()
%
% Description:
%   Batch visualize a number of RGC models for different conditions
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

    % Choose which optics scenario to run.
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;

    % Monochromatic stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = ...
        {'multi-cone'};

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
    

    % How to select the best cone position
    % choose between {'weighted', 'unweighted'} RMSE
    operationOptions.rmsSelector = 'unweighted';


    % Operation to run
    operation = simulator.operations.visualizedFittedModels;


    % Examined RGCs
    centerConeType = 'L';
    coneRGCindicesExamined = 1:11;

    % Examined residual defocus values
    residualDefocusDiopterValuesExamined = [0.067]; %[0.00 0.067];

    for iResidualDefocus = 1:numel(residualDefocusDiopterValuesExamined)
        operationOptions.residualDefocusDiopters = residualDefocusDiopterValuesExamined(iResidualDefocus);
   
        for iConeRGCindex = 1:numel(coneRGCindicesExamined)
            % Select which recording session and which RGC to fit. 
            operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                 'whichSession', 'meanOverSessions', ...
                 'whichCenterConeType', centerConeType, ...
                 'whichRGCindex', coneRGCindicesExamined(iConeRGCindex));
            
            simulator.performOperation(operation, operationOptions, monkeyID);
        end
    end



end