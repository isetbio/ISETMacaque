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

    % Model scenario to examine
    operationOptions.modelScenario = simulator.modelScenarios.diffrLimitedOptics_residualDefocus_MonochromaticGrating;
    operationOptions.residualDefocusDiopters = 0.0;

    % Choose operation
    % --------------------------------------
    % 1. Generate cone mosaic
    % --------------------------------------
    %operation = simulator.operations.generateConeMosaic;
    %operationOptions.recomputeMosaic = ~true;
    
    % -----------------------------------------------------------------
    % 2. Compute cone mosaic responses
    % -----------------------------------------------------------------
    operation = simulator.operations.computeConeMosaicSTFresponses;

    % -----------------------------------------------------------------
    % 3. Visualize cone mosaic responses
    % -----------------------------------------------------------------
    %operation = simulator.operations.visualizeConeMosaicSTFresponses;
    
    
    % -----------------------------------------------------------------
    % 4. Fit fluorescence STF responses for some modeling scenario
    % -----------------------------------------------------------------
    %operation = simulator.operations.fitFluorescenceSTFresponses;

    % Select the diffraction-limited optics, 0.067D residual defocus model scenario
    operationOptions.STFdataToFit = simulator.fluorescenceResponseData.meanOverAllSessions;


    % Or, select the M838, 2.5 mm pupil model scenario
    %operationOptions.modelScenario = simulator.modelScenario.M838Optics_AchromaticGrating
    %operationOptioncs.M838PupilSizeMM = 2.5;
    
    % Go !
    runOperation(operation, operationOptions, monkeyID);
end

