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
        {'single-cone'};

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


    % Examined RGCs (all 11 L-center and 4 M-center)
    LconeRGCsNum  = 11;
    MconeRGCsNum = 4;
    coneTypes(1:LconeRGCsNum) = {'L'};
    coneTypes(LconeRGCsNum+(1:MconeRGCsNum)) = {'M'};
    coneRGCindices(1:LconeRGCsNum) = 1:LconeRGCsNum;
    coneRGCindices(LconeRGCsNum+(1:MconeRGCsNum)) = 1:MconeRGCsNum;

    for iRGCindex = 1:numel(coneRGCindices)
        
         % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'meanOverSessions', ...
            'whichCenterConeType', coneTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));
        
        % Synthesize RGCID string
        RGCIDstring = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex);
        
        % Select optimal residual defocus for deriving the synthetic RGC model
        operationOptions.residualDefocusDiopters = simulator.optimalResidualDefocusForSingleConeCenterRFmodel(...
            monkeyID, RGCIDstring);
        % Go
        simulator.performOperation(operation, operationOptions, monkeyID); 
    end

end