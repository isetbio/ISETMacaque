function computeISETBioModelSTFdata
    % Select stimulus
    stimulusType = 'LCDdisplayAchromatic'; % 'AO'; % 'LCDdisplayAchromatic';;

    switch (stimulusType)
         case 'AO'
             % Monochromatic AO stimulus employed by Williams lab
             visualStimulus = struct(...
                 'type', 'WilliamsLabStimulus', ...
                 'stimulationDurationCycles', 4 ...
             );
         case 'LCDdisplayAchromatic'
            visualStimulus = struct(...
                 'type', 'CRT', ...
                 'stimulationDurationCycles', 4, ...
                 'backgroundChromaticity', [0.31 0.32], ...
                 'backgroundLuminanceCdM2', 1802, ...  % Match the AO stimulus luminance
                 'lmsConeContrasts', [1 1 1] ...
            );
    end

    monkeyID = 'M838';

    
    % Load a fitted model
    % Model variant to use for the cone pooling weights
    % L4-cone weights
    targetLcenterRGCindices = [8];
    targetMcenterRGCindices = [];
    startingPointsNum = 512;

    accountForResponseOffset = true;
    fitBias = 'none';                           % 1/stdErr
    fitBias = 'boostHighSpatialFrequencies';
    %fitBias = 'flat'; 

    modelVariant = struct(...
        'centerConesSchema', 'single', ...
        'residualDefocusDiopters', 0.067, ...
        'coneCouplingLambda', 0, ...
        'transducerFunctionAccountsForResponseOffset', accountForResponseOffset, ...
        'transducerFunctionAccountsForResponseSign', false, ...
        'fitBias', fitBias);

    operationMode = 'fitModelOnSessionAveragedData';
%   operationMode = 'fitModelOnSingleSessionData';

    switch (operationMode)
        case 'fitModelOnSessionAveragedData'
            % Fit the model on the average (over all sessions) data
            crossValidateModel = false;
            crossValidateModelAgainstAllSessions = false;
            trainModel = [];

        case 'fitModelOnSingleSessionData'
            % Fit the model on single sessions
            crossValidateModel = true;
            crossValidateModelAgainstAllSessions = false;
            trainModel = true;
          
        case 'crossValidateFittedModelOnSingleSessionData'
            % Cross-validate the fitted model on other sessions
            crossValidateModel = true;
            crossValidateModelAgainstAllSessions = false;
            trainModel = false;

        case 'crossValidateFittedModelOnAllSessionData'
            % Cross-validate the fitted model on other sessions
            crossValidateModel = true;
            crossValidateModelAgainstAllSessions = true;
            trainModel = false;
    end

    theTrainedModelFitsfilename = fitsFilename(modelVariant, startingPointsNum, ...
                        crossValidateModel, crossValidateModelAgainstAllSessions, trainModel, ...
                        targetLcenterRGCindices, targetMcenterRGCindices);

    [dModel, dData] = loadModelAndAverageSessionMeasuredData(theTrainedModelFitsfilename, monkeyID);
    
    % Select the model with smallest RMSerror to the data it was fitted to
    [~, theMinRMSmodelIndex] = min(dModel.rmsErrors);

    % Extract the model params for the selected model
    centerConeIndices = dModel.centerConeIndices{theMinRMSmodelIndex};
    centerConeWeights = dModel.centerConeWeights{theMinRMSmodelIndex};
    surroundConeIndices = dModel.surroundConeIndices{theMinRMSmodelIndex};
    surroundConeWeights = dModel.surroundConeWeights{theMinRMSmodelIndex};
    DoGparams = dModel.fittedParamsPositionExamined(theMinRMSmodelIndex,:);
    theFittedSTF = squeeze(dModel.fittedSTFs(theMinRMSmodelIndex,:));
    
    

    % Load the cone mosaic responses
    residualDefocus = 0.001;  % this was run for a pupil size of 2.0 mm
    sParams = struct(...
        'apertureParams', struct('shape', 'Gaussian', 'sigma', 0.204), ...
        'modelVariant', struct('coneCouplingLambda', 0, 'residualDefocusDiopters', residualDefocus), ...
        'PolansSubject', 838, ...
        'visualStimulus', visualStimulus);
    modelSTFrunData = loadConeMosaicSTFResponses(monkeyID, sParams);

    % Center model cone responses
    centerConeResponses = modelSTFrunData.coneMosaicSpatiotemporalActivation(:,:,centerConeIndices);
    
    % Surround model cone responses
    centerConeResponses = modelSTFrunData.coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices);

    Kc = DoGparams(1);
    KsToKc = DoGparams(2);
    Ks = Kc * KsToKc;

    modelRGCresponses = computeRGCresponseByPoolingConeMosaicResponses( ...
            centerConeResponses , ...
            centerConeResponses, ...
            centerConeWeights, ...
            surroundConeWeights, ...
            Kc, Ks);

    % Fit a sinusoid to the time series responses for each spatial frequency
    % The amplitude of the sinusoid is the STFmagnitude at that spatial frequency
    sfsNum = size(modelRGCresponses ,1);
    theModelSTF = zeros(1, sfsNum);
    %timeHR = linspace(constants.temporalSupportSeconds(1), constants.temporalSupportSeconds(end), 100);
    
    for iSF = 1:sfsNum

        % Fit sinusoid to the compund center-surround responses.
        % This forces the STF amplitude to be non-negative, which can lead to
        % issues with the fluorescene STF data which for some cells go
        % negative at low spatial frequencies. So we assign a positive sign
        % if (theModelCenterSTF(iSF) > theModelSurroundSTF(iSF)), 
        % and a negative sign otherwise

        [~, fittedParams] = ...
            fitSinusoidToResponseTimeSeries(...
            modelSTFrunData.temporalSupportSeconds, ...
            modelRGCresponses(iSF,:), ...
            WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
            []);
        STFamplitude = fittedParams(1);

        fluorescenceDC = 0;
        theModelSTF(iSF) = fluorescenceDC + STFamplitude;
    end

    figure(100); clf;
    plot(modelSTFrunData.examinedSpatialFrequencies, theFittedSTF/max(theFittedSTF), 'ko-');
    hold on;
    plot(modelSTFrunData.examinedSpatialFrequencies, theModelSTF/max(theModelSTF), 'r-');

end

function modelSTFrunData = loadConeMosaicSTFResponses(monkeyID, sParams)

    % Load the ISETBio computed time-series responses for the simulated STF run
    modelSTFrunData = loadPrecomputedISETBioConeMosaicSTFrunData(monkeyID, sParams);

    % Transform excitations signal (e) to a contrast signal (c), using the
    % background excitations signal (b): c = (e-b)/b;
    b = modelSTFrunData.coneMosaicBackgroundActivation;
    modelSTFrunData.coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, modelSTFrunData.coneMosaicSpatiotemporalActivation, b), 1./b);

end

