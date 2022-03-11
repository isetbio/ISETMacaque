function runMain()
% Main gateway to all operations
%
% Syntax:
%   selectOperation()
%
% Description:
%   Select which operation to run (e.g., generate cone mosaic responses, fit etc)
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
    %operation = simulator.operations.fitFluorescenceSTFresponses;

    % Select which recording session and which cell to fit. 
    operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
        'whichSession', 'meanOverSessions', ...
        'whichCenterConeType', 'L', ...
        'whichRGCindices', [8]);
 
    % 
    operationOptions.fitOptions = struct(...
        'multiStartsNum', 512, ...
        'accountForNegativeSTFdata', true, ...
        'spatialFrequencyBias', 'boostHighSpatialFrequencies' ...
        );
    
    % Go !
    runOperation(operation, operationOptions, monkeyID);
end

