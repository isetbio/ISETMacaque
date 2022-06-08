function runModelCrossValidation
% Cross-validate different models

    % Monkey to employ
    monkeyID = 'M838';

    % Choose what operation to run.
    operation = simulator.operations.fitAndCrossValidateFluorescenceSTFresponses;

    % Always use the monochromatic AO stimulus
    operationOptions.stimulusType = simulator.stimTypes.monochromaticAO;

    % The 4-optics scenarios for the 4 models to be cross-validated.
    operationOptions.opticsScenario = [...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus ...
        simulator.opticsScenarios.diffrLimitedOptics_residualDefocus];

    % The residual defocus values for the 4 models to be cross-validated.
    residualDefocusDiopter = [...
        0.0 ...
        0.0 ...
        0.067 ...
        0.067]; 

    % RF center pooling scenarios for the 4 models to be cross-validated.
    operationOptions.rfCenterConePoolingScenariosExamined = { ...
        'single-cone' ...
        'multi-cone' ...
        'single-cone' ...
        'multi-cone'};

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
    
    % Get all recorded RGC infos
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    % Or analyze a specific RGC
    centerConeTypes = {'L'};
    coneRGCindices = 10;


    % Do the cross-validated fit for each cell
    for iRGCindex = 1:numel(coneRGCindices) 

        % Select all sessions (not the mean over sessions) and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
            'whichSession', 'allSessions', ...
            'whichCenterConeType', centerConeTypes{iRGCindex}, ...
            'whichRGCindex', coneRGCindices(iRGCindex));

        % Set operationOptions.residualDefocusDiopters for all models
        for iResidualDefocusIndex = 1:numel(residualDefocusDiopter)
            if (residualDefocusDiopter(iResidualDefocusIndex) == -99)
                operationOptions.residualDefocusDiopters(iResidualDefocusIndex) = ...
                    simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, ...
                       sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex));

            else
                operationOptions.residualDefocusDiopters(iResidualDefocusIndex) = ...
                    residualDefocusDiopter(iResidualDefocusIndex);
            end
        end

         % All set, go!
        simulator.performOperation(operation, operationOptions, monkeyID);
    end

end

