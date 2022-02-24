function computeConeMosaicResponses(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus, varargin)
    
    p = inputParser;
    p.addParameter('noLCA', false, @islogical);
    p.parse(varargin{:});
    noLCA = p.Results.noLCA;
    
    switch (visualStimulus.type)
        case 'WilliamsLabStimulus'
            % Define wavelength support relative to the imaging wavelength
            wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-20:2:20); %(-160:2:140);
    
        case 'CRT'
            wavelengthSupport = 1+(465:5:750);
    end
    
    
    % Load the cone mosaic to use
    mosaicFileName = coneMosaicFilename(monkeyID);
    load(mosaicFileName, 'cm');
    theConeMosaic = cm;
    clear 'cm';

    % Cone mosaic modifications
    % 1. Spectral support
    theConeMosaic.wave = wavelengthSupport;

    % 2. Aperture modifiers
    newConeApertureModifiers = theConeMosaic.coneApertureModifiers;
    newConeApertureModifiers.smoothLocalVariations = true;
    newConeApertureModifiers.shape = apertureParams.shape;
    if (strcmp(apertureParams.shape, 'Gaussian'))
        newConeApertureModifiers.sigma = apertureParams.sigma;
    end
    theConeMosaic.coneApertureModifiers = newConeApertureModifiers;
    
    % 3. Cone coupling
    theConeMosaic.coneCouplingLambda = coneCouplingLambda;
    
    
    % 4. Optics
    if (isempty(PolansSubject))
        % Generate diffraction-limited optics for the Williams lab experiment
        [theOI, thePSF, ...
            psfSupportMinutesX, psfSupportMinutesY, ...
            psfSupportWavelength] = diffractionLimitedOptics(...
            WilliamsLabData.constants.pupilDiameterMM, wavelengthSupport, ...
            WilliamsLabData.constants.imagingPeakWavelengthNM, ...
            WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
            opticalDefocusDiopters, 'noLCA', noLCA);
        

        % Save OTF with custom residual blur. This will be used for
        % de-convonlving the DF/F responses before fitting them with the DoG model
        if (abs(opticalDefocusDiopters) > 0)
            % Extract OTF at the in-focus wavelength
            theOptics = oiGet(theOI, 'optics');
            theOTF = opticsGet(theOptics, 'otf data');
            [~,idx] = min(abs(psfSupportWavelength-WilliamsLabData.constants.imagingPeakWavelengthNM));
            visualizedOTF = squeeze(theOTF(:,:,idx));
            visualizedOTF = fftshift(abs(visualizedOTF));
            r = (size(visualizedOTF,1)-1)/2+1;
            OTFslice = squeeze(visualizedOTF(r,:));  
            
            % Extract spatial frequency support
            sfSupportCyclesPerMM = opticsGet(theOptics, 'otf fx');
            sfSupportCyclesPerDeg = sfSupportCyclesPerMM/1e3*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
   
            % Interpolate to frequencies used to measure RGC responses
            sessionData = 'mean'; 
            [~,~,~,~,~,~,diffractionLimitedOTF] = loadOTFdeconvolvedDeltaFluoresenceResponses(monkeyID, sessionData);
            sfsExamimed = diffractionLimitedOTF.sf;
            OTF_ResidualDefocus = interp1(sfSupportCyclesPerDeg, OTFslice, sfsExamimed);
            OTF_ResidualDefocusHR = struct(...
                'mag', OTFslice, ...
                'sf', sfSupportCyclesPerDeg);
            save(customDefocusOTFFilename(opticalDefocusDiopters), ...
                'OTF_ResidualDefocus', 'sfsExamimed', 'OTF_ResidualDefocusHR');
            fprintf('saved Defocus to %s' ,customDefocusOTFFilename(opticalDefocusDiopters))
        end
    
    else
        pupilDiameterMM = 2.5;
        
        if (opticalDefocusDiopters == -0.001)
            correctForAllZ = true
            correctForDefocus = false;
        end

        if (PolansSubject == 838)

            load('M838_Polychromatic_PSF.mat', 'Z_coeff_M838', 'd_pupil');

            if (correctForDefocus)
                Z_coeff_M838(5) = 0.00;
            end


            if (correctForAllZ)
                Z_coeff_M838(9:end) = 0;
            end



            measPupilDiamMM = d_pupil*1000;
            measWavelength = 550; 
            [~,idx] = min(abs(wavelengthSupport-measWavelength));
            measWavelength = wavelengthSupport(idx);
            psfSupportWavelength = wavelengthSupport;
            [thePSF, ~, ~,~, psfSupportMinutesX, psfSupportMinutesY, theWVF] = ...
               computePSFandOTF(Z_coeff_M838, ...
                                psfSupportWavelength , 701, ...
                                measPupilDiamMM, pupilDiameterMM, measWavelength, false, ...
                                'doNotZeroCenterPSF', false, ...
                                'micronsPerDegree', WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                                'upsampleFactor', 1, ...
                                'flipPSFUpsideDown', ~true, ...
                                'noLCA', false, ...
                                'name', 'M838 optics');
         
             % Generate the OI from the wavefront map
            theOI = wvf2oiSpecial(theWVF,  WilliamsLabData.constants.micronsPerDegreeRetinalConversion, pupilDiameterMM);
        else
           
            [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = ...
            PolansOptics.oiForSubjectAtEccentricity(PolansSubject, 'right eye', [0 0], ...
                pupilDiameterMM, wavelengthSupport, WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                'zeroCenterPSF', true, ...
                'inFocusWavelength', WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'subtractCentralRefraction', PolansOptics.constants.subjectRequiresCentralRefractionCorrection(PolansSubject));
        end
        
    end
    
    % Visualize the PSF
    [sfSupportCyclesPerDeg, visualizedOTFslice] = visualizeDiffractionLimitedPSF(thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, ...
            theOI, WilliamsLabData.constants.imagingPeakWavelengthNM);
 
    % Visualize mosaic and PSF
    visualizedDomainRangeMicrons = 40;
    visualizeMosaicAndPSF(theConeMosaic, visualizedDomainRangeMicrons, thePSF, ...
            psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, WilliamsLabData.constants.imagingPeakWavelengthNM, PolansSubject);
       

    % Generate the background stimulus scene
    [theBackgroundScene, scalingFactor] = generateStimulus(visualStimulus, wavelengthSupport, theOI, [], [], [], []);
    meanLuminance = sceneGet(theBackgroundScene, 'mean luminance');
    fprintf('Background scene mean luminance: %f\n', meanLuminance);


    % Compute the optical image of the background stimulus
    theBackgroundOI = oiCompute(theBackgroundScene, theOI);
    
    
    
    % Load the examined spatial frequencies
    load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID), 'freqs'); 
    examinedSpatialFrequencies = freqs;
   
    % Stimulus duration in cycles
    desiredOISequenceStimulationCycles = visualStimulus.stimulationDurationCycles;
    
    % Compute the spatial phases for the oi sequence
    spatialPhases = spatialPhasesForOISequence(desiredOISequenceStimulationCycles);
    

    % Set the integration time of the cone mosaic to the displayFrameDurationSeconds
    displayFrameDurationSeconds = 1/WilliamsLabData.constants.galvanoMeterScannerRefreshRate;
    theConeMosaic.integrationTime = displayFrameDurationSeconds;
    
    % Compute the cone mosaic activation to the background stimulus
    fprintf('Computing background activation\n');
    coneMosaicBackgroundActivation = theConeMosaic.compute(theBackgroundOI);
         
    % Compute the cone mosaic activation to each of the examined spatial frequencies
    for iSF = 1:numel(examinedSpatialFrequencies)
        testStimulusContrast = 1;  % SF runs were obtained using 100% contrast gratings
        testStimulusSpatialFrequencyCPD = examinedSpatialFrequencies(iSF);
        fprintf('Computing responses to %2.1f c/deg stimulus\n', testStimulusSpatialFrequencyCPD);
        
        % Generate OI sequence representing the drifting grating
        theListOfOpticalImages = cell(1, numel(spatialPhases));
        theStimulusTemporalSupportSeconds = zeros(1, numel(spatialPhases));
        for iPhase = 1:numel(spatialPhases)
            theStimulusScene = generateStimulus(visualStimulus,  wavelengthSupport, theOI, testStimulusContrast, testStimulusSpatialFrequencyCPD, spatialPhases(iPhase), scalingFactor);
            meanLuminance = sceneGet(theStimulusScene, 'mean luminance');
            fprintf('Test scene mean luminance: (%2.2fc/deg, phase: %2.2f degs) %f\n', examinedSpatialFrequencies(iSF), spatialPhases(iPhase), meanLuminance);
            % Compute the optical image of the test stimulus
            theListOfOpticalImages{iPhase} = oiCompute(theStimulusScene, theOI);
            theStimulusTemporalSupportSeconds(iPhase) = (iPhase-1)*displayFrameDurationSeconds;
        end % iPhase
        
        theOIsequence = oiArbitrarySequence(theListOfOpticalImages, theStimulusTemporalSupportSeconds);
        %theOIsequence.visualize('montage');
        
        % Compute the spatiotemporal cone-mosaic activation to this OIsequence
        [cmSpatiotemporalActivation, ~, ~, ~, temporalSupportSeconds] = ...
             theConeMosaic.compute(theOIsequence);
    
        % Single precision to sagfve space
        coneMosaicSpatiotemporalActivation(iSF,:,:) = single(cmSpatiotemporalActivation);
    end % iSF
        
    % Synthesize responses filename
    responseFileName = responsesFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus);
    
    save(responseFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'examinedSpatialFrequencies', '-v7.3');
end


function [theScene, theScalingFactor] = generateStimulus(visualStimulus,  wavelengthSupport, theOI, theContrast, theSpatialFrequency, theSpatialPhase, theScalingFactor)

    % Stimulus frame params for the background stimulus
    stimFrameParams = struct(...
                'fovDegs', [], ...                 % variable
                'spatialFrequencyCPD', [], ...     % variable
                'spatialPhaseDegs', [], ...        % variable
                'contrast', [], ...
                'pixelSizeDegs', WilliamsLabData.constants.pixelSizeMicronsOnRetina/WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...  % half of the device pixel size
                'sceneSpatialUpsampleFactor', WilliamsLabData.constants.sceneSpatialUpsampleFactor, ... % actual stim pixel size too close to cone aperture, so upsample the scene to have a well-sampled cone aperture
                'imagingPeakWavelengthNM', WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'imagingFullWidthHalfMaxBandwidthNM', WilliamsLabData.constants.imagingFullWidthHalfMaxBandwidthNM, ...
                'wavelengthSupport', wavelengthSupport, ...
                'viewingDistanceMeters', 20.0 ...                   % focused at infinity
                );
            
    
    switch (visualStimulus.type)
        case 'WilliamsLabStimulus'
            if (isempty(theContrast))
                % Background Scene
                % Compute the scaling factor using a 3 deg, uniform field stimulus to compute the energy over a
                % retinal region of 2.54x1.92 (which we know from measurements that it has a power of 2.5 microWatts)
                stimFrameParams.fovDegs = 3;
                stimFrameParams.contrast = 0;
                stimFrameParams.spatialFrequencyCPD = 0;
                stimFrameParams.spatialPhaseDegs = 0;
                theBackgroundScene = generateMonochromaticGratingScene(stimFrameParams,  []);

                % Compute the OI of the background scene
                theOI = oiCompute(theBackgroundScene, theOI);

                % Compute scaling factor using the OI for the uniform field and the calibrationROI
                theScalingFactor = computeScalingFactor(theOI, WilliamsLabData.constants.calibrationROI);

                % Make sure we got the right ROIenergy after applying the computed scaling factor
                theBackgroundScene = generateMonochromaticGratingScene(stimFrameParams,  theScalingFactor);
                theOI = oiCompute(theBackgroundScene, theOI);
                [~, computedROIenergyMicroWatts] = computeScalingFactor(theOI, WilliamsLabData.constants.calibrationROI);
                fprintf('Desired energy within ROI: %f microWatts, achieved: %f microWatts\n', ...
                    WilliamsLabData.constants.calibrationROI.energyMicroWatts, computedROIenergyMicroWatts); 

                % The background stimulus frame, now with the size used in the recordings
                stimFrameParams.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
            else
                % Stimulus frame params for the test stimulus
                stimFrameParams.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
                stimFrameParams.spatialFrequencyCPD = theSpatialFrequency;
                stimFrameParams.spatialPhaseDegs = theSpatialPhase;
                stimFrameParams.contrast = 1;
            end
            
            % Generate the scene
            theScene = generateMonochromaticGratingScene(stimFrameParams, theScalingFactor);
                
        case 'CRT'
            theDisplay = generateLCDdisplay(wavelengthSupport, stimFrameParams.pixelSizeDegs, stimFrameParams.viewingDistanceMeters);
            
            if (isempty(theContrast))
                % The background stimulus frame, now with the size used in the recordings
                stimFrameParams.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
                stimFrameParams.contrast = 0;
                stimFrameParams.spatialFrequencyCPD = 0;
                stimFrameParams.spatialPhaseDegs = 0;
            else
                % Stimulus frame params for the test stimulus
                stimFrameParams.fovDegs = WilliamsLabData.constants.sfTuningStimulusFOVdegs;
                stimFrameParams.spatialFrequencyCPD = theSpatialFrequency;
                stimFrameParams.spatialPhaseDegs = theSpatialPhase;
                stimFrameParams.contrast = 1;
            end
            
            % Generate the scene
            theScene = generateAchromaticGratingSceneOnLCDdisplay(stimFrameParams, theDisplay, ...
                visualStimulus.backgroundLuminanceCdM2, ...
                visualStimulus.backgroundChromaticity);
            theScalingFactor = [];
            
        otherwise
            error('Unknown stimulus type: ''%s''.', visualStimulus.type);
    end


end


function visualizeMosaicAndPSF(theConeMosaic, visualizedDomainRangeMicrons, thePSF, ...
    psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, inFocusWavelength, PolansSubject)
    hFig = figure(2000); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [40 40 550 600]);
    ax = subplot('Position', [0.1 0.1 0.85 0.85]);
    theConeMosaic.visualize('figureHandle', hFig, ...
        'axesHandle', ax, ...
        'domain', 'microns', ...
        'visualizedConeAperture', 'lightCollectingArea4sigma', ...
        'visualizedConeApertureThetaSamples', 30, ...
        'domainVisualizationLimits', visualizedDomainRangeMicrons*0.5*[-1 1 -1 1], ...
        'domainVisualizationTicks', struct('x', -20:20:20, 'y', -20:20:20), ...
        'crossHairsOnMosaicCenter', true, ...
        'labelCones', true, ...
        'noYLabel', ~true, ...
        'noXlabel', ~true, ...
        'plotTitle', ' ', ...
        'fontSize', 18);
    psfSupportMicronsX = psfSupportMinutesX/60*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
    psfSupportMicronsY = psfSupportMinutesY/60*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;

    if (1==1)
    % Add contour plot of the PSF
    hold(ax, 'on');
    cmap = brewermap(1024,'greys');
    alpha = 0.5;
    contourLineColor = [0.0 0.0 0.0];
    [~,idx] = min(abs(psfSupportWavelength-inFocusWavelength));
    visualizedPSF = squeeze(thePSF(:,:,idx));
    visualizedPSF = visualizedPSF / max(visualizedPSF(:));
    cMosaic.semiTransparentContourPlot(ax, psfSupportMicronsX, psfSupportMicronsY, visualizedPSF, [0.03:0.15:0.95], cmap, alpha, contourLineColor);

    % Add horizontal slice through the PSF
    m = (size(visualizedPSF,1)-1)/2+1;
    visualizedPSFslice = squeeze(visualizedPSF(m,:));
    idx = find(abs(visualizedPSFslice) >= 0.01);
    visualizedPSFslice = visualizedPSFslice(idx);
    
    xx = psfSupportMicronsX(idx);
    yy = -visualizedDomainRangeMicrons*0.5*0.95 + visualizedPSFslice*visualizedDomainRangeMicrons*0.5*0.9;
    %shadedAreaPlot(ax,xx,yy, -visualizedDomainRangeMicrons*0.5*0.95, [0.8 0.8 0.8], [0.1 0.1 0.9], 0.5, 1.5);

    hL = plot(ax,xx, yy, '-', 'LineWidth', 4.0);
    hL.Color = [1,1,0.8,0.7];
    plot(ax,xx, yy, 'k-', 'LineWidth', 2);
    
    % Add vertical slice through the PSF
    visualizedPSFslice = squeeze(visualizedPSF(:,m));
    idx = find(abs(visualizedPSFslice) >= 0.01);
    visualizedPSFslice = visualizedPSFslice(idx);
    xx = visualizedDomainRangeMicrons*0.5*0.95 - visualizedPSFslice*visualizedDomainRangeMicrons*0.5*0.9;
    yy = psfSupportMicronsY(idx);
    %shadedAreaPlot(ax,xx,yy, -visualizedDomainRangeMicrons*0.5*0.95, [0.8 0.8 0.8], [0.1 0.1 0.9], 0.5, 1.5);

    
    hL = plot(ax,xx, yy, '-', 'LineWidth', 4.0);
    hL.Color = [1,1,0.8,0.7];
    plot(ax,xx, yy, 'k-', 'LineWidth', 2);
    end
    
    
    if (PolansSubject == 0)
        title(['PSF focused at \lambda = ' sprintf('%2.0fnm', inFocusWavelength)], 'FontWeight', 'normal');
    else
        title(['PSF focused at \lambda = ' sprintf('%2.0fnm (Polans subj. %d)', inFocusWavelength, PolansSubject)], 'FontWeight', 'normal');
    end
    drawnow;
    NicePlot.exportFigToPDF(sprintf('PolansSubject%dPSFonMosaic.pdf', PolansSubject), hFig, 300);
end

