function runMain()
% Main gateway to all operations
%
% Syntax:
%   runMain()
%
% Description:
%   Main gateway to all operations
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
    % To list the available options, type:
    %    enumeration simulator.opticsScenarios
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
    operationOptions.residualDefocusDiopters = 0.067;
    %operationOptions.residualDefocusDiopters = 0.000;

    % M838, 2.5 mm pupil optics scenario
    %operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
    %operationOptions.pupilSizeMM = 2.5;


    % Choose which stimulus type to use.
    % To list the available options, type:
    %    enumeration simulator.stimTypes
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;
    %operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;

    % Choose what operation to run.
    % To list the available options, type:
    %    enumeration simulator.operations

    % --------------------------------------
    % 1. Generate cone mosaic
    % --------------------------------------
    %operation = simulator.operations.generateConeMosaic;
    %operationOptions.recomputeMosaic = ~true;
    
    % -----------------------------------------------------------------
    % 2. Compute cone mosaic responses
    % -----------------------------------------------------------------
    %operation = simulator.operations.computeConeMosaicSTFresponses;

    % -----------------------------------------------------------------
    % 3. Visualize cone mosaic responses
    % -----------------------------------------------------------------
    operation = simulator.operations.visualizeConeMosaicSTFresponses;
    
    
    % -----------------------------------------------------------------
    % 4. Fit fluorescence STF responses for some modeling scenario
    % -----------------------------------------------------------------
    operation = simulator.operations.fitFluorescenceSTFresponses;

    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = ...
        {'single-cone', 'multi-cone'};

    % Select which recording session and which RGC to fit. 
    operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
        'whichSession', 'meanOverSessions', ...
        'whichCenterConeType', 'M', ...
        'whichRGCindex', 4);
 
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
    

    % -----------------------------------------------------------------
    % 5. Visualize model fits for some modeling scenario
    % -----------------------------------------------------------------
    % How to select the best cone position
    % choose between {'weighted', 'unweighted'} RMSE
    operationOptions.rmsSelector = 'unweighted';
    operation = simulator.operations.visualizedFittedModels;

    % Go !
    simulator.performOperation(operation, operationOptions, monkeyID);
end

