function dataOut = performOperation(operation, operationOptions, monkeyID)
% Configure the selected operation and run it
%
% Syntax:
%   simulator.performOperation(operation, operationOptions, monkeyID)
%
% Description:
%   Configure the selected operation and run it
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None

    % Assert that we have a valid operation
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    % Set stimulus params based on selected stimulusType enumeration
    switch (operationOptions.stimulusType)
        case simulator.stimTypes.monochromaticAO
            options.stimulusParams = simulator.params.AOSLOStimulus();

        case simulator.stimTypes.achromaticLCD
            % Achromatic (LCD) stimulus params
            options.stimulusParams = simulator.params.LCDAchromaticStimulus();

        otherwise
            error('Unknown stimulus type: ''%s''.', operationOptions.stimulusType)
    end

    % Set optics params based on selected opticsScenario enumeration
    if (ismember(operation, [simulator.operations.fitCrossValidationModelsToFluorescenceSTFresponses, ...
                             simulator.operations.testCrossValidationModelsToFluoresceneSTFresponses]))
        crossValidatedModelsNum = numel(operationOptions.opticsScenario);
        for iCrossValidationModelIndex = 1:crossValidatedModelsNum
            options.opticsParams{iCrossValidationModelIndex} = opticsParamsForScenario(...
                    operationOptions.opticsScenario(iCrossValidationModelIndex), operationOptions, options.stimulusParams, iCrossValidationModelIndex);
        end
    else
        options.opticsParams = opticsParamsForScenario(...
             operationOptions.opticsScenario, operationOptions, options.stimulusParams, 1);
    end
    
    % Set spatial frequency support for the STF measurements
    dStruct = simulator.load.fluorescenceSTFdata(monkeyID);
    options.stimulusParams.STFspatialFrequencySupport = dStruct.spatialFrequencySupport;
    clear 'dStruct'

    % Set the cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);


    dataOut = [];

    % Switch
    switch (operation)
        case simulator.operations.computeSynthesizedRGCSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(...
                monkeyID, options);

            % Synthesize the filename of the file than contains the synthetic RGC model
            syntheticRGCmodelFilename = simulator.filename.fittedRGCmodel(...
                monkeyID, ...
                operationOptions.syntheticRGCmodelParams, ...
                operationOptions.coneMosaicSamplingParams, ...
                operationOptions.fitParams, ...
                operationOptions.STFdataToFit);

            % Synthesize PSF filename for the synthetic STF
            syntheticSTFdataPDFFilename = simulator.filename.syntheticSTFPDF(...
                monkeyID, options, operationOptions.STFdataToFit, ...
                operationOptions.syntheticRGCmodelParams.opticsParams.residualDefocusDiopters);
            

            % Compute synthetic RGC responses for the stimuli used to measure
            % the RGC spatial transfer functions (STFs)
            dataOut = simulator.compute.syntheticRGCSTF(syntheticRGCmodelFilename, ...
                coneMosaicResponsesFileName, ...
                syntheticSTFdataPDFFilename, ...
                operationOptions.syntheticSTFtoFit, ...
                operationOptions.syntheticSTFtoFitComponentWeights, ...
                operationOptions.STFdataToFit, ...
                operationOptions.syntheticRGCmodelParams.rfCenterConePoolingScenario, ...
                operationOptions.syntheticRGCmodelParams.opticsParams.residualDefocusDiopters, ...
                operationOptions.syntheticRGCmodelParams.rmsSelector);

            % Also return the cone mosaic responses filename
            dataOut.coneMosaicResponsesFileName = coneMosaicResponsesFileName;
            
        
        case { simulator.operations.fitCrossValidationModelsToFluorescenceSTFresponses, ...
               simulator.operations.testCrossValidationModelsToFluoresceneSTFresponses }
            
            % Train each of the cross-validated models to data from each  session
            sessionsNum = size(operationOptions.STFdataToFit.responses,3);

            for iCrossValidationModelIndex = 1:crossValidatedModelsNum
                % Update opticsParams options for this cross-validated model
                optionsForCrossValidationModel = options;
                optionsForCrossValidationModel.opticsParams = options.opticsParams{iCrossValidationModelIndex};
                
                % Update center cone composition for this cross-validated model
                operationOptionsForCrossValidationModel = operationOptions;
                operationOptionsForCrossValidationModel.rfCenterConePoolingScenariosExamined = ...
                    {operationOptions.rfCenterConePoolingScenariosExamined{iCrossValidationModelIndex}};

                % Generate corresponding cone mosaic responses filename
                coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, optionsForCrossValidationModel);

                crossValidationModelDescriptor = sprintf('''%s'', %2.3fD residual defocus', ...
                    operationOptionsForCrossValidationModel.rfCenterConePoolingScenariosExamined{1}, ...
                    optionsForCrossValidationModel.opticsParams.residualDefocusDiopters);

                if (operation == simulator.operations.fitCrossValidationModelsToFluorescenceSTFresponses)

                    % Fit cross-validation model separately for each session
                    for iSession = 1:sessionsNum
                        fprintf('Fitting cross-validation model #%d (%s) on data from session %d / %d\n', ...
                            iCrossValidationModelIndex, ...
                            crossValidationModelDescriptor, ...
                            iSession, sessionsNum);
    
                        % Get session to fit
                        singleSessionSTFdataToFit = operationOptionsForCrossValidationModel.STFdataToFit;
                        singleSessionSTFdataToFit.responses = operationOptionsForCrossValidationModel.STFdataToFit.responses(:,:,iSession);
                        singleSessionSTFdataToFit.responseSE = operationOptionsForCrossValidationModel.STFdataToFit.responseSE(:,:,iSession);
    
                        % Synthesize filename for the cross-validated RGCmodel trained on this session
                        fittedCrossValidationSingleSessionModelFileName = simulator.filename.fittedCrossValidationSingleSessionTrainRGCmodel(monkeyID, ...
                            optionsForCrossValidationModel, ...
                            operationOptionsForCrossValidationModel.rfCenterConePoolingScenariosExamined{1}, ...
                            operationOptionsForCrossValidationModel.coneMosaicSamplingParams, ...
                            operationOptionsForCrossValidationModel.fitParams, ...
                            singleSessionSTFdataToFit, iSession);
                    
                        % Fit the model
                        simulator.fit.fluorescenceSTFData(...
                            singleSessionSTFdataToFit, ...
                            operationOptionsForCrossValidationModel.fitParams, ...
                            operationOptionsForCrossValidationModel.coneMosaicSamplingParams, ...
                            operationOptionsForCrossValidationModel.rfCenterConePoolingScenariosExamined, ...
                            coneMosaicResponsesFileName, ...
                            fittedCrossValidationSingleSessionModelFileName);
                    end % iSession

                else
                    % Test cross-validation model trained on one session
                    % to data from the remaining sessions, allowing for
                    % scaling only

                    inSampleErrors = zeros(sessionsNum,1);
                    outOfSampleErrors = zeros(sessionsNum, sessionsNum-1);

                    for iTrainSession = 1:sessionsNum

                        fprintf('Testing cross-validation model #%d (%s) trained on session %d / %d\n', ...
                            iCrossValidationModelIndex, ...
                            crossValidationModelDescriptor, ...
                            iTrainSession, sessionsNum);

                        % Get session to fit
                        singleSessionSTFdataToFit = operationOptionsForCrossValidationModel.STFdataToFit;
                        singleSessionSTFdataToFit.responses = operationOptionsForCrossValidationModel.STFdataToFit.responses(:,:,iTrainSession);
                        singleSessionSTFdataToFit.responseSE = operationOptionsForCrossValidationModel.STFdataToFit.responseSE(:,:,iTrainSession);
                        
                        % Synthesize filename for the cross-validated RGCmodel trained on this session
                        fittedCrossValidationSingleSessionModelFileName = simulator.filename.fittedCrossValidationSingleSessionTrainRGCmodel(monkeyID, ...
                            optionsForCrossValidationModel, ...
                            operationOptionsForCrossValidationModel.rfCenterConePoolingScenariosExamined{1}, ...
                            operationOptionsForCrossValidationModel.coneMosaicSamplingParams, ...
                            operationOptionsForCrossValidationModel.fitParams, ...
                            singleSessionSTFdataToFit, iTrainSession);

                        % Load the trained cross-validation model
                        load(fittedCrossValidationSingleSessionModelFileName, ...
                                'STFdataToFit', 'theConeMosaic', 'fittedModels');

                        theKeys = keys(fittedModels);
                        if (numel(theKeys)>1)
                            error('There should have been just 1 model here');
                        end
                        theTrainedCrossValidationModel = fittedModels(theKeys{1});
                        theSTFdataUsedToTrainTheCrossValidationModel = STFdataToFit;

                        % Test sessions
                        testSessions = setdiff(1:sessionsNum, iTrainSession);
                        for iTestSession = 1:numel(testSessions)
                            % Get session to fit
                            validationSession = testSessions(iTestSession);
                            singleSessionSTFdataToFit = operationOptionsForCrossValidationModel.STFdataToFit;
                            singleSessionSTFdataToFit.responses = operationOptionsForCrossValidationModel.STFdataToFit.responses(:,:,validationSession);
                            singleSessionSTFdataToFit.responseSE = operationOptionsForCrossValidationModel.STFdataToFit.responseSE(:,:,validationSession);
                            singleSessionSTFdataToFit.fitParams = operationOptionsForCrossValidationModel.fitParams;
                        
                            [inSampleErrors(iTrainSession), outOfSampleErrors(iTrainSession,iTestSession)] = ...
                            simulator.fit.fluorescenceSTFDataUsingCrossValidationModel(...
                                 singleSessionSTFdataToFit, ...
                                 theTrainedCrossValidationModel, ...
                                 theSTFdataUsedToTrainTheCrossValidationModel, ...
                                 iTrainSession, validationSession);
                        end % iTestSession
                    end % iTrainSession

                    % Evaluate net cross-validation performance here
                    dataOut.crossValidationModelDesriptor{iCrossValidationModelIndex} = crossValidationModelDescriptor;
                    dataOut.inSampleErrors(iCrossValidationModelIndex,:) = ...
                        inSampleErrors(:);
                    dataOut.outOfSampleErrors(iCrossValidationModelIndex,:) = ...
                        outOfSampleErrors(:);
                end
            end % iCrossValidationModelIndex

        case simulator.operations.fitFluorescenceSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            % Synthesize filename for the fitted RGCmodel 
            fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
                operationOptions.coneMosaicSamplingParams, operationOptions.fitParams, operationOptions.STFdataToFit);

            % Fit the model
            simulator.fit.fluorescenceSTFData(...
                operationOptions.STFdataToFit, ...
                operationOptions.fitParams, ...
                operationOptions.coneMosaicSamplingParams, ...
                operationOptions.rfCenterConePoolingScenariosExamined, ...
                coneMosaicResponsesFileName, ...
                fittedModelFileName);

        case simulator.operations.extractFittedModelPerformance
            % Synthesize filename for the fitted RGCmodel  
            fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
                operationOptions.coneMosaicSamplingParams, ...
                operationOptions.fitParams, ...
                operationOptions.STFdataToFit);

            % Extract rms performance at best position
            dataOut = simulator.analyze.fittedRGCModelPerformance(fittedModelFileName,operationOptions);

        case simulator.operations.visualizedFittedModels
            % Synthesize filename for the fitted RGCmodel  
            fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
                operationOptions.coneMosaicSamplingParams, ...
                operationOptions.fitParams, ...
                operationOptions.STFdataToFit);
            
            % Synthesize filenames for the PDFs of the fitted RGCmodel
            [fittedModelFilenameAllPositionsPDF, ...
             fittedModelFilenameBestPositionPDF] = simulator.filename.fittedRGCmodelPDFs(...
                        monkeyID, options, ...
                        operationOptions.coneMosaicSamplingParams, ...
                        operationOptions.fitParams, ...
                        operationOptions.STFdataToFit);

            % Visualize fitted model
            simulator.visualize.fittedRGCModel(fittedModelFileName,operationOptions, ...
                fittedModelFilenameAllPositionsPDF, fittedModelFilenameBestPositionPDF);


        case simulator.operations.visualizeConeMosaicSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            % Visualize responses
            visualizedDomainRangeMicrons = 60;
%             d = simulator.visualize.coneMosaicSTFresponses(coneMosaicResponsesFileName, ...
%                 'visualizedDomainRangeMicrons', visualizedDomainRangeMicrons, ...
%                 'framesToVisualize', [1]);

            % Video
            visualizedDomainRangeMicrons = 20;
            d = simulator.visualize.coneMosaicSTFresponses(coneMosaicResponsesFileName, ...
                'visualizedDomainRangeMicrons', visualizedDomainRangeMicrons, ...
                'framesToVisualize', []);

            if (~isempty(d))
                % Co-visualize the cone mosaic with the PSF
                % Generate optics using the desired optics params
                [~, thePSFdata] = simulator.optics.generate(monkeyID, options.opticsParams);
    
                % Import the cone mosaic
                load(coneMosaicResponsesFileName, 'theConeMosaic');
    
                % Visualize the cone mosaic and the PSF
                simulator.visualize.mosaicAndPSF(theConeMosaic, thePSFdata, visualizedDomainRangeMicrons, ...
                    WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                    'figureHandle', d.hFig, ...
                    'axesHandle', d.axPSF);
            end


        case simulator.operations.computeConeMosaicSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            % Modify the default cone mosaic with the examined cone mosaic params
            theConeMosaic = simulator.coneMosaic.modify(monkeyID, options.cMosaicParams);
            
            % Generate optics using the desired optics params
            [theOI, thePSFdata] = simulator.optics.generate(monkeyID, options.opticsParams);
    
            % Visualize mosaic and PSF
            visualizedDomainRangeMicrons = 50;
            simulator.visualize.mosaicAndPSF(theConeMosaic, thePSFdata, visualizedDomainRangeMicrons, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'noConeMosaic', ~true, ...
                'displayXYslices', true);
            
            % Compute cone mosaic responses for the stimuli used to measure
            % the RGC spatial transfer functions (STFs)
            simulator.compute.coneMosaicSTF(options.stimulusParams, ...
                theOI, theConeMosaic, coneMosaicResponsesFileName);

       case simulator.operations.generateConeMosaic

           % Generate the cone mosaic
           simulator.coneMosaic.generate(monkeyID, operationOptions.recomputeMosaic);

    end

end



function opticsParams = opticsParamsForScenario(opticsScenario, operationOptions, stimulusParams, residualDefocusIndex)
         
    switch (opticsScenario)
        case simulator.opticsScenarios.diffrLimitedOptics_residualDefocus

            % Diffraction-limited optics with defocus-based residual blur
            opticsParams = struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', operationOptions.residualDefocusDiopters(residualDefocusIndex), ...
                'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
                'wavelengthSupport', stimulusParams.wavelengthSupport);

        case simulator.opticsScenarios.diffrLimitedOptics_GaussianBlur
            % Diffraction-limited optics with Gaussian-based residual blur 
            error('Optic scenario ''%s'' is not implemented yet', simulator.opticsScenarios.diffrLimitedOptics_GaussianBlur);

        case simulator.opticsScenarios.M838Optics
            % M838 optics
            opticsParams = struct(...
                'type', simulator.opticsTypes.M838, ...
                'pupilSizeMM', operationOptions.pupilSizeMM, ...
                'wavelengthSupport', stimulusParams.wavelengthSupport);

        case simulator.opticsScenarios.PolansOptics
            % Polans optics
            opticsParams = struct(...
                'type', simulator.opticsTypes.Polans, ...
                'subjectID', operationOptions.subjectID, ...
                'pupilSizeMM', operationOptions.pupilSizeMM, ...
                'wavelengthSupport', stimulusParams.wavelengthSupport);


        otherwise
            error('Unknown optics scenario: ''%s''.', opticsScenario);
    end
end
