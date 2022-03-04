function computeISETBioModelSTFdata
    

pupilDiamForPhysiologicalOptics = 2.5;
    
    
doLcells = true;
doMcells = true;

KsToKc = [];
RsToRc = [];

if (doLcells)
    targetMcenterRGCindices = [];
    
    % Load a fitted model

    targetLcenterRGCindices = [1];
    accountForResponseOffset = true;                      
    fitBias = 'none';
    fittedModelResidualDefocus = 0.0;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

    targetLcenterRGCindices = [3];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

    

    targetLcenterRGCindices = [4];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];


    targetLcenterRGCindices = [5];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];
  
    targetLcenterRGCindices = [6];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   

     targetLcenterRGCindices = [7];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.0;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   

    targetLcenterRGCindices = [8];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.0;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   
    
    targetLcenterRGCindices = [10];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   
%     
    targetLcenterRGCindices = [11];
    accountForResponseOffset = true;                     
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   
end

if (doMcells)
    targetLcenterRGCindices = [];
    
    targetMcenterRGCindices = [1];
    accountForResponseOffset = ~true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   
    targetMcenterRGCindices = [2];
    accountForResponseOffset = true;                      
    fitBias = 'flat';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc];

   
    targetMcenterRGCindices = [4];
    accountForResponseOffset = true;                      
    fitBias = 'boostHighSpatialFrequencies';
    fittedModelResidualDefocus = 0.067;
    summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics);
    d = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData);
    KsToKc(size(KsToKc,1)+1,:) = [d.physiologicalOpticsKsToKc summaryData.diffractionLimitedKsToKc ];
    RsToRc(size(RsToRc,1)+1,:) = [d.physiologicalOpticsRsToRc summaryData.diffractionLimitedRsToRc ];

   
end

   
hFig = figure(333); clf;
set(hFig, 'Color', [1 1 1], 'Position', [10 10 1400 1050]);

edges = 0:5:100;

[KaplanKsToKc, eccDegs] = CronerKaplanFig6Data();
subplot(3,3,7)
theData = 1./KaplanKsToKc;
h = histogram(theData,edges);
h.FaceColor = [1 .8 .5];
h.EdgeColor = [1 .8 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca,  'XLim', [0 90],  ...
    'XTick',  0:10:200, 'YLim',[0 7], 'YTick', 0:1:8, 'FontSize', 22);
xlabel('Kc/Ks');
title('Croner & Kaplan ''94');
xtickangle(0)
ylabel('count')



subplot(3,3,4);
theData = 1./KsToKc(:,1);
h = histogram(theData,edges);
h.FaceColor = [1 .3 .5]*0.8;
h.EdgeColor = [1 .3 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
set(gca,  'XLim', [0 90],  ...
    'XTick',  0:10:200, 'YLim',[0 5], 'YTick', 0:7, 'FontSize', 22);
box off
grid on
title('physiological optics (M3)');
xtickangle(0)
ylabel('count')

subplot(3,3,1);
theData = 1./KsToKc(:,2);
h = histogram(theData,edges);
h.FaceColor = [0.8 0.8 0.8];
h.EdgeColor = [0.2 0.2 0.2];
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
set(gca,  'XLim', [0 90],  ...
    'XTick',  0:10:200, 'YLim',[0 7], 'YTick', 0:7, 'FontSize', 22);
title('diffr.-limited optics (M3)');
box off
grid on
xtickangle(0)
ylabel('count')


edges = 0:2:20;
[Rc, Rs] = CronerKaplanFig4Data();
theData = (Rs.radiusDegs)./(Rc.radiusDegs);
subplot(3,3,8);
h = histogram(theData,edges);
h.FaceColor = [1 .8 .5];
h.EdgeColor = [1 .8 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 14], 'YLim', [0 25], 'YTick', 0:5:25, ...
    'XTick', [0:2:20], 'FontSize', 22);
xlabel('Rs/Rc ratio');
title('Croner & Kaplan ''94');
xtickangle(0);


subplot(3,3,5)
theData = RsToRc(:,1);
h = histogram(RsToRc(:,1),edges);
h.FaceColor = [1 .3 .5]*0.8;
h.EdgeColor = [1 .3 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 14],  'YLim', [0 8], ...
    'XTick', [0:2:20], 'FontSize', 22);

title('physiological optics (M3)');
xtickangle(0);

subplot(3,3,2)
theData = RsToRc(:,2);
h = histogram(theData,edges);
h.FaceColor = [0.8 0.8 0.8];
h.EdgeColor = [0.2 0.2 0.2];
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 14],  ...
    'XTick', [0:2:20], 'YLim', [0 8], 'FontSize', 22);
xtickangle(0)
title('diffr.-limited optics (M3)');



integratedSensitivitySurroundToCenter(:,1) = KsToKc(:,1) .* (RsToRc(:,1)).^2;
integratedSensitivitySurroundToCenter(:,2) = KsToKc(:,2) .* (RsToRc(:,2)).^2;


edges = 0:0.25:5;
subplot(3,3,6);
theData = integratedSensitivitySurroundToCenter(:,1);
h = histogram(theData,edges);
h.FaceColor = [1 .3 .5]*0.8;
h.EdgeColor = [1 .3 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 5],  ...
    'XTick', [0:1:5], 'YLim', [0 6], 'YTick', 0:6, 'FontSize', 22);
title('physiological optics (M3)');

xtickangle(0)
meanIntSensPhysio = median(theData(:))


subplot(3,3,3);
theData = integratedSensitivitySurroundToCenter(:,2);
h = histogram(theData,edges);
h.FaceColor = [0.8 0.8 0.8];
h.EdgeColor = [0.2 0.2 0.2];
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 5],  ...
    'XTick', [0:1:5], 'YLim', [0 6], 'YTick', 0:6, 'FontSize', 22);

title('diffr.-limited optics (M3)');
xtickangle(0)


subplot(3,3,9);
[eccDegs, KaplanIntegratedSensitivitySurroundToCenter ] = CronerKaplanFig11Data();
theData = KaplanIntegratedSensitivitySurroundToCenter;
h = histogram(theData,edges);
h.FaceColor = [1 .8 .5];
h.EdgeColor = [1 .8 .5]*0.5;
hold on;
plot(median(theData(:))*[1 1], [0 50], 'k--', 'LineWidth', 1.5);
box off
grid on
set(gca, 'XLim', [0 5],  'YLim', [0 40], 'YTick', 0:10:50, ...
    'XTick', [0:1:5], 'FontSize', 22);
xlabel('S/C integrated sensitivity ratio');
title('Croner&Kaplan ''94');
xtickangle(0)
end

function summaryData = doIt(targetLcenterRGCindices, targetMcenterRGCindices, accountForResponseOffset, fitBias, fittedModelResidualDefocus, pupilDiamForPhysiologicalOptics)
        
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
    RsToRc = DoGparams(3);
    Ks = Kc * KsToKc;
    

    % Remove effect of residual defocus assumed in the model
    load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID), 'otf');
    if (modelVariant.residualDefocusDiopters ~= 0)
        
        load(defocusOTFFilename, 'OTF_ResidualDefocus');
        % Correction factor: add diffraction-limited, remove residual defocus
        % OTF (which includes diffraction-limited)
        defocusCorrectionFactor = otf./OTF_ResidualDefocus;

        theFittedSTF = theFittedSTF .* defocusCorrectionFactor;
        theMeasuredSTF = theMeasuredSTF .* defocusCorrectionFactor;
    else
        % Add diffraction-limited OTF only
        theFittedSTF = theFittedSTF .* otf;
        theMeasuredSTF = theMeasuredSTF .* otf;
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

        theModelSTF(iSF) = STFamplitude;
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

    summaryData = struct(...
         'physiologicalOpticsSTF', theModelSTF, ...
         'sfSupport', modelSTFrunData.examinedSpatialFrequencies, ...
         'diffractionLimitedKsToKc', KsToKc, ...
         'diffractionLimitedRsToRc', RsToRc ...
         );


end

function dataOut = fitDogModel(targetLcenterRGCindices, targetMcenterRGCindices, summaryData)

    sf = summaryData.sfSupport;
    weights  = summaryData.physiologicalOpticsSTF*0+1;

    DoGFunction = @(params,sf)(...
                    params(1)           * ( pi * params(2)^2             * exp(-(pi*params(2)*sf).^2) ) - ...
                    params(1)*params(3) * ( pi * (params(2)*params(4))^2 * exp(-(pi*params(2)*params(4)*sf).^2) ));
               
    %                Kc                 RcDegs                 kS/kC                  Rs/Rc
    initialParams1 = [1000               1/60                    1e-1                 7];
    lowerBound1    = [1           0.17/60                   1e-3                 1];
    upperBound1    = [5000       5/60                      1                    20];


    objective1 = @(p) sum(weights .* (DoGFunction(p, sf) - summaryData.physiologicalOpticsSTF).^2);



    problem1 = createOptimProblem('fmincon',...
                    'x0', initialParams1, ...
                    'objective', objective1, ...
                    'lb', lowerBound1, ...
                    'ub', upperBound1 ...
                    );


    displayProgress = 'off'; % 'iter';
    ms = MultiStart(...
                        'Display', displayProgress, ...
                        'StartPointsToRun','bounds-ineqs', ...
                        'FunctionTolerance', 2e-4, ...
                        'UseParallel', true);
    startingPointsNum = 512;
    fitParams1 = run(ms, problem1, startingPointsNum);


    for k = 1:4
        [lowerBound1(k) fitParams1(k) upperBound1(k)]
    end


    dataOut.physiologicalOpticsKsToKc = fitParams1(3);
    dataOut.physiologicalOpticsRsToRc = fitParams1(4);

    figure(222); clf;
    plot(sf, summaryData.physiologicalOpticsSTF, 'ko'); hold on;
    plot(sf, DoGFunction(fitParams1, sf), 'r-');
    title('physiological optics');

    
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

