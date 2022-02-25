function computeISETBioModelSTFdata
    

    pupilDiamForPhysiologicalOptics = 2.5;
    
    
doLcells = false;
doMcells = true;

if (doLcells)
    targetMcenterRGCindices = [];
    
    % Load a fitted model

     targetLcenterRGCindices = [3];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
    
    targetLcenterRGCindices = [4];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
    
    targetLcenterRGCindices = [6];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.00;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
    
     targetLcenterRGCindices = [7];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.0;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
    
    targetLcenterRGCindices = [8];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.0;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
    
    
    targetLcenterRGCindices = [10];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)

%     
    targetLcenterRGCindices = [11];
    accountForResponseOffset = true;                     
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)

end

if (doMcells)
    targetLcenterRGCindices = [];
    
    targetMcenterRGCindices = [1];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
   fittedModelResidualDefocus = 0.067;
   doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)

    targetMcenterRGCindices = [2];
    accountForResponseOffset = true;                      
    fitBias = 'flat';
    fittedModelResidualDefocus = 0.067;
   doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)

     targetMcenterRGCindices = [4];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
   doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)

end

    

end

function doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
        
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
    
    startingPointsNum = 512;

    
    % Select the single cone center, with residual defocus of fittedModelResidualDefocus
    modelVariant = struct(...
        'centerConesSchema', 'single', ...
        'residualDefocusDiopters', fittedModelResidualDefocus, ...
        'coneCouplingLambda', 0, ...
        'transducerFunctionAccountsForResponseOffset', accountForResponseOffset, ...
        'transducerFunctionAccountsForResponseSign', false, ...
        'fitBias', fitBias);

    defocusOTFFilename = sprintf('/Volumes/SSDdisk/MATLAB/projects/ISETMacaque/simulations/generatedData/OTF_%1.3fDiopters.mat', modelVariant.residualDefocusDiopters);
    
    
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
    theMeasuredSTF = dData.dFresponses;
    
    % Recompute RMS-errors at each position without any weighting
    residuals = (bsxfun(@minus, dModel.fittedSTFs, theMeasuredSTF)).^2;
    rmsErrors = sqrt(sum(residuals,2));
    
    % Find position with lowest RMS error
    [~, theSelectedPosition] = min(rmsErrors);

    % The selected fitted model's center and surround cone pooling weights
    centerConeIndices = dModel.centerConeIndices{theSelectedPosition};
    centerConeWeights = dModel.centerConeWeights{theSelectedPosition};
    surroundConeIndices = dModel.surroundConeIndices{theSelectedPosition};
    surroundConeWeights = dModel.surroundConeWeights{theSelectedPosition};
    
    % The selected fitted model's STF
    theFittedSTF = squeeze(dModel.fittedSTFs(theSelectedPosition,:));
    
    % Retrieve selected fitted model's DoG params
    DoGparams = dModel.fittedParamsPositionExamined(theSelectedPosition,:);
    Kc = DoGparams(1);
    KsToKc = DoGparams(2);
    Ks = Kc * KsToKc;
    
    % Remove effect of residual defocus
    if (modelVariant.residualDefocusDiopters ~= 0)
        load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID), 'otf');
        load(defocusOTFFilename, 'OTF_ResidualDefocus');
        % Correction factor: add diffraction-limited, remove residual defocus
        % OTF (which includes diffraction-limited)
        defocusCorrectionFactor = otf./OTF_ResidualDefocus;

        theFittedSTF = theFittedSTF .* defocusCorrectionFactor;
        theMeasuredSTF = theMeasuredSTF .* defocusCorrectionFactor;
    end
    
    
    % Load the cone mosaic responses
    switch(pupilDiamForPhysiologicalOptics)
        case 3.0 
            residualDefocusForPhysiologicalOpticsEncodingPupilSize = 0.003;  % this was run for a pupil size of 3.0 mm
        case 2.0
            residualDefocusForPhysiologicalOpticsEncodingPupilSize= 0.002;  % this was run for a pupil size of 2.0 mm
        case 2.5 
            residualDefocusForPhysiologicalOpticsEncodingPupilSize = -0.002;  % this was run for a pupil size of 2.5 mm
        otherwise
            error('not computed');
    end

    sParams = struct(...
        'apertureParams', struct('shape', 'Gaussian', 'sigma', 0.204), ...
        'modelVariant', struct('coneCouplingLambda', 0, 'residualDefocusDiopters', residualDefocusForPhysiologicalOpticsEncodingPupilSize), ...
        'PolansSubject', 838, ...
        'visualStimulus', visualStimulus);
    modelSTFrunData = loadConeMosaicSTFResponses(monkeyID, sParams);

    % Center model cone responses
    centerConeResponses = modelSTFrunData.coneMosaicSpatiotemporalActivation(:,:,centerConeIndices);
    
    % Surround model cone responses
    surroundConeResponses = modelSTFrunData.coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices);

    

    modelRGCresponses = computeRGCresponseByPoolingConeMosaicResponses( ...
            centerConeResponses , ...
            surroundConeResponses, ...
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

    hFig = figure(100); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 430 480]);
    maxSTF = max([max(theMeasuredSTF) max(theFittedSTF)]);
    
     yyaxis left
     %subplot('Position', [0.13 0.55 0.85 0.42]);
    
    p1 = plot(modelSTFrunData.examinedSpatialFrequencies, theMeasuredSTF, 'ko', ...
        'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerSize', 18, ...
        'LineWidth', 2, 'Color', [0.2 0.2 0.2]);
    hold on;
    p2 = plot(modelSTFrunData.examinedSpatialFrequencies, theFittedSTF, '-', ...
        'LineWidth', 3.0, 'Color', [0.2 0.2 0.2]);
    plot(modelSTFrunData.examinedSpatialFrequencies, theMeasuredSTF, 'ko', ...
         'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerSize', 18, ...
        'LineWidth', 1.5, 'Color', [0.2 0.2 0.2]);
    
%     plot(modelSTFrunData.examinedSpatialFrequencies, theModelSTF, 'ro-', ...
%         'MarkerFaceColor', [1 .3 .5], 'MarkerEdgeColor',  [1 .3 .5]*0.5, 'MarkerSize', 18, ...
%         'Color',  [1 .3 .5]*0.5, ...
%         'LineWidth', 1.5);
    
   
    maxSTF =  1.5*max(theFittedSTF);
    if (maxSTF < 0.7)
         yTicks = 0:0.1:2;
         yTicks2 = 0:0.01:2;
    else
         yTicks = 0:0.2:2;
         yTicks2 = 0:0.02:2;
    end
    
    legend boxoff
    set(gca, 'XScale', 'log',  'YColor', [0.2 0.2 0.2], 'XLim', [4 60], 'YLim', [0 maxSTF], 'YTick', yTicks, 'XTick', [5 10 20 40 60], 'FontSize', 20);
    grid on; box off;
    ylabel('STF');
    if (~isempty(targetLcenterRGCindices))
        fName = sprintf('L%d_defocus_%2.3fD_pupilDiamMM_%2.1f.pdf',  targetLcenterRGCindices(1), fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
        title(sprintf('L%d', targetLcenterRGCindices(1)), 'FontSize', 16);
        
    else
        fName = sprintf('M%d_defocus_%2.3fD_pupilDiamMM_%2.1f.pdf',  targetMcenterRGCindices(1), fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
        title(sprintf('M%d',  targetMcenterRGCindices(1)), 'FontSize', 16);
    end
    
    
    %subplot('Position', [0.13 0.08 0.85 0.42]);
    yyaxis right
    

     plot(modelSTFrunData.examinedSpatialFrequencies, theModelSTF, '-', ...
        'Color',  [1 .3 .5]*0.5, ...
        'LineWidth', 3);
    p3 = plot(modelSTFrunData.examinedSpatialFrequencies, theModelSTF, 'ro-', ...
        'MarkerFaceColor', [1 .3 .5], 'MarkerEdgeColor',  [1 .3 .5]*0.5, 'MarkerSize', 18, ...
        'Color',  [1 .3 .5]*0.5, ...
        'LineWidth', 1.5);
     hLegend = legend([p1 p2 p3], {'AOSLO data', 'AOSLO model fit (diffr.-limited, 6.7 mm pupil)', ...
                       sprintf('physiological optics (%2.1f mm pupil)', pupilDiamForPhysiologicalOptics)}, ...
        'Location', 'NorthWest', 'FontSize', 13);
    
    legend boxoff
    set(gca, 'XScale', 'log', 'XLim', [4 60], 'YLim', [0 1.5*max(theModelSTF)], 'YTick', yTicks2, 'XTick', [5 10 20 40 60], 'FontSize', 20);
    set(gca, 'YColor',  [1 .3 .5]);
    grid on; box off;
    xlabel('spatial frequency (c/deg)');
    
    NicePlot.exportFigToPDF(fName, hFig,300);

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

